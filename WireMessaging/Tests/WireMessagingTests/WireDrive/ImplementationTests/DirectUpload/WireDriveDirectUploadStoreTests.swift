//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import CoreData
import Foundation
import Testing

@testable import WireMessagingData
@testable import WireMessagingDomain

/// Exercised against the real `zmessaging` model rather than a mock, so that a schema mistake in the
/// `WireDriveDirectUpload` entity fails here instead of at runtime.
struct WireDriveDirectUploadStoreTests {

    private let sut: WireDriveDirectUploadStore

    init() throws {
        self.sut = WireDriveDirectUploadStore(contextProvider: try TestManagedObjectContextProvider())
    }

    // MARK: - Round trip

    @Test
    func persistsEveryFieldOfARecord() async throws {
        // Given
        let record = WireDriveDirectUploadRecord.fixture(
            state: .uploading,
            attemptCount: 2,
            sessionIdentifier: "com.wire.drive.upload-abc",
            taskIdentifier: 7,
            presignedURL: URL(string: "https://example.com/put?X-Amz-Signature=abc")!,
            presignedURLExpiresAt: Date(timeIntervalSince1970: 1_700_000_900),
            presignedRequestHeaders: ["x-amz-meta-extra": "value"],
            failure: .serverError(statusCode: 503)
        )

        // When
        try await sut.upsert(record)

        // Then
        let persisted = try #require(try await sut.fetch(uploadID: record.uploadID))
        #expect(persisted == record)
    }

    @Test
    func persistsARecordWithNoOptionalValues() async throws {
        // Given
        let record = WireDriveDirectUploadRecord.fixture(
            mimeType: nil,
            sessionIdentifier: nil,
            taskIdentifier: nil,
            presignedURL: nil,
            presignedURLExpiresAt: nil,
            presignedRequestHeaders: [:],
            failure: nil
        )

        // When
        try await sut.upsert(record)

        // Then
        #expect(try await sut.fetch(uploadID: record.uploadID) == record)
    }

    @Test
    func returnsNilForAnUnknownUpload() async throws {
        #expect(try await sut.fetch(uploadID: UUID()) == nil)
    }

    // MARK: - Upsert semantics

    @Test
    func updatesAnExistingRecordRatherThanDuplicatingIt() async throws {
        // Given
        var record = WireDriveDirectUploadRecord.fixture(state: .staged)
        try await sut.upsert(record)

        // When
        record.state = .uploading
        record.attemptCount = 1
        try await sut.upsert(record)

        // Then
        let all = try await sut.fetchAll()
        #expect(all.count == 1)
        #expect(all.first?.state == .uploading)
        #expect(all.first?.attemptCount == 1)
    }

    /// Only transitions are worth a write; a refreshed timestamp on its own is not.
    @Test
    func skipsTheWriteWhenOnlyTheTimestampChanged() async throws {
        // Given
        let record = WireDriveDirectUploadRecord.fixture(updatedAt: Date(timeIntervalSince1970: 1))
        try await sut.upsert(record)

        var touched = record
        touched.updatedAt = Date(timeIntervalSince1970: 999)

        // When
        try await sut.upsert(touched)

        // Then — the stored timestamp is unchanged, which is what proves the write was skipped.
        #expect(try await sut.fetch(uploadID: record.uploadID)?.updatedAt == record.updatedAt)
    }

    @Test
    func writesABatchOfRecords() async throws {
        // Given
        let records = (0 ..< 5).map { index in
            WireDriveDirectUploadRecord.fixture(createdAt: Date(timeIntervalSince1970: TimeInterval(index)))
        }

        // When
        try await sut.upsert(records: records)

        // Then
        #expect(try await sut.fetchAll().count == 5)
    }

    @Test
    func writingAnEmptyBatchIsHarmless() async throws {
        try await sut.upsert(records: [])
        #expect(try await sut.fetchAll().isEmpty)
    }

    // MARK: - Fetching

    @Test
    func fetchesAllRecordsOldestFirst() async throws {
        // Given
        let older = WireDriveDirectUploadRecord.fixture(createdAt: Date(timeIntervalSince1970: 100))
        let newer = WireDriveDirectUploadRecord.fixture(createdAt: Date(timeIntervalSince1970: 200))
        try await sut.upsert(records: [newer, older])

        // When
        let all = try await sut.fetchAll()

        // Then
        #expect(all.map(\.uploadID) == [older.uploadID, newer.uploadID])
    }

    @Test
    func fetchesByState() async throws {
        // Given
        let uploading = WireDriveDirectUploadRecord.fixture(state: .uploading)
        let staged = WireDriveDirectUploadRecord.fixture(state: .staged)
        let uploaded = WireDriveDirectUploadRecord.fixture(state: .uploaded)
        try await sut.upsert(records: [uploading, staged, uploaded])

        // When
        let unfinished = try await sut.fetch(states: [.uploading, .staged])

        // Then
        #expect(Set(unfinished.map(\.uploadID)) == Set([uploading.uploadID, staged.uploadID]))
    }

    @Test
    func fetchingByStateWithNoMatchesReturnsNothing() async throws {
        // Given
        try await sut.upsert(WireDriveDirectUploadRecord.fixture(state: .uploaded))

        // Then
        #expect(try await sut.fetch(states: [.failed]).isEmpty)
    }

    // MARK: - Deleting

    @Test
    func deletesSpecificRecords() async throws {
        // Given
        let kept = WireDriveDirectUploadRecord.fixture()
        let removed = WireDriveDirectUploadRecord.fixture()
        try await sut.upsert(records: [kept, removed])

        // When
        try await sut.delete(uploadIDs: [removed.uploadID])

        // Then
        #expect(try await sut.fetchAll().map(\.uploadID) == [kept.uploadID])
    }

    @Test
    func deletingAnUnknownRecordIsHarmless() async throws {
        try await sut.delete(uploadIDs: [UUID()])
    }

    @Test
    func deletesEverything() async throws {
        // Given
        try await sut.upsert(records: [.fixture(), .fixture()])

        // When
        try await sut.deleteAll()

        // Then
        #expect(try await sut.fetchAll().isEmpty)
    }

    // MARK: - State fidelity

    /// The persisted raw value must survive the round trip for every state, since reconciliation
    /// decides what to resume from based on it.
    @Test(arguments: WireDriveDirectUploadRecord.State.allCases)
    func roundTripsEveryState(_ state: WireDriveDirectUploadRecord.State) async throws {
        // Given
        let record = WireDriveDirectUploadRecord.fixture(state: state)

        // When
        try await sut.upsert(record)

        // Then
        #expect(try await sut.fetch(uploadID: record.uploadID)?.state == state)
    }

    @Test(arguments: [
        WireDriveUploadError.fileNotFound,
        .urlError(error: URLError(.timedOut)),
        .other(message: "boom"),
        .serverError(statusCode: 500),
        .unauthorized,
        .insufficientStorage,
        .cancelledBySystem
    ])
    func roundTripsEveryFailureReason(_ failure: WireDriveUploadError) async throws {
        // Given
        let record = WireDriveDirectUploadRecord.fixture(state: .failed, failure: failure)

        // When
        try await sut.upsert(record)

        // Then
        #expect(try await sut.fetch(uploadID: record.uploadID)?.failure == failure)
    }
}
