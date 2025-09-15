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
import WireLogging
import WireSystem

public class CoreCryptoKeyProvider {

    private let coreCryptoKeyMigrationManager: CoreCryptoKeyMigrationManagerProtocol
    private let userID: UUID

    public init(coreCryptoKeyMigrationManager: CoreCryptoKeyMigrationManagerProtocol, userID: UUID) {
        self.coreCryptoKeyMigrationManager = coreCryptoKeyMigrationManager
        self.userID = userID
    }

    public func coreCryptoKey(
        createIfNeeded: Bool,
        path: String
    ) async throws -> Data {
        try await performKeyMigrationsIfNeeded(path: path)

        do {
            return try fetchScopedCoreCryptoKey()
        } catch {
            if createIfNeeded {
                return try createScopedCoreCryptoKey()
            } else {
                throw error
            }
        }
    }

    private func performKeyMigrationsIfNeeded(path: String) async throws {
        try await migrateDatabaseKeyToBytes(path: path)
        try migrateToScopedDatabaseKey(path: path)
        try? await rotateKey(path: path)
    }

    private func migrateToScopedDatabaseKey(path: String) throws {
        let scopedKey = try? fetchScopedCoreCryptoKey()

        guard
            coreCryptoKeyMigrationManager.isMigrationToScopedKeyNeeded,
            let unscopedKey = try? fetchUnscopedCoreCryptoKey(),
            scopedKey == nil
        else { return }

        do {
            WireLogger.coreCrypto.info("Migrating to scoped core crypto key...", attributes: .safePublic)

            // Store the unscoped key as scoped key
            let item = ScopedCoreCryptoKeychainItem(userID: userID)
            try KeychainManager.storeItem(item, value: unscopedKey)

            // Mark migration as done
            coreCryptoKeyMigrationManager.markMigrationToScopedKeyDone()

        } catch {
            WireLogger.coreCrypto.warn(
                "Failed to migrate to scoped core crypto key: \(String(describing: error))",
                attributes: .safePublic
            )
            throw error
        }
    }

    private func rotateKey(path: String) async throws {
        guard coreCryptoKeyMigrationManager.isKeyRotationNeeded else {
            return
        }

        do {
            WireLogger.coreCrypto.info("Updating core crypto key...", attributes: .safePublic)

            // Generate a new key and update the database
            let oldKey = try fetchScopedCoreCryptoKey()
            let newKey = try KeychainManager.generateKey(numberOfBytes: 32)
            try await coreCryptoKeyMigrationManager.updateKey(path: path, oldKey: oldKey, newKey: newKey)

            // Store the new key in place of the old one
            let item = ScopedCoreCryptoKeychainItem(userID: userID)
            try KeychainManager.deleteItem(item)
            try KeychainManager.storeItem(item, value: newKey)

            // Mark the rotation as done
            coreCryptoKeyMigrationManager.markKeyRotationAsDone()

        } catch {
            WireLogger.coreCrypto.warn(
                "Failed to update core crypto key: \(String(describing: error))",
                attributes: .safePublic
            )
            throw error
        }
    }

    private func migrateDatabaseKeyToBytes(path: String) async throws {
        guard coreCryptoKeyMigrationManager.isMigrationToBytesNeeded else { return }

        // Getting the unscoped key, because if the scoped key exists, it's already in the right format.
        if let oldKey = try? fetchUnscopedCoreCryptoKey() {
            // Since version 6.x, CC has changed the key format and clients need to migrate the key.
            // We can reuse the same key, but the "new key" must be 'Data'.
            do {
                try await coreCryptoKeyMigrationManager.migrateDatabaseKeyToBytes(
                    path: path,
                    oldKey: oldKey.base64EncodedString(),
                    newKey: oldKey
                )
            } catch {
                WireLogger.coreCrypto.warn(
                    "Failed to migrate core crypto key: \(String(describing: error))",
                    attributes: .safePublic
                )
                throw error
            }
        } else {
            // If there is no key,
            // then this is a fresh install and we do not need to perform migration.
            coreCryptoKeyMigrationManager.markMigrationToBytesAsSkipped()
        }
    }

    private func fetchScopedCoreCryptoKey() throws -> Data {
        let item = ScopedCoreCryptoKeychainItem(userID: userID)
        return try KeychainManager.fetchItem(item)
    }

    private func fetchUnscopedCoreCryptoKey() throws -> Data {
        let item = UnscopedCoreCryptoKeychainItem()
        return try KeychainManager.fetchItem(item)
    }

    private func createScopedCoreCryptoKey() throws -> Data {
        let item = ScopedCoreCryptoKeychainItem(userID: userID)
        let key = try KeychainManager.generateKey(numberOfBytes: 32)
        try KeychainManager.storeItem(item, value: key)
        return key
    }

}

struct ScopedCoreCryptoKeychainItem: KeychainItemProtocol {

    var userID: UUID

    var id: String {
        "com.wire.cc.key.\(userID.uuidString)"
    }

    var tag: Data {
        id.data(using: .utf8)!
    }

    var getQuery: [CFString: Any] {
        [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: tag,
            kSecReturnData: true,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
        ]
    }

    func setQuery(value: some Any) -> [CFString: Any] {
        [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: tag,
            kSecValueData: value,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
        ]
    }
}

struct UnscopedCoreCryptoKeychainItem: KeychainItemProtocol {

    var id: String {
        "com.wire.mls.key"
    }

    var tag: Data {
        id.data(using: .utf8)!
    }

    var getQuery: [CFString: Any] {
        [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: tag,
            kSecReturnData: true,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
        ]
    }

    func setQuery(value: some Any) -> [CFString: Any] {
        [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: tag,
            kSecValueData: value,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
        ]
    }

}
