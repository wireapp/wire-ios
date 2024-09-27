//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
import WireCryptobox

extension Sequence where Element: NSManagedObject {
    /// Perform changes on a sequence of NSManagedObjects and save at a regular interval and fault
    /// objects in order to keep memory consumption low.
    ///
    /// - Parameters:
    ///   - saveInterval: Number of changes we are performed before the context is saved
    ///   - block: Change which should be performed on the objects
    func modifyAndSaveInBatches(saveInterval: Int = 10000, _ block: (Element) throws -> Void) throws {
        var processed: [Element] = []

        for element in self {
            try autoreleasepool {
                try block(element)

                processed.append(element)

                if processed.count > saveInterval {
                    let context = element.managedObjectContext

                    try context?.save()
                    for item in processed {
                        context?.refresh(item, mergeChanges: false)
                    }
                    processed = []
                }
            }
        }

        try processed.last?.managedObjectContext?.save()
    }
}

extension NSManagedObjectContext {
    public var isLocked: Bool {
        guard encryptMessagesAtRest else {
            return false
        }
        return databaseKey == nil
    }

    // MARK: - Migration

    enum MigrationError: LocalizedError {
        case missingDatabaseKey
        case failedToMigrateInstances(type: ZMManagedObject.Type, reason: String)

        // MARK: Internal

        var errorDescription: String? {
            switch self {
            case .missingDatabaseKey:
                "A database key is required to migrate."
            case let .failedToMigrateInstances(type, reason):
                "Failed to migrate all instances of \(type). Reason: \(reason)"
            }
        }
    }

    public func migrateTowardEncryptionAtRest(databaseKey: VolatileData) throws {
        do {
            WireLogger.ear.info("migrating existing data toward EAR")
            saveOrRollback()
            try migrateInstancesTowardEncryptionAtRest(
                type: ZMGenericMessageData.self,
                key: databaseKey
            )
            try migrateInstancesTowardEncryptionAtRest(
                type: ZMClientMessage.self,
                key: databaseKey
            )
            try migrateInstancesTowardEncryptionAtRest(
                type: ZMConversation.self,
                key: databaseKey
            )
            saveOrRollback()
        } catch {
            WireLogger.ear.error("failed to migrate existing data toward EAR: \(error)")
            reset()
            throw error
        }
    }

    public func migrateAwayFromEncryptionAtRest(databaseKey: VolatileData) throws {
        do {
            WireLogger.ear.info("migrating existing data away from EAR")
            saveOrRollback()
            try migrateInstancesAwayFromEncryptionAtRest(
                type: ZMGenericMessageData.self,
                key: databaseKey
            )
            try migrateInstancesAwayFromEncryptionAtRest(
                type: ZMClientMessage.self,
                key: databaseKey
            )
            try migrateInstancesAwayFromEncryptionAtRest(
                type: ZMConversation.self,
                key: databaseKey
            )
            saveOrRollback()
        } catch {
            WireLogger.ear.error("failed to migrate existing data away from EAR: \(error)")
            reset()
            throw error
        }
    }

    private func migrateInstancesTowardEncryptionAtRest(
        type: (some MigratableEntity).Type,
        key: VolatileData
    ) throws {
        do {
            try fetchObjects(type: type).modifyAndSaveInBatches { instance in
                try instance.migrateTowardEncryptionAtRest(
                    in: self,
                    key: key
                )
            }
        } catch {
            throw MigrationError.failedToMigrateInstances(type: type, reason: error.localizedDescription)
        }
    }

    private func migrateInstancesAwayFromEncryptionAtRest(
        type: (some MigratableEntity).Type,
        key: VolatileData
    ) throws {
        do {
            try fetchObjects(type: type).modifyAndSaveInBatches { instance in
                try instance.migrateAwayFromEncryptionAtRest(
                    in: self,
                    key: key
                )
            }
        } catch {
            throw MigrationError.failedToMigrateInstances(type: type, reason: error.localizedDescription)
        }
    }

    private func fetchObjects<T: MigratableEntity>(type: T.Type) throws -> [T] {
        let request = fetchRequest(forType: type, batchSize: 100)
        return try fetch(request)
    }

    private func fetchRequest<T>(forType type: T.Type, batchSize: Int) -> NSFetchRequest<T>
        where T: MigratableEntity {
        let fetchRequest = NSFetchRequest<T>(entityName: T.entityName())
        fetchRequest.predicate = type.predicateForObjectsNeedingMigration
        fetchRequest.returnsObjectsAsFaults = false
        fetchRequest.fetchBatchSize = batchSize
        return fetchRequest
    }

