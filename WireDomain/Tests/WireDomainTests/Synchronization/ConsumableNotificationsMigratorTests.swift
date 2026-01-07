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

import WireDomainSupport
import WireNetworkSupport
import WireSystem
import WireUtilities
import XCTest
@testable import WireDomain

final class ConsumableNotificationsMigratorTests: XCTestCase {
    var sut: ConsumableNotificationsMigrator!
    var mockSync: MockSyncMigratorProtocol!
    var mockUserClientsAPI: MockUserClientsAPI!
    var mockLocalStore: MockUserClientsLocalStoreProtocol!
    var mockFeatureConfigRepository: MockFeatureConfigRepositoryProtocol!
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
        mockFeatureConfigRepository = MockFeatureConfigRepositoryProtocol()
        mockFeatureConfigRepository.isFeatureEnabled_MockValue = true

        journal = Journal(userID: Scaffolding.userID, storage: UserDefaults.temporary())
        DeveloperFlag.consumableNotifications.enable(true, storage: .temporary())
        sut = ConsumableNotificationsMigrator(
            sync: mockSync,
            featureConfigRepository: mockFeatureConfigRepository,
            userClientsAPI: mockUserClientsAPI,
            userClientsLocalStore: mockLocalStore,
            apiVersion: .v9,
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

    func test_migrate_userClientNeedsRegistration() async throws {
        // GIVEN
        mockLocalStore.fetchSelfClientID_MockValue = Scaffolding.userID.uuidString
        mockLocalStore.hasRegisteredConsumableNotificationsCapable_MockValue = false
        mockUserClientsAPI.updateClientIdClientUpdate_MockMethod = { _, _ in }
        mockSync.migrateFromIncrementalSyncV1_MockMethod = {}

        // WHEN
        try await sut.migrate()

        // THEN
        XCTAssertEqual(mockUserClientsAPI.updateClientIdClientUpdate_Invocations.count, 1)
        XCTAssertEqual(mockSync.migrateFromIncrementalSyncV1_Invocations.count, 1)
        XCTAssertTrue(journal[.isConsumableNotificationsEnabled])
    }

    func test_migrate_userClientAlreadyCapable() async throws {
        // GIVEN
        mockLocalStore.fetchSelfClientID_MockValue = Scaffolding.userID.uuidString
        mockLocalStore.hasRegisteredConsumableNotificationsCapable_MockValue = true
        mockSync.migrateFromIncrementalSyncV1_MockMethod = {}

        // WHEN
        try await sut.migrate()

        // THEN
        XCTAssertEqual(mockUserClientsAPI.updateClientIdClientUpdate_Invocations.count, 0)
        XCTAssertEqual(mockSync.migrateFromIncrementalSyncV1_Invocations.count, 1)

        XCTAssertTrue(journal[.isConsumableNotificationsEnabled])
    }

    func test_migrate_syncFails_throws() async throws {
        // GIVEN
        mockLocalStore.fetchSelfClientID_MockValue = Scaffolding.userID.uuidString
        mockLocalStore.hasRegisteredConsumableNotificationsCapable_MockValue = false
        mockUserClientsAPI.updateClientIdClientUpdate_MockMethod = { _, _ in }
        let error = TestError(message: "")
        mockSync.migrateFromIncrementalSyncV1_MockError = error

        // WHEN
        await XCTAssertThrowsErrorAsync(error) {
            try await self.sut.migrate()
        }

        // THEN
        XCTAssertEqual(mockUserClientsAPI.updateClientIdClientUpdate_Invocations.count, 1)
        XCTAssertEqual(mockSync.migrateFromIncrementalSyncV1_Invocations.count, 1)
        XCTAssertFalse(journal[.isConsumableNotificationsEnabled])
    }

    func test_migrate_registrationFails_throws() async throws {
        // GIVEN
        mockLocalStore.fetchSelfClientID_MockValue = Scaffolding.userID.uuidString
        mockLocalStore.hasRegisteredConsumableNotificationsCapable_MockValue = false
        let error = TestError(message: "")
        mockUserClientsAPI.updateClientIdClientUpdate_MockError = error

        mockSync.migrateFromIncrementalSyncV1_MockMethod = {}

        // WHEN
        await XCTAssertThrowsErrorAsync(error) {
            try await self.sut.migrate()
        }

        // THEN
        XCTAssertEqual(mockUserClientsAPI.updateClientIdClientUpdate_Invocations.count, 1)
        XCTAssertEqual(mockSync.migrateFromIncrementalSyncV1_Invocations.count, 0)
        XCTAssertFalse(journal[.isConsumableNotificationsEnabled])
    }

    func test_migrate_apiVersionTooLow_throws() async throws {
        // GIVEN
        sut = ConsumableNotificationsMigrator(
            sync: mockSync,
            featureConfigRepository: mockFeatureConfigRepository,
            userClientsAPI: mockUserClientsAPI,
            userClientsLocalStore: mockLocalStore,
            apiVersion: .v7,
            journal: journal
        )

        mockSync.migrateFromIncrementalSyncV1_MockMethod = {}

        // WHEN / THEN
        await XCTAssertThrowsErrorAsync(ConsumableNotificationsMigrator.Failure.apiVersionTooLow) {
            try await self.sut.migrate()
        }
    }

    func test_migrate_featureConfigDisabled_throws() async throws {
        // GIVEN
        mockFeatureConfigRepository.isFeatureEnabled_MockValue = false

        mockSync.migrateFromIncrementalSyncV1_MockMethod = {}

        // WHEN / THEN
        await XCTAssertThrowsErrorAsync(ConsumableNotificationsMigrator.Failure.featureConfigNotEnabled) {
            try await self.sut.migrate()
        }
    }
}
