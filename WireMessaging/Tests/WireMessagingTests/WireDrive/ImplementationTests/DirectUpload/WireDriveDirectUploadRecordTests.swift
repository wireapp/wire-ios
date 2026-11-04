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

import Foundation
import Testing

@testable import WireMessagingDomain

struct WireDriveDirectUploadRecordTests {

    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    // MARK: - Presigned URL freshness

    @Test
    func needsAPresignedURLWhenThereIsNone() {
        // Given
        let sut = WireDriveDirectUploadRecord.fixture(presignedURL: nil)

        // Then
        #expect(sut.needsPresignedURL(now: now))
    }

    @Test
    func doesNotNeedAPresignedURLWhileOneIsComfortablyValid() {
        // Given
        let sut = WireDriveDirectUploadRecord.fixture(
            presignedURL: URL(string: "https://example.com/put")!,
            presignedURLExpiresAt: now.addingTimeInterval(600)
        )

        // Then
        #expect(!sut.needsPresignedURL(now: now))
    }

    /// A transfer that starts moments before expiry would be rejected mid-flight, so a margin is
    /// applied rather than comparing against the exact expiry.
    @Test
    func needsAPresignedURLWhenExpiryIsImminent() {
        // Given
        let sut = WireDriveDirectUploadRecord.fixture(
            presignedURL: URL(string: "https://example.com/put")!,
            presignedURLExpiresAt: now.addingTimeInterval(30)
        )

        // Then
        #expect(sut.needsPresignedURL(now: now, margin: 120))
    }

    @Test
    func needsAPresignedURLWhenTheExpiryIsUnknown() {
        // Given
        let sut = WireDriveDirectUploadRecord.fixture(
            presignedURL: URL(string: "https://example.com/put")!,
            presignedURLExpiresAt: nil
        )

        // Then
        #expect(sut.needsPresignedURL(now: now))
    }

    // MARK: - Write amplification

    /// `updatedAt` alone must not trigger a database write; that is what keeps a stream of events
    /// from churning the store.
    @Test
    func treatsRecordsDifferingOnlyByTimestampAsEqual() {
        // Given
        let sut = WireDriveDirectUploadRecord.fixture(updatedAt: now)
        var touched = sut
        touched.updatedAt = now.addingTimeInterval(60)

        // Then
        #expect(sut.hasEqualPersistedFields(to: touched))
    }

    @Test
    func treatsAStateChangeAsWorthPersisting() {
        // Given
        let sut = WireDriveDirectUploadRecord.fixture(state: .uploading)
        var advanced = sut
        advanced.state = .uploaded

        // Then
        #expect(!sut.hasEqualPersistedFields(to: advanced))
    }

    @Test
    func treatsAResolvedPathAsWorthPersisting() {
        // Given
        let sut = WireDriveDirectUploadRecord.fixture(nodePath: "cell-1/report.pdf")
        var renamed = sut
        renamed.nodePath = "cell-1/report (1).pdf"

        // Then
        #expect(!sut.hasEqualPersistedFields(to: renamed))
    }

    // MARK: - Lifecycle predicates

    @Test(arguments: [
        WireDriveDirectUploadRecord.State.uploaded,
        .failed
    ])
    func recognisesTerminalStates(_ state: WireDriveDirectUploadRecord.State) {
        #expect(state.isTerminal)
    }

    @Test(arguments: [
        WireDriveDirectUploadRecord.State.staged,
        .preChecked,
        .awaitingStart,
        .uploading
    ])
    func recognisesNonTerminalStates(_ state: WireDriveDirectUploadRecord.State) {
        #expect(!state.isTerminal)
    }

    /// Raw values are persisted, so they must never drift.
    @Test
    func persistedStateRawValuesAreStable() {
        #expect(WireDriveDirectUploadRecord.State.staged.rawValue == 0)
        #expect(WireDriveDirectUploadRecord.State.preChecked.rawValue == 1)
        #expect(WireDriveDirectUploadRecord.State.awaitingStart.rawValue == 2)
        #expect(WireDriveDirectUploadRecord.State.uploading.rawValue == 3)
        #expect(WireDriveDirectUploadRecord.State.uploaded.rawValue == 5)
        #expect(WireDriveDirectUploadRecord.State.failed.rawValue == 6)
    }

