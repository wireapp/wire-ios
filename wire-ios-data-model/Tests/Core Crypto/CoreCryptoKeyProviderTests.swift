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
import WireFoundationSupport
import XCTest
@testable import WireDataModel
@testable import WireDataModelSupport

class CoreCryptoKeyProviderTests: XCTestCase {

    var userID = UUID()
    var uniqueKeyId: UUID!
    var mockMigrationManager: MockCoreCryptoKeyMigrationManagerProtocol!
    var mockStaleKeysTracker: MockStaleCoreCryptoKeysTrackerProtocol!
    var mockUserDefaults: UserDefaultsProtocolMock!
    var sut: CoreCryptoKeyProvider!
    var unscopedItem: CoreCryptoKeychainItem!
    var scopedItem: CoreCryptoKeychainItem!
    var storage: [String: Any]!

    override func setUp() {
        super.setUp()

        uniqueKeyId = UUID()

        // Set up migration manager mock
        mockMigrationManager = MockCoreCryptoKeyMigrationManagerProtocol()
        mockMigrationManager.updateKeyPathOldKeyNewKey_MockMethod = { _, _, _ in }
        mockMigrationManager.markKeyRotationAsDone_MockMethod = {}
        mockMigrationManager.markMigrationToBytesAsSkipped_MockMethod = {}
        mockMigrationManager.markMigrationToScopedKeyDone_MockMethod = {}
        mockMigrationManager.isMigrationToBytesNeeded = false
        mockMigrationManager.isMigrationToScopedKeyNeeded = false
        mockMigrationManager.isKeyRotationNeeded = false

        // Set up stale key tracker mocks
        mockStaleKeysTracker = MockStaleCoreCryptoKeysTrackerProtocol()

        // Set up user defaults mock
        storage = [:]
        let uniqueKeyIdDefaultsKey = "\(userID.uuidString)_\(CoreCryptoKeyProviderDefaults.uniqueKeyIdentifier)"
        mockUserDefaults = UserDefaultsProtocolMock()
        mockUserDefaults.setValueAnyForKeyDefaultNameStringVoidClosure = { value, key in
            if
                key == uniqueKeyIdDefaultsKey,
                let stringValue = value as? String,
                let uuidValue = UUID(uuidString: stringValue) {
                self.uniqueKeyId = uuidValue
            } else {
                self.storage[key] = value
            }
        }
        mockUserDefaults.stringForKeyDefaultNameStringStringClosure = { key in
            if key == uniqueKeyIdDefaultsKey {
                return self.uniqueKeyId.uuidString
            }
            return self.storage[key] as? String
        }

        // Set up sut
        sut = CoreCryptoKeyProvider(
            coreCryptoKeyMigrationManager: mockMigrationManager,
            userID: userID,
            storage: mockUserDefaults,
            staleKeysTracker: mockStaleKeysTracker
        )

        // Set up the keychain items
        unscopedItem = CoreCryptoKeychainItem(
            uniqueKeyId: UUID(),
            userID: UUID(),
            scoped: false
        )
        scopedItem = CoreCryptoKeychainItem(
            uniqueKeyId: uniqueKeyId,
            userID: userID
        )
    }

    override func tearDown() {
        try? KeychainManager.deleteItem(unscopedItem)
        try? KeychainManager.deleteItem(scopedItem)
        mockUserDefaults = nil
        mockMigrationManager = nil
        mockStaleKeysTracker = nil
        sut = nil
        unscopedItem = nil
        scopedItem = nil
        super.tearDown()
    }

    // MARK: Fetching & creating key

    func test_itFetchesCoreCryptoKey() async throws {
        // GIVEN
        let expectedKey = try KeychainManager.generateKey(numberOfBytes: 32)
        try KeychainManager.storeItem(scopedItem, value: expectedKey)

        // WHEN
        let key = try await sut.coreCryptoKey(allowCreation: false, path: "")

        // THEN
        XCTAssertEqual(key, expectedKey)
    }

    func test_itDoesntCreateCoreCryptoKey_WhenNotAllowed() async {
        // WHEN
        await XCTAssertThrowsErrorAsync {
            _ = try await sut.coreCryptoKey(allowCreation: false, path: "")
        }

        // THEN
        XCTAssertNil(try? KeychainManager.fetchItem(scopedItem))
    }

    func test_itCreatesCoreCryptoKey_WhenAllowed() async throws {
        // WHEN
        let key = try await sut.coreCryptoKey(allowCreation: true, path: "")

        // THEN
        XCTAssertNotNil(key)

        let storedKey: Data? = try? KeychainManager.fetchItem(scopedItem)
        XCTAssertNotNil(storedKey)
        XCTAssertEqual(key, storedKey)
    }

