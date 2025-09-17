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

import Foundation
import XCTest
@testable import WireDataModel
@testable import WireDataModelSupport

class CoreCryptoKeyProviderTests: XCTestCase {

    var userID: UUID = .init()
    var userID2: UUID = .init()
    var mockMigrationManager: MockCoreCryptoKeyMigrationManagerProtocol!
    var sut: CoreCryptoKeyProvider!

    override func setUp() {
        super.setUp()
        mockMigrationManager = MockCoreCryptoKeyMigrationManagerProtocol()
        mockMigrationManager.updateKeyPathOldKeyNewKey_MockMethod = { _, _, _ in }
        mockMigrationManager.markKeyRotationAsDone_MockMethod = {}
        mockMigrationManager.markMigrationToBytesAsSkipped_MockMethod = {}
        mockMigrationManager.markMigrationToScopedKeyDone_MockMethod = {}
        mockMigrationManager.isMigrationToBytesNeeded = false
        mockMigrationManager.isMigrationToScopedKeyNeeded = false
        mockMigrationManager.isKeyRotationNeeded = false
        sut = CoreCryptoKeyProvider(coreCryptoKeyMigrationManager: mockMigrationManager, userID: userID)
    }

    override func tearDown() {
        try? KeychainManager.deleteItem(UnscopedCoreCryptoKeychainItem())
        try? KeychainManager.deleteItem(ScopedCoreCryptoKeychainItem(userID: userID))
        try? KeychainManager.deleteItem(ScopedCoreCryptoKeychainItem(userID: userID2))
        mockMigrationManager = nil
        sut = nil
        super.tearDown()
    }

    // MARK: Fetching & creating key

    func test_itFetchesCoreCryptoKey() async throws {
        // GIVEN
        let item = ScopedCoreCryptoKeychainItem(userID: userID)
        let expectedKey = try KeychainManager.generateKey(numberOfBytes: 32)
        try KeychainManager.storeItem(item, value: expectedKey)

        // WHEN
        let key = try await sut.coreCryptoKey(createIfNeeded: false, path: "")

        // THEN
        XCTAssertEqual(key, expectedKey)
    }

    func test_itDoesntCreateCoreCryptoKey_WhenNotNeeded() async {
        // WHEN
        await XCTAssertThrowsErrorAsync {
            _ = try await sut.coreCryptoKey(createIfNeeded: false, path: "")
        }

        // THEN
        XCTAssertNil(try? KeychainManager.fetchItem(ScopedCoreCryptoKeychainItem(userID: userID)))
    }

    func test_itCreatesCoreCryptoKey_WhenNeeded() async throws {
        // WHEN
        let key = try await sut.coreCryptoKey(createIfNeeded: true, path: "")

        // THEN
        XCTAssertNotNil(key)

        let storedKey: Data? = try? KeychainManager.fetchItem(ScopedCoreCryptoKeychainItem(userID: userID))
        XCTAssertNotNil(storedKey)
        XCTAssertEqual(key, storedKey)
    }

    // MARK: Migrating key

    func test_itSkipsMigrationToBytes_WhenThereIsNoKey() async throws {
        // GIVEN
        mockMigrationManager.isMigrationToBytesNeeded = true

        // WHEN
        await XCTAssertThrowsErrorAsync {
            _ = try await sut.coreCryptoKey(createIfNeeded: false, path: "")
        }

        // THEN
        XCTAssertEqual(mockMigrationManager.markMigrationToBytesAsSkipped_Invocations.count, 1)
    }

    func test_itPerformsMigrationToBytes() async throws {
        // GIVEN
        mockMigrationManager.isMigrationToBytesNeeded = true

        var receivedNewKey: Data?
        mockMigrationManager.migrateDatabaseKeyToBytesPathOldKeyNewKey_MockMethod = { _, _, newKey in
            receivedNewKey = newKey
        }

        let item = UnscopedCoreCryptoKeychainItem()
        let expectedKey = try KeychainManager.generateKey(numberOfBytes: 32)
        try KeychainManager.storeItem(item, value: expectedKey)

        // WHEN
        _ = try? await sut.coreCryptoKey(createIfNeeded: false, path: "")

        // THEN
        XCTAssertEqual(mockMigrationManager.migrateDatabaseKeyToBytesPathOldKeyNewKey_Invocations.count, 1)
        XCTAssertEqual(receivedNewKey, expectedKey)
    }

