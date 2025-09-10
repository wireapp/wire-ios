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

    private let coreCryptoKeyMigrationManager: CoreCryptoKeyMigrationManagerProtocol?
    private let userID: UUID

    public init(coreCryptoKeyMigrationManager: CoreCryptoKeyMigrationManagerProtocol?, userID: UUID) {
        self.coreCryptoKeyMigrationManager = coreCryptoKeyMigrationManager
        self.userID = userID
    }

    public func coreCryptoKey(
        createIfNeeded: Bool,
        path: String
    ) async throws -> Data {
        removeLegacyKeyIfNeeded()
        try await migrateKeyIfNeeded(path: path)

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

    public func updateDatabaseKey(path: String) async throws {
        // We need to get the unscoped key because this is part of the migration to 4.3.0
        // and scoped keys haven't been introduced before
        if let oldKey = try? fetchUnscopedCoreCryptoKey() {
            do {
                WireLogger.coreCrypto.info("Updating core crypto key...", attributes: .safePublic)

                let item = ScopedCoreCryptoKeychainItem(userID: userID)
                let newKey = try KeychainManager.generateKey(numberOfBytes: 32)
                try await coreCryptoKeyMigrationManager?.updateKey(path: path, oldKey: oldKey, newKey: newKey)

                // In case another account needs to update it, we don't delete the old key because it's not scoped by account.
                try KeychainManager.storeItem(item, value: newKey)
            } catch {
                WireLogger.coreCrypto.warn("Failed to update core crypto key: \(String(describing: error))", attributes: .safePublic)
                throw error
            }
        }
    }

    public func migrateToScopedDatabaseKey() throws {
        let scopedKeyExists = (try? fetchScopedCoreCryptoKey()) != nil

        guard !scopedKeyExists else { return }

        do {
            WireLogger.coreCrypto.info("Migrating to scoped core crypto key...", attributes: .safePublic)
            let unscopedKey = try fetchUnscopedCoreCryptoKey()
            let item = ScopedCoreCryptoKeychainItem(userID: userID)
            try KeychainManager.storeItem(item, value: unscopedKey)
        } catch {
            WireLogger.coreCrypto.warn("Failed to migrate to scoped core crypto key: \(String(describing: error))", attributes: .safePublic)
            throw error
        }
    }

    private func migrateKeyIfNeeded(path: String) async throws {
        // Getting the unscoped key, because if the scoped key exists, it's already in the right format.
        if let oldKey = try? fetchUnscopedCoreCryptoKey() {
            // Since version 6.x, CC has changed the key format and clients need to migrate the key.
            // We can reuse the same key, but the "new key" must be 'Data'.
            do {
                try await coreCryptoKeyMigrationManager?.performMigrationIfNeeded(
                    path: path,
                    oldKey: oldKey.base64EncodedString(),
                    newKey: oldKey
                )
            } catch {
                WireLogger.coreCrypto.warn("Failed to migrate core crypto key: \(String(describing: error))")
                throw error
            }
        } else {
            // If there is no key,
            // then this is a fresh install and we do not need to perform migration.
            coreCryptoKeyMigrationManager?.markMigrationAsSkipped()
        }
    }

    private func fetchScopedCoreCryptoKey() throws -> Data {
        let item = ScopedCoreCryptoKeychainItem(userID: userID)
        return try KeychainManager.fetchItem(item)
    }

    private func fetchUnscopedCoreCryptoKey() throws -> Data {
        let item = CoreCryptoKeychainItem()
        return try KeychainManager.fetchItem(item)
    }

    private func createScopedCoreCryptoKey() throws -> Data {
        let item = ScopedCoreCryptoKeychainItem(userID: userID)
        let key = try KeychainManager.generateKey(numberOfBytes: 32)
        try KeychainManager.storeItem(item, value: key)
        return key
    }

    private func removeLegacyKeyIfNeeded() {
        let legacyItem = LegacyCoreCryptoKeychainItem()

        do {
            _ = try KeychainManager.fetchItem(legacyItem) as Data
            WireLogger.coreCrypto.info("Found legacy core crypto key. Deleting...")
            try KeychainManager.deleteItem(legacyItem)
            WireLogger.coreCrypto.info("Deleted legacy core crypto key")
        } catch let KeychainManager.Error.failedToDeleteItemFromKeychain(error) {
            WireLogger.coreCrypto.error("Failed to delete legacy core crypto key: \(String(describing: error))")
        } catch {
            // key was not found. no action needed
        }
    }
}

struct ScopedCoreCryptoKeychainItem: KeychainItemProtocol {

    var userID: UUID

    var id: String {
        "com.wire.mls.key.\(userID.uuidString)"
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

struct CoreCryptoKeychainItem: KeychainItemProtocol {

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

struct LegacyCoreCryptoKeychainItem: KeychainItemProtocol {

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
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlocked
        ]
    }

    func setQuery(value: some Any) -> [CFString: Any] {
        [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: tag,
            kSecValueData: value,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlocked
        ]
    }
}
