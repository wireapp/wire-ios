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

    override func tearDown() {
        super.tearDown()
        try? KeychainManager.deleteItem(UnscopedCoreCryptoKeychainItem())
    }

    // MARK: Fetching & creating key

    func test_itFetchesCoreCryptoKey() async throws {
        // GIVEN
        let mockCoreCryptoKeyMigrationManager = MockCoreCryptoKeyMigrationManagerProtocol()
        let sut = CoreCryptoKeyProvider(coreCryptoKeyMigrationManager: mockCoreCryptoKeyMigrationManager)
        mockCoreCryptoKeyMigrationManager.performMigrationIfNeededPathOldKeyNewKey_MockMethod = { _, _, _ in }

        let item = UnscopedCoreCryptoKeychainItem()
        let expectedKey = try KeychainManager.generateKey(numberOfBytes: 32)
        try KeychainManager.storeItem(item, value: expectedKey)

        // WHEN
        let key = try await sut.coreCryptoKey(createIfNeeded: false, path: "")

        // THEN
        XCTAssertEqual(key, expectedKey)
    }

    func test_itDoesntCreateCoreCryptoKey_WhenNotNeeded() async {
        // GIVEN
        let mockCoreCryptoKeyMigrationManager = MockCoreCryptoKeyMigrationManagerProtocol()
        let sut = CoreCryptoKeyProvider(coreCryptoKeyMigrationManager: mockCoreCryptoKeyMigrationManager)
        mockCoreCryptoKeyMigrationManager.performMigrationIfNeededPathOldKeyNewKey_MockMethod = { _, _, _ in }
        mockCoreCryptoKeyMigrationManager.markMigrationAsSkipped_MockMethod = {}

        // WHEN
        await XCTAssertThrowsErrorAsync {
            _ = try await sut.coreCryptoKey(createIfNeeded: false, path: "")
        }

        // THEN
        XCTAssertNil(try? KeychainManager.fetchItem(UnscopedCoreCryptoKeychainItem()))
    }

    func test_itCreatesCoreCryptoKey_WhenNeeded() async throws {
        // GIVEN
        let mockCoreCryptoKeyMigrationManager = MockCoreCryptoKeyMigrationManagerProtocol()
        let sut = CoreCryptoKeyProvider(coreCryptoKeyMigrationManager: mockCoreCryptoKeyMigrationManager)
        mockCoreCryptoKeyMigrationManager.performMigrationIfNeededPathOldKeyNewKey_MockMethod = { _, _, _ in }
        mockCoreCryptoKeyMigrationManager.markMigrationAsSkipped_MockMethod = {}

        // WHEN
        let key = try await sut.coreCryptoKey(createIfNeeded: true, path: "")

        // THEN
        XCTAssertNotNil(key)

        let storedKey: Data? = try? KeychainManager.fetchItem(UnscopedCoreCryptoKeychainItem())
        XCTAssertNotNil(storedKey)
        XCTAssertEqual(key, storedKey)
    }

    // MARK: Migrating key

    func test_itSkipsKeyMigration() async throws {
        // GIVEN
        let mockCoreCryptoKeyMigrationManager = MockCoreCryptoKeyMigrationManagerProtocol()
        let sut = CoreCryptoKeyProvider(coreCryptoKeyMigrationManager: mockCoreCryptoKeyMigrationManager)
        mockCoreCryptoKeyMigrationManager.markMigrationAsSkipped_MockMethod = {}

        // WHEN
        await XCTAssertThrowsErrorAsync {
            _ = try await sut.coreCryptoKey(createIfNeeded: false, path: "")
        }

        // THEN
        XCTAssertEqual(mockCoreCryptoKeyMigrationManager.markMigrationAsSkipped_Invocations.count, 1)
    }

    func test_itPerformsKeyMigration() async throws {
        // GIVEN
        let mockCoreCryptoKeyMigrationManager = MockCoreCryptoKeyMigrationManagerProtocol()
        let sut = CoreCryptoKeyProvider(coreCryptoKeyMigrationManager: mockCoreCryptoKeyMigrationManager)
        mockCoreCryptoKeyMigrationManager.performMigrationIfNeededPathOldKeyNewKey_MockMethod = { _, _, _ in }

        let item = UnscopedCoreCryptoKeychainItem()
        let expectedKey = try KeychainManager.generateKey(numberOfBytes: 32)
        try KeychainManager.storeItem(item, value: expectedKey)

        // WHEN
        _ = try? await sut.coreCryptoKey(createIfNeeded: false, path: "")

        // THEN

        XCTAssertEqual(mockCoreCryptoKeyMigrationManager.performMigrationIfNeededPathOldKeyNewKey_Invocations.count, 1)
    }

    func test_itPerformsKeyUpdate() async throws {
        // GIVEN
        let mockCoreCryptoKeyMigrationManager = MockCoreCryptoKeyMigrationManagerProtocol()
        let sut = CoreCryptoKeyProvider(coreCryptoKeyMigrationManager: mockCoreCryptoKeyMigrationManager)
        mockCoreCryptoKeyMigrationManager.updateKeyPathOldKeyNewKey_MockMethod = { _, _, _ in }
        mockCoreCryptoKeyMigrationManager.performMigrationIfNeededPathOldKeyNewKey_MockMethod = { _, _, _ in }
        mockCoreCryptoKeyMigrationManager.markMigrationAsSkipped_MockMethod = {}

        let item = UnscopedCoreCryptoKeychainItem()
        let oldKey = try KeychainManager.generateKey(numberOfBytes: 32)
        try KeychainManager.storeItem(item, value: oldKey)

        // WHEN
        try? await sut.updateDatabaseKey(path: "")

        // THEN
        XCTAssertEqual(mockCoreCryptoKeyMigrationManager.updateKeyPathOldKeyNewKey_Invocations.count, 1)

        let newKey = try? await sut.coreCryptoKey(createIfNeeded: false, path: "")
        XCTAssertNotEqual(oldKey, newKey)
    }

}
