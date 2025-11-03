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
import WireFoundation
import WireLegacyLogging
import WireSystem

public enum CoreCryptoKeyProviderDefaults: String, DefaultsKey {
    case uniqueKeyIdentifier
}

public class CoreCryptoKeyProvider {

    private let coreCryptoKeyMigrationManager: CoreCryptoKeyMigrationManagerProtocol
    private let staleKeysTracker: StaleCoreCryptoKeysTrackerProtocol
    private let defaults: PrivateUserDefaults<CoreCryptoKeyProviderDefaults>
    private let userID: UUID

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

    public convenience init(
        coreCryptoKeyMigrationManager: CoreCryptoKeyMigrationManagerProtocol,
        userID: UUID,
        storage: UserDefaultsProtocol,
    ) {
        self.init(
            coreCryptoKeyMigrationManager: coreCryptoKeyMigrationManager,
            userID: userID,
            storage: storage,
            staleKeysTracker: StaleCoreCryptoKeysTracker(defaults: storage)
        )
    }

    init(
        coreCryptoKeyMigrationManager: CoreCryptoKeyMigrationManagerProtocol,
        userID: UUID,
        storage: UserDefaultsProtocol,
        staleKeysTracker: StaleCoreCryptoKeysTrackerProtocol,
    ) {
        self.coreCryptoKeyMigrationManager = coreCryptoKeyMigrationManager
        self.defaults = PrivateUserDefaults(userID: userID, storage: storage)
        self.userID = userID
        self.staleKeysTracker = staleKeysTracker
    }

    public func coreCryptoKey(
        createIfNeeded: Bool,
        path: String
    ) async throws -> Data {
        try await performKeyMigrationsIfNeeded(path: path)

        if let key = try fetchCoreCryptoKey(scoped: true) {
            return key
        } else if createIfNeeded {
            return try createCoreCryptoKey()
        } else {
            throw Failure.keyNotFound
        }
    }

    private func performKeyMigrationsIfNeeded(path: String) async throws {
        try await migrateDatabaseKeyToBytes(path: path)
        try migrateToScopedDatabaseKey(path: path)
        try await rotateKeyIfNeeded(path: path)
    }

    private func migrateToScopedDatabaseKey(path: String) throws {

        guard
            coreCryptoKeyMigrationManager.isMigrationToScopedKeyNeeded,
            let unscopedKey = try fetchCoreCryptoKey(scoped: false)
        else { return }

        if (try fetchCoreCryptoKey(scoped: true)) != nil {
            coreCryptoKeyMigrationManager.markMigrationToScopedKeyDone()
        } else {
            do {
                WireLogger.coreCrypto.info("Migrating to scoped core crypto key...", attributes: .safePublic)

                // Store the unscoped key as scoped key
                let item = CoreCryptoKeychainItem(uniqueKeyId: uniqueKeyId, userID: userID)
                try KeychainManager.storeItem(item, value: unscopedKey)

                // Mark migration as done
                coreCryptoKeyMigrationManager.markMigrationToScopedKeyDone()

            } catch {
                throw Failure.failedToScopeKey(error)
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
        } catch Failure.keyNotFound {
            WireLogger.coreCrypto.info("Aborting key rotation: old key not found", attributes: .safePublic)
            return
        } catch {
            throw Failure.failedToRotateKey(error)
        }
    }

    private func rotateKey(path: String) async throws {

        // Get the old key, to rotate with the new key
        guard let oldKey = try fetchCoreCryptoKey(scoped: true) else {
            throw Failure.keyNotFound
        }
        let oldKeyId = uniqueKeyId
        let oldItem = CoreCryptoKeychainItem(uniqueKeyId: oldKeyId, userID: userID)
        logRotation("fetched the old key")

        // Generate a new key and save it with a new key ID
        let newKey = try KeychainManager.generateKey(numberOfBytes: 32)
        let newKeyId = UUID()
        let newItem = CoreCryptoKeychainItem(uniqueKeyId: newKeyId, userID: userID)
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

        } catch let CoreCryptoKeyMigrationManagerError.failedToUpdateKey(underlyingError) {

            // We failed to rotate the key, rollback by deleting the new key
            deleteOrMarkAsStale(item: newItem)
            logRotation("rollback: deleted or marked new key as stale")
            throw CoreCryptoKeyMigrationManagerError.failedToUpdateKey(underlyingError: underlyingError)
        }
    }

    private func logRotation(_ message: String) {
        WireLogger.coreCrypto.info("[key rotation] \(message)", attributes: .safePublic)
    }

    private func deleteOrMarkAsStale(item: CoreCryptoKeychainItem) {
        do {
            try KeychainManager.deleteItem(item)
        } catch {
            staleKeysTracker.addKey(id: item.uniqueKeyId)
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
                throw Failure.failedToMigrateKeyToBytes(error)
            }
        } else {
            // If there is no key,
            // then this is a fresh install and we do not need to perform migration.
            coreCryptoKeyMigrationManager.markMigrationToBytesAsSkipped()
        }
    }

    private func fetchCoreCryptoKey(scoped: Bool) throws -> Data? {
        do {
            let item = CoreCryptoKeychainItem(
                uniqueKeyId: uniqueKeyId,
                userID: userID,
                scoped: scoped
            )
            return try KeychainManager.fetchItem(item)
        } catch KeychainManager.Error.failedToFetchItemFromKeychain(errSecItemNotFound) {
            return nil
        }
    }

    private func createCoreCryptoKey() throws -> Data {
        let item = CoreCryptoKeychainItem(uniqueKeyId: uniqueKeyId, userID: userID)
        let key = try KeychainManager.generateKey(numberOfBytes: 32)
        try KeychainManager.storeItem(item, value: key)
        return key
    }

}

public extension CoreCryptoKeyProvider {

    enum Failure: LocalizedError {
        case keyNotFound
        case failedToScopeKey(Error)
        case failedToRotateKey(Error)
        case failedToMigrateKeyToBytes(Error)

        var errorDecscription: String {
            switch self {
            case .keyNotFound:
                "key not found"
            case let .failedToScopeKey(error):
                "failed to scope key (\(String(describing: error)))"
            case let .failedToRotateKey(error):
                "failed to rotate key (\(String(describing: error))"
            case let .failedToMigrateKeyToBytes(error):
                "failed to migrate key to bytes (\(String(describing: error)))"
            }
        }
    }
}

struct CoreCryptoKeychainItem: KeychainItemProtocol {

    /// deprecated key
    static let unscopedId = "com.wire.mls.key"

    static let scopedBaseId = "com.wire.cc.key"

    let uniqueKeyId: UUID
    let userID: UUID
    var scoped: Bool = true

    var id: String {
        if scoped {
            "\(Self.scopedBaseId).\(userID.uuidString).\(uniqueKeyId.uuidString)"
        } else {
            Self.unscopedId
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