    // MARK: Migrating key
    
    func test_itAvoidsMigrationToBytes_WhenNotAllowed() async throws {
        // GIVEN
        mockMigrationManager.isMigrationToBytesNeeded = true

        // WHEN
        await XCTAssertThrowsErrorAsync {
            _ = try await sut.coreCryptoKey(allowCreation: false, path: "")
        }
        
        // THEN
        XCTAssertTrue(mockMigrationManager.markMigrationToBytesAsSkipped_Invocations.isEmpty)
    }
        
    func test_itMarksMigrationToBytesAsSkipped_WhenAllowed_AndThereIsNoKey() async throws {
        // GIVEN
        mockMigrationManager.isMigrationToBytesNeeded = true

        // WHEN
        _ = try await sut.coreCryptoKey(allowCreation: true, path: "")

        // THEN
        XCTAssertEqual(mockMigrationManager.markMigrationToBytesAsSkipped_Invocations.count, 1)
    }

    func test_itPerformsMigrationToBytes_WhenAllowed() async throws {
        // GIVEN
        mockMigrationManager.isMigrationToBytesNeeded = true

        var receivedNewKey: Data?
        mockMigrationManager.migrateDatabaseKeyToBytesPathOldKeyNewKey_MockMethod = { _, _, newKey in
            receivedNewKey = newKey
        }

        let expectedKey = try KeychainManager.generateKey(numberOfBytes: 32)
        try KeychainManager.storeItem(unscopedItem, value: expectedKey)

        // WHEN
        _ = try? await sut.coreCryptoKey(allowCreation: true, path: "")

        // THEN
        XCTAssertEqual(mockMigrationManager.migrateDatabaseKeyToBytesPathOldKeyNewKey_Invocations.count, 1)
        XCTAssertEqual(receivedNewKey, expectedKey)
    }

    // MARK: Scoping key

    func test_itAvoidsScopedKeyMigration_WhenNotAllowed() async throws {
        // GIVEN
        mockMigrationManager.isMigrationToScopedKeyNeeded = true
        
        // create unscoped key
        let unscopedKey = try KeychainManager.generateKey(numberOfBytes: 32)
        try KeychainManager.storeItem(unscopedItem, value: unscopedKey)
        
        // WHEN
        _ = try? await sut.coreCryptoKey(allowCreation: false, path: "")
        
        // THEN
        let scopedKey: Data? = try? KeychainManager.fetchItem(scopedItem)
        XCTAssertNil(scopedKey)
    }
    
    func test_itMigratesToScopedKey_WhenAllowed() async throws {
        // GIVEN
        mockMigrationManager.isMigrationToScopedKeyNeeded = true
        mockMigrationManager.markMigrationToScopedKeyDone_MockMethod = { [mockMigrationManager] in
            mockMigrationManager?.isMigrationToScopedKeyNeeded = false
        }

        // create unscoped key
        let unscopedKey = try KeychainManager.generateKey(numberOfBytes: 32)
        try KeychainManager.storeItem(unscopedItem, value: unscopedKey)

        // WHEN
        _ = try? await sut.coreCryptoKey(allowCreation: true, path: "")

        // THEN
        let scopedKey: Data? = try? KeychainManager.fetchItem(scopedItem)
        XCTAssertNotNil(scopedKey)
        XCTAssertEqual(unscopedKey, scopedKey)
    }

    func test_itSkipsScopedKeyMigration_WhenAllowed_AndNotNeeded() async throws {
        // GIVEN
        mockMigrationManager.isMigrationToScopedKeyNeeded = false

        // create unscoped key
        let unscopedKey = try KeychainManager.generateKey(numberOfBytes: 32)
        try KeychainManager.storeItem(unscopedItem, value: unscopedKey)

        // WHEN
        _ = try? await sut.coreCryptoKey(allowCreation: true, path: "")

        // THEN
        XCTAssertEqual(mockMigrationManager.markMigrationToScopedKeyDone_Invocations.count, 0)
    }

    func test_itMarksScopedKeyMigrationAsDone_WhenAllowed_AndScopedKeyAlreadyExists() async throws {
        // GIVEN
        mockMigrationManager.isMigrationToScopedKeyNeeded = true

        // create unscoped key
        let unscopedKey = try KeychainManager.generateKey(numberOfBytes: 32)
        try KeychainManager.storeItem(unscopedItem, value: unscopedKey)

        // create scoped key
        let scopedKey = try KeychainManager.generateKey(numberOfBytes: 32)
        try KeychainManager.storeItem(scopedItem, value: scopedKey)

        // WHEN
        _ = try? await sut.coreCryptoKey(allowCreation: true, path: "")

        // THEN
        XCTAssertEqual(mockMigrationManager.markMigrationToScopedKeyDone_Invocations.count, 1)
    }

