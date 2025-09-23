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
import WireFoundation

enum CoreCryptoKeyProviderDefaults: String, DefaultsKey {
    case uniqueKeyIdentifier
}

public class CoreCryptoKeyProvider {

    private let coreCryptoKeyMigrationManager: CoreCryptoKeyMigrationManagerProtocol
    private let defaults: PrivateUserDefaults<CoreCryptoKeyProviderDefaults>
    
    /// We use the unique key id to scope the database key by user session.
    /// Since the id is tied to the user defaults, it gets deleted on logout and app deletion
    private var uniqueKeyId: UUID {
        get {
            if let id = defaults.getUUID(forKey: .uniqueKeyIdentifier) {
                return id
            } else {
                let id = UUID()
                defaults.setUUID(id, forKey: .uniqueKeyIdentifier)
                return id
            }
        } set {
            defaults.setUUID(newValue, forKey: .uniqueKeyIdentifier)
        }
    }
    
    public init(
        coreCryptoKeyMigrationManager: CoreCryptoKeyMigrationManagerProtocol,
        userID: UUID
    ) {
        self.coreCryptoKeyMigrationManager = coreCryptoKeyMigrationManager
        self.defaults = PrivateUserDefaults(userID: userID)
    }

    public func coreCryptoKey(
        createIfNeeded: Bool,
        path: String
    ) async throws -> Data {
        try await performKeyMigrationsIfNeeded(path: path)

        if let key = try fetchCoreCryptoKey() {
            return key
        } else if createIfNeeded {
            return try createCoreCryptoKey()
        } else {
            throw Error.keyNotFound
        }
    }

    private func performKeyMigrationsIfNeeded(path: String) async throws {
        try await migrateDatabaseKeyToBytes(path: path)
        try migrateToScopedDatabaseKey(path: path)
        try? await rotateKeyIfNeeded(path: path)
    }

    private func migrateToScopedDatabaseKey(path: String) throws {

        guard
            coreCryptoKeyMigrationManager.isMigrationToScopedKeyNeeded,
            let unscopedKey = try fetchCoreCryptoKey(scoped: false)
        else { return }

        if (try fetchCoreCryptoKey()) != nil {
            coreCryptoKeyMigrationManager.markMigrationToScopedKeyDone()
        } else {
            do {
                WireLogger.coreCrypto.info("Migrating to scoped core crypto key...", attributes: .safePublic)

                // Store the unscoped key as scoped key
                let item = CoreCryptoKeychainItem(uniqueKeyId: uniqueKeyId)
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
    }

    private func rotateKeyIfNeeded(path: String) async throws {
        guard coreCryptoKeyMigrationManager.isKeyRotationNeeded else {
            return
        }
        
        do {
            WireLogger.coreCrypto.info("Rotating core crypto key...", attributes: .safePublic)
            try await rotateKey(path: path)
        } catch {
            WireLogger.coreCrypto.warn(
                "Failed to rotate core crypto key: \(String(describing: error))",
                attributes: .safePublic
            )
            throw error
        }
    }
    
    private func rotateKey(path: String) async throws {

        // Get the old key, to rotate with the new key
        guard let oldKey = try fetchCoreCryptoKey() else {
            throw Error.keyNotFound
        }
        let oldKeyId = uniqueKeyId
        let oldItem = CoreCryptoKeychainItem(uniqueKeyId: oldKeyId)
        logRotation("fetched the old key")
            
        // Generate a new key and save it with a new key ID
        let newKey = try KeychainManager.generateKey(numberOfBytes: 32)
        let newKeyId = UUID()
        let newItem = CoreCryptoKeychainItem(uniqueKeyId: newKeyId)
        try KeychainManager.storeItem(newItem, value: newKey)
        logRotation("generated and saved the new key")
        
        do {
            // Update the database
            try await coreCryptoKeyMigrationManager.updateKey(path: path, oldKey: oldKey, newKey: newKey)
            logRotation("updated the database with the new key")
            
            // Delete the old key
            deleteOrMarkAsStale(item: oldItem)
            logRotation("deleted or marked old key as stale")
            
            // Update the unique key identifier
            uniqueKeyId = newKeyId
            logRotation("updated unique key identifier")
            
            // Mark the rotation as done
            coreCryptoKeyMigrationManager.markKeyRotationAsDone()
            logRotation("marked key rotation as done")

        } catch {
            
            // Check if we need to clean up or rollback, otherwise throw the error
            switch error {
            case CoreCryptoKeyMigrationManagerError.failedToUpdateKey(let underlyingError):
                
                // We failed to rotate the key, rollback by deleting the new key
                deleteOrMarkAsStale(item: newItem)
                logRotation("rollback: deleted or marked new key as stale")
                throw underlyingError
  
            default:
                throw error
            }
        }
    }
    
    private func logRotation(_ message: String) {
        WireLogger.coreCrypto.info("[key rotation] \(message)")
    }
    
    private func deleteOrMarkAsStale(item: CoreCryptoKeychainItem) {
        do {
            try KeychainManager.deleteItem(item)
        } catch {
            StaleCoreCryptoKeysTracker.addKey(id: item.uniqueKeyId)
        }
    }

    private func migrateDatabaseKeyToBytes(path: String) async throws {
        guard coreCryptoKeyMigrationManager.isMigrationToBytesNeeded else { return }

        // Getting the unscoped key, because if the scoped key exists, it's already in the right format.
        if let oldKey = try? fetchCoreCryptoKey(scoped: false) {
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

    private func fetchCoreCryptoKey(scoped: Bool = true) throws -> Data? {
        do {
            let item = CoreCryptoKeychainItem(uniqueKeyId: uniqueKeyId, scoped: scoped)
            return try KeychainManager.fetchItem(item)
        } catch KeychainManager.Error.failedToFetchItemFromKeychain(errSecItemNotFound) {
            return nil
        } catch {
            throw error
        }
    }

    private func createCoreCryptoKey() throws -> Data {
        let item = CoreCryptoKeychainItem(uniqueKeyId: uniqueKeyId)
        let key = try KeychainManager.generateKey(numberOfBytes: 32)
        try KeychainManager.storeItem(item, value: key)
        return key
    }

}

public extension CoreCryptoKeyProvider {
    
    enum Error: Swift.Error {
        case keyNotFound
    }
}

struct CoreCryptoKeychainItem: KeychainItemProtocol {

    let uniqueKeyId: UUID
    var scoped: Bool = true

    var id: String {
        if scoped {
            "com.wire.cc.key.\(uniqueKeyId.uuidString)"
        } else {
            "com.wire.mls.key"
        }
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