    // MARK: - Presentation

    // Covers the collapse from the fine grained persisted lifecycle to what the user sees.

    /// Everything before bytes are sent reads as queued; the user does not need to know about
    /// pre-checking or presigning.
    @Test(arguments: [
        WireDriveDirectUploadRecord.State.staged,
        .preChecked,
        .awaitingStart
    ])
    func preparationStatesReadAsQueued(_ state: WireDriveDirectUploadRecord.State) {
        // Given
        let record = WireDriveDirectUploadRecord.fixture(state: state)

        // When
        let item = record.toItem(progress: nil, isStagedFileAvailable: true)

        // Then
        #expect(item.status == .queued)
    }

    /// A task can exist for a while before the system gets round to starting it, and "uploading 0%"
    /// would be misleading.
    @Test
    func uploadingWithNoBytesSentReadsAsQueued() {
        // Given
        let record = WireDriveDirectUploadRecord.fixture(state: .uploading)

        // When
        let item = record.toItem(progress: 0, isStagedFileAvailable: true)

        // Then
        #expect(item.status == .queued)
    }

    @Test
    func uploadingReportsProgress() {
        // Given
        let record = WireDriveDirectUploadRecord.fixture(state: .uploading)

        // When
        let item = record.toItem(progress: 0.4, isStagedFileAvailable: true)

        // Then
        #expect(item.status == .uploading(progress: 0.4))
    }

    @Test
    func uploadedReadsAsUploaded() {
        // Given
        let record = WireDriveDirectUploadRecord.fixture(state: .uploaded)

        // Then
        #expect(record.toItem(progress: nil, isStagedFileAvailable: false).status == .uploaded)
    }

    @Test
    func failedCarriesItsReason() {
        // Given
        let record = WireDriveDirectUploadRecord.fixture(state: .failed, failure: .unauthorized)

        // Then
        #expect(record.toItem(progress: nil, isStagedFileAvailable: true).status == .failed(error: .unauthorized))
    }

    @Test
    func failedWithoutAReasonStillReadsAsFailed() {
        // Given — should not happen, but must not crash or read as success.
        let record = WireDriveDirectUploadRecord.fixture(state: .failed, failure: nil)

        // Then
        #expect(record.toItem(progress: nil, isStagedFileAvailable: true).status.isFailed)
    }

    // MARK: - Retryability

    @Test
    func failedIsRetryableWhenTheBytesSurvived() {
        // Given
        let record = WireDriveDirectUploadRecord.fixture(state: .failed, failure: .unauthorized)

        // Then
        #expect(record.toItem(progress: nil, isStagedFileAvailable: true).isRetryable)
    }

    @Test
    func failedIsNotRetryableWhenTheBytesAreGone() {
        // Given
        let record = WireDriveDirectUploadRecord.fixture(state: .failed, failure: .unauthorized)

        // Then
        #expect(!record.toItem(progress: nil, isStagedFileAvailable: false).isRetryable)
    }

    @Test
    func failedIsNotRetryableForAPermanentReason() {
        // Given
        let record = WireDriveDirectUploadRecord.fixture(state: .failed, failure: .insufficientStorage)

        // Then
        #expect(!record.toItem(progress: nil, isStagedFileAvailable: true).isRetryable)
    }

    @Test(arguments: [
        WireDriveDirectUploadRecord.State.staged,
        .uploading,
        .uploaded
    ])
    func onlyFailedUploadsAreRetryable(_ state: WireDriveDirectUploadRecord.State) {
        // Given
        let record = WireDriveDirectUploadRecord.fixture(state: state)

        // Then
        #expect(!record.toItem(progress: nil, isStagedFileAvailable: true).isRetryable)
    }

    // MARK: - Derived bytes

    @Test
    func derivesBytesSentFromProgress() {
        // Given
        let record = WireDriveDirectUploadRecord.fixture(fileSize: 1000, state: .uploading)

        // When
        let item = record.toItem(progress: 0.25, isStagedFileAvailable: true)

        // Then
        #expect(item.bytesSent == 250)
    }
}