    // MARK: Rotating key
    
    func test_itAvoidsRotatingTheDatabaseKey_WhenNotAllowed() async throws {
        // GIVEN
        mockMigrationManager.isKeyRotationNeeded = true
        
        // create scoped key item as current key
        let oldKeyId = uniqueKeyId
        let oldKeyItem = scopedItem!
        let oldKey = try KeychainManager.generateKey(numberOfBytes: 32)
        try KeychainManager.storeItem(oldKeyItem, value: oldKey)
        
        // WHEN
        _ = try? await sut.coreCryptoKey(allowCreation: false, path: "")
        
        // THEN
        // verify it didn't update the key
        XCTAssertTrue(mockMigrationManager.updateKeyPathOldKeyNewKey_Invocations.isEmpty)
 
        // verify the old key is still there
        XCTAssertNotNil(try? KeychainManager.fetchItem(oldKeyItem))

        // verify it didn't change the key ID
        XCTAssertEqual(oldKeyId, uniqueKeyId)
        
        // verify it didn't mark the rotation as done
        XCTAssertTrue(mockMigrationManager.markKeyRotationAsDone_Invocations.isEmpty)
    }

    func test_itRotatesTheDatabaseKey_WhenAllowed() async throws {
        // GIVEN
        mockMigrationManager.isKeyRotationNeeded = true
        mockMigrationManager.markKeyRotationAsDone_MockMethod = { [mockMigrationManager] in
            mockMigrationManager?.isKeyRotationNeeded = false
        }

        // create scoped key item as current key
        let oldKeyId = uniqueKeyId
        let oldKeyItem = scopedItem!
        let oldKey = try KeychainManager.generateKey(numberOfBytes: 32)
        try KeychainManager.storeItem(oldKeyItem, value: oldKey)

        // set the mock for key rotation
        var expectedNewKey: Data?
        mockMigrationManager.updateKeyPathOldKeyNewKey_MockMethod = { _, _oldKey, _newKey in
            // verify it updates the old key
            XCTAssertEqual(oldKey, _oldKey)

            // save value of new key
            expectedNewKey = _newKey
        }

        // WHEN
        _ = try? await sut.coreCryptoKey(allowCreation: true, path: "")

        // THEN
        // verify it updated the key
        XCTAssertEqual(mockMigrationManager.updateKeyPathOldKeyNewKey_Invocations.count, 1)

        // verify it created a new unique id and a new key, and saved it in keychain
        XCTAssertNotEqual(oldKeyId, uniqueKeyId)
        let newKeyItem = CoreCryptoKeychainItem(uniqueKeyId: uniqueKeyId, userID: userID)
        let newKey: Data? = try? KeychainManager.fetchItem(newKeyItem)
        XCTAssertNotNil(newKey)
        XCTAssertEqual(newKey, expectedNewKey)

        // verify it deleted the old key
        XCTAssertNil(try? KeychainManager.fetchItem(oldKeyItem))

        // verify we marked migration as done
        XCTAssertFalse(mockMigrationManager.isKeyRotationNeeded)

        // clean up
        try? KeychainManager.deleteItem(oldKeyItem)
        try? KeychainManager.deleteItem(newKeyItem)
    }

    func test_itSkipsKeyRotation_WhenAllowed_AndNotNeeded() async throws {
        // GIVEN
        mockMigrationManager.isKeyRotationNeeded = false

        // create scoped key
        let scopedKey = try KeychainManager.generateKey(numberOfBytes: 32)
        try KeychainManager.storeItem(scopedItem, value: scopedKey)

        // WHEN
        _ = try? await sut.coreCryptoKey(allowCreation: true, path: "")

        // THEN
        XCTAssertEqual(mockMigrationManager.updateKeyPathOldKeyNewKey_Invocations.count, 0)
    }
    
    func test_itMarksKeyRotationAsDone_WhenAllowed_AndNoKeyExists() async throws {
        // GIVEN
        mockMigrationManager.isKeyRotationNeeded = true
        
        // WHEN
        _ = try? await sut.coreCryptoKey(allowCreation: true, path: "")
        
        // THEN
        XCTAssertEqual(mockMigrationManager.markKeyRotationAsDone_Invocations.count, 1)
    }

}