    // MARK:

    func test_itMigratesToScopedKey_AndRotatesTheDatabaseKey() async throws {
        // GIVEN
        mockMigrationManager.isMigrationToScopedKeyNeeded = true
        mockMigrationManager.isKeyRotationNeeded = true
        mockMigrationManager.markKeyRotationAsDone_MockMethod = { [mockMigrationManager] in
            mockMigrationManager?.isKeyRotationNeeded = false
        }
        mockMigrationManager.markMigrationToScopedKeyDone_MockMethod = { [mockMigrationManager] in
            mockMigrationManager?.isMigrationToScopedKeyNeeded = false
        }

        // create unscoped key
        let unscopedItem = UnscopedCoreCryptoKeychainItem()
        let unscopedKey = try KeychainManager.generateKey(numberOfBytes: 32)
        try KeychainManager.storeItem(unscopedItem, value: unscopedKey)

        // create scoped key item
        let scopedItem = ScopedCoreCryptoKeychainItem(userID: userID)

        // Set the mock for key rotation
        var expectedNewKey: Data?
        mockMigrationManager.updateKeyPathOldKeyNewKey_MockMethod = { _, oldKey, newKey in
            // verify it updates the unscoped key
            XCTAssertEqual(oldKey, unscopedKey)

            // save value of new key
            expectedNewKey = newKey
        }

        // WHEN
        _ = try? await sut.coreCryptoKey(createIfNeeded: false, path: "")

        // THEN
        // verify it updated the key
        XCTAssertEqual(mockMigrationManager.updateKeyPathOldKeyNewKey_Invocations.count, 1)

        // verify the new key is saved as a scoped key
        let scopedKey: Data? = try? KeychainManager.fetchItem(scopedItem)
        XCTAssertNotNil(scopedKey)
        XCTAssertEqual(expectedNewKey, scopedKey)

        // verify we marked migrations as done
        XCTAssertFalse(mockMigrationManager.isMigrationToScopedKeyNeeded)
        XCTAssertFalse(mockMigrationManager.isKeyRotationNeeded)
    }

    func test_itSkipsScopedKeyMigration_WhenNotNeeded() async throws {
        // GIVEN
        mockMigrationManager.isMigrationToScopedKeyNeeded = false

        // create unscoped key
        let unscopedItem = UnscopedCoreCryptoKeychainItem()
        let unscopedKey = try KeychainManager.generateKey(numberOfBytes: 32)
        try KeychainManager.storeItem(unscopedItem, value: unscopedKey)

        // WHEN
        _ = try? await sut.coreCryptoKey(createIfNeeded: false, path: "")

        // THEN
        XCTAssertEqual(mockMigrationManager.markMigrationToScopedKeyDone_Invocations.count, 0)
    }

    func test_itMarksScopedKeyMigrationAsDone_WhenScopedKeyAlreadyExists() async throws {
        // GIVEN
        mockMigrationManager.isMigrationToScopedKeyNeeded = true

        // create unscoped key
        let unscopedItem = UnscopedCoreCryptoKeychainItem()
        let unscopedKey = try KeychainManager.generateKey(numberOfBytes: 32)
        try KeychainManager.storeItem(unscopedItem, value: unscopedKey)

        // create scoped key
        let scopedItem = ScopedCoreCryptoKeychainItem(userID: userID)
        let scopedKey = try KeychainManager.generateKey(numberOfBytes: 32)
        try KeychainManager.storeItem(scopedItem, value: scopedKey)

        // WHEN
        _ = try? await sut.coreCryptoKey(createIfNeeded: false, path: "")

        // THEN
        XCTAssertEqual(mockMigrationManager.markMigrationToScopedKeyDone_Invocations.count, 1)
    }

    func test_itSkipsKeyRotation_WhenNotNeeded() async throws {
        // GIVEN
        mockMigrationManager.isKeyRotationNeeded = false

        // create scoped key
        let scopedItem = ScopedCoreCryptoKeychainItem(userID: userID)
        let scopedKey = try KeychainManager.generateKey(numberOfBytes: 32)
        try KeychainManager.storeItem(scopedItem, value: scopedKey)

        // WHEN
        _ = try? await sut.coreCryptoKey(createIfNeeded: false, path: "")

        // THEN
        XCTAssertEqual(mockMigrationManager.updateKeyPathOldKeyNewKey_Invocations.count, 0)
    }

}
