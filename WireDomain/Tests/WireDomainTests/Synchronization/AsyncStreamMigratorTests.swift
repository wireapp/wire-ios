//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import WireAPISupport
import WireDomainSupport
import WireSystem
import XCTest
@testable import WireDomain

final class AsyncStreamMigratorTests: XCTestCase {
    var sut: AsyncStreamMigrator!
    var mockSync: MockPullPendingUpdateEventsSyncProtocol!
    var mockUserClientsAPI: MockUserClientsAPI!
    var mockLocalStore: MockUserClientsLocalStoreProtocol!
    var journal: JournalProtocol!

    enum Scaffolding {
        static let userID: UUID = .init()
        static let userClientID: String = .randomClientIdentifier()
    }

    override func setUp() {
        super.setUp()
        mockSync = .init()
        mockUserClientsAPI = .init()
        mockLocalStore = .init()
        journal = Journal(userID: Scaffolding.userID, storage: UserDefaults.temporary())

        sut = AsyncStreamMigrator(
            sync: mockSync,
            userClientsAPI: mockUserClientsAPI,
            userClientsLocalStore: mockLocalStore,
            apiVersion: .v8,
            journal: journal
        )
    }

    override func tearDown() {
        super.tearDown()
        mockSync = nil
        mockUserClientsAPI = nil
        mockLocalStore = nil
        journal = nil

        sut = nil
    }

    func test_migrateToAsyncStream_userClientNeedsRegistration() async throws {
        // GIVEN
        mockLocalStore.fetchSelfClientID_MockValue = Scaffolding.userID.uuidString
        mockLocalStore.isClientAsyncStreamCapable_MockValue = false
        mockUserClientsAPI.updateClientIdPayload_MockMethod = { _, _ in }
        mockSync.pull_MockValue = AsyncStream { [] }

        // WHEN
        try await sut.migrateToAsyncStream()

        // THEN
        XCTAssertEqual(mockUserClientsAPI.updateClientIdPayload_Invocations.count, 1)
        XCTAssertEqual(mockSync.pull_Invocations.count, 1)
        XCTAssertTrue(journal[.isAsyncStreamEnabled])
    }

    func test_migrateToAsyncStream_userClientAlreadyCapable() async throws {
        // GIVEN
        mockLocalStore.fetchSelfClientID_MockValue = Scaffolding.userID.uuidString
        mockLocalStore.isClientAsyncStreamCapable_MockValue = true
        mockUserClientsAPI.updateClientIdPayload_MockMethod = { _, _ in }
        mockSync.pull_MockValue = AsyncStream { [] }

        // WHEN
        try await sut.migrateToAsyncStream()

        // THEN
        XCTAssertEqual(mockUserClientsAPI.updateClientIdPayload_Invocations.count, 0)
        XCTAssertEqual(mockSync.pull_Invocations.count, 1)
        XCTAssertTrue(journal[.isAsyncStreamEnabled])
    }

    func test_migrateToAsyncStream_syncFails_throws() async throws {
        // GIVEN
        mockLocalStore.fetchSelfClientID_MockValue = Scaffolding.userID.uuidString
        mockLocalStore.isClientAsyncStreamCapable_MockValue = false
        mockUserClientsAPI.updateClientIdPayload_MockMethod = { _, _ in }
        let error = TestError(message: "")
        mockSync.pull_MockError = error

        // WHEN
        await XCTAssertThrowsErrorAsync(error) {
            try await self.sut.migrateToAsyncStream()
        }

        // THEN
        XCTAssertEqual(mockUserClientsAPI.updateClientIdPayload_Invocations.count, 1)
        XCTAssertEqual(mockSync.pull_Invocations.count, 1)
        XCTAssertFalse(journal[.isAsyncStreamEnabled])
    }

    func test_migrateToAsyncStream_registrationFails_throws() async throws {
        // GIVEN
        mockLocalStore.fetchSelfClientID_MockValue = Scaffolding.userID.uuidString
        mockLocalStore.isClientAsyncStreamCapable_MockValue = false
        let error = TestError(message: "")
        mockUserClientsAPI.updateClientIdPayload_MockError = error

        mockSync.pull_MockValue = AsyncStream { [] }

        // WHEN
        await XCTAssertThrowsErrorAsync(error) {
            try await self.sut.migrateToAsyncStream()
        }

        // THEN
        XCTAssertEqual(mockUserClientsAPI.updateClientIdPayload_Invocations.count, 1)
        XCTAssertEqual(mockSync.pull_Invocations.count, 0)
        XCTAssertFalse(journal[.isAsyncStreamEnabled])
    }

    func test_migrateToAsyncStream_apiVersionTooLow_throws() async throws {
        // GIVEN
        sut = AsyncStreamMigrator(
            sync: mockSync,
            userClientsAPI: mockUserClientsAPI,
            userClientsLocalStore: mockLocalStore,
            apiVersion: .v7,
            journal: journal
        )

        mockSync.pull_MockValue = AsyncStream { [] }

        // WHEN / THEN
        await XCTAssertThrowsErrorAsync(AsyncStreamMigrator.Failure.apiVersionTooLow) {
            try await self.sut.migrateToAsyncStream()
        }
    }
}
