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

import WireLogging

/// Protocol for migrating database entities to/from encrypted storage.
///
/// The migrator handles the process of encrypting or decrypting sensitive data in the database
/// when Encryption at Rest (EAR) is enabled or disabled.
///
/// sourcery: AutoMockable
public protocol EARMigratorProtocol {

    /// Migrates existing unencrypted data to encrypted form.
    ///
    /// This method:
    /// 1. Fetches all entities that need encryption
    /// 2. Encrypts sensitive fields using the message encryption service
    /// 3. Saves changes in batches to avoid memory pressure
    /// 4. Rolls back all changes if any error occurs
    ///
    /// **Entities migrated:**
    /// - `ZMGenericMessageData` - Protobuf message data
    /// - `ZMClientMessage` - Message content
    /// - `ZMConversation` - Conversation properties (e.g., legal hold request)
    ///
    /// - Parameter context: The managed object context in which to perform the migration
    /// - Throws: `MigrationError.failedToMigrateInstances` if migration fails for any entity type
    func migrateTowardEncryptionAtRest(
        context: NSManagedObjectContext
    ) throws

    /// Migrates existing encrypted data back to unencrypted form.
    ///
    /// This method:
    /// 1. Fetches all entities that are currently encrypted
    /// 2. Decrypts sensitive fields using the message encryption service
    /// 3. Saves changes in batches to avoid memory pressure
    /// 4. Rolls back all changes if any error occurs
    ///
    /// **Entities migrated:**
    /// - `ZMGenericMessageData` - Protobuf message data
    /// - `ZMClientMessage` - Message content
    /// - `ZMConversation` - Conversation properties (e.g., legal hold request)
    ///
    /// - Parameter context: The managed object context in which to perform the migration
    /// - Throws: `MigrationError.failedToMigrateInstances` if migration fails for any entity type
    func migrateAwayFromEncryptionAtRest(
        context: NSManagedObjectContext
    ) throws

}

private typealias MigratableEntity = EncryptionAtRestMigratable & ZMManagedObject

public class EARMigrator: EARMigratorProtocol {

    // MARK: - Types
    
    enum MigrationError: LocalizedError {

        case failedToMigrateInstances(type: ZMManagedObject.Type, reason: String)

        var errorDescription: String? {
            switch self {
            case let .failedToMigrateInstances(type, reason):
                "Failed to migrate all instances of \(type). Reason: \(reason)"
            }
        }

    }

    // MARK: - Properties
    
    private let messageEncryptionService: EARMessageEncryptionServiceProtocol

    // MARK: - Init
    
    public init(messageEncryptionService: EARMessageEncryptionServiceProtocol) {
        self.messageEncryptionService = messageEncryptionService
    }

    // MARK: - Public Interface
    
    public func migrateTowardEncryptionAtRest(context: NSManagedObjectContext) throws {
        do {
            WireLogger.ear.info("migrating existing data toward EAR", attributes: .safePublic)

            let contextData = try context.earContextData()

            context.saveOrRollback()
            try migrateInstancesTowardEncryptionAtRest(
                type: ZMGenericMessageData.self,
                contextData: contextData,
                context: context
            )
            try migrateInstancesTowardEncryptionAtRest(
                type: ZMClientMessage.self,
                contextData: contextData,
                context: context
            )
            try migrateInstancesTowardEncryptionAtRest(
                type: ZMConversation.self,
                contextData: contextData,
                context: context
            )
            context.saveOrRollback()
        } catch {
            WireLogger.ear.error("failed to migrate existing data toward EAR: \(error)", attributes: .safePublic)
            context.reset()
            throw error
        }
    }

    public func migrateAwayFromEncryptionAtRest(context: NSManagedObjectContext) throws {
        do {
            WireLogger.ear.info("migrating existing data away from EAR", attributes: .safePublic)

            let contextData = try context.earContextData()

            context.saveOrRollback()
            try migrateInstancesAwayFromEncryptionAtRest(
                type: ZMGenericMessageData.self,
                contextData: contextData,
                context: context
            )
            try migrateInstancesAwayFromEncryptionAtRest(
                type: ZMClientMessage.self,
                contextData: contextData,
                context: context
            )
            try migrateInstancesAwayFromEncryptionAtRest(
                type: ZMConversation.self,
                contextData: contextData,
                context: context
            )
            context.saveOrRollback()
        } catch {
            WireLogger.ear.error("failed to migrate existing data away from EAR: \(error)", attributes: .safePublic)
            context.reset()
            throw error
        }
    }
    
    // MARK: - Private Methods

    private func migrateInstancesTowardEncryptionAtRest(
        type: (some MigratableEntity).Type,
        contextData: Data,
        context: NSManagedObjectContext
    ) throws {
        do {
            try fetchObjects(type: type, context: context).modifyAndSaveInBatches { instance in
                try instance.migrateTowardEncryptionAtRest(
                    contextData: contextData,
                    messageEncryptionService: messageEncryptionService
                )
            }
        } catch {
            throw MigrationError.failedToMigrateInstances(type: type, reason: error.localizedDescription)
        }
    }

    private func migrateInstancesAwayFromEncryptionAtRest(
        type: (some MigratableEntity).Type,
        contextData: Data,
        context: NSManagedObjectContext
    ) throws {
        do {
            try fetchObjects(type: type, context: context).modifyAndSaveInBatches { instance in
                try instance.migrateAwayFromEncryptionAtRest(
                    contextData: contextData,
                    messageEncryptionService: messageEncryptionService
                )
            }
        } catch {
            throw MigrationError.failedToMigrateInstances(type: type, reason: error.localizedDescription)
        }
    }

    private func fetchObjects<T: MigratableEntity>(
        type: T.Type,
        context: NSManagedObjectContext
    ) throws -> [T] {
        let request = fetchRequest(forType: type, batchSize: 100)
        return try context.fetch(request)
    }

    private func fetchRequest<T>(
        forType type: T.Type,
        batchSize: Int
    ) -> NSFetchRequest<T> where T: MigratableEntity {
        let fetchRequest = NSFetchRequest<T>(entityName: T.entityName())
        fetchRequest.predicate = type.predicateForObjectsNeedingMigration
        fetchRequest.returnsObjectsAsFaults = false
        fetchRequest.fetchBatchSize = batchSize
        return fetchRequest
    }

}