    /// Whether the encryption at rest feature is enabled.

    public internal(set) var encryptMessagesAtRest: Bool {
        get {
            guard let value = persistentStoreMetadata(
                forKey: PersistentMetadataKey.encryptMessagesAtRest
                    .rawValue
            ) as? NSNumber else {
                return false
            }

            return value.boolValue
        }

        set {
            setPersistentStoreMetadata(
                NSNumber(value: newValue),
                key: PersistentMetadataKey.encryptMessagesAtRest.rawValue
            )
        }
    }

    // MARK: - Encryption / Decryption

    enum EncryptionError: LocalizedError {
        case missingDatabaseKey
        case missingContextData
        case cryptobox(error: ChaCha20Poly1305.AEADEncryption.EncryptionError)

        // MARK: Internal

        var errorDescription: String? {
            switch self {
            case .missingDatabaseKey:
                "Database key not found. Perhaps the database is locked."

            case .missingContextData:
                "Couldn't obtain context data."

            case let .cryptobox(error):
                error.errorDescription
            }
        }
    }

    func encryptData(data: Data) throws -> (data: Data, nonce: Data) {
        guard let key = databaseKey else {
            throw EncryptionError.missingDatabaseKey
        }

        return try encryptData(
            data: data,
            key: key
        )
    }

    func encryptData(
        data: Data,
        key: VolatileData
    ) throws -> (data: Data, nonce: Data) {
        guard let context = contextData() else {
            throw EncryptionError.missingContextData
        }

        do {
            let (ciphertext, nonce) = try ChaCha20Poly1305.AEADEncryption.encrypt(
                message: data,
                context: context,
                key: key._storage
            )
            return (ciphertext, nonce)
        } catch let error as ChaCha20Poly1305.AEADEncryption.EncryptionError {
            throw EncryptionError.cryptobox(error: error)
        }
    }

    func decryptData(
        data: Data,
        nonce: Data
    ) throws -> Data {
        guard let key = databaseKey else {
            throw EncryptionError.missingDatabaseKey
        }

        return try decryptData(
            data: data,
            nonce: nonce,
            key: key
        )
    }

    func decryptData(
        data: Data,
        nonce: Data,
        key: VolatileData
    ) throws -> Data {
        guard let context = contextData() else {
            throw EncryptionError.missingContextData
        }

        do {
            return try ChaCha20Poly1305.AEADEncryption.decrypt(
                ciphertext: data,
                nonce: nonce,
                context: context,
                key: key._storage
            )
        } catch let error as ChaCha20Poly1305.AEADEncryption.EncryptionError {
            throw EncryptionError.cryptobox(error: error)
        }
    }

    private func contextData() -> Data? {
        let selfUser = ZMUser.selfUser(in: self)

        guard
            let selfClient = selfUser.selfClient(),
            let selfUserId = selfUser.remoteIdentifier?.transportString(),
            let selfClientId = selfClient.remoteIdentifier,
            let context = (selfUserId + selfClientId).data(using: .utf8)
        else {
            WireLogger.ear.error("Could not obtain self user id and self client id")
            assertionFailure("Could not obtain self user id and self client id")
            return nil
        }

        return context
    }

    // MARK: - Database Key

    private static let databaseKeyUserInfoKey = "databaseKey"

    /// The database key used to protect contents of the database.

    public var databaseKey: VolatileData? {
        get {
            userInfo[Self.databaseKeyUserInfoKey] as? VolatileData
        }
        set {
            userInfo[Self.databaseKeyUserInfoKey] = newValue
        }
    }
}

// MARK: - Migratable

private typealias MigratableEntity = EncryptionAtRestMigratable & ZMManagedObject

// MARK: - EncryptionAtRestMigratable

/// A type that needs to be migrated when encryption at rest is enabled / disabled.

protocol EncryptionAtRestMigratable {
    /// The predicate to use to fetch specific instances for migration.

    static var predicateForObjectsNeedingMigration: NSPredicate? { get }

    /// Migrate necessary data to adhere to encryption at rest feature.
    ///
    /// For example, encrypt sensitve data and set a nonce.

    func migrateTowardEncryptionAtRest(
        in context: NSManagedObjectContext,
        key: VolatileData
    ) throws

    /// Migrate necessary data to make it available under normal circumstances.
    ///
    /// For example, decrypt sensitive data and clear the nonce.

    func migrateAwayFromEncryptionAtRest(
        in context: NSManagedObjectContext,
        key: VolatileData
    ) throws
}
