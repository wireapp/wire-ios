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

// sourcery: AutoMockable
public protocol EARMigratorProtocol {

    func migrateTowardEncryptionAtRest(
        context: NSManagedObjectContext
    ) throws

    func migrateAwayFromEncryptionAtRest(
        context: NSManagedObjectContext
    ) throws

}

private typealias MigratableEntity = EncryptionAtRestMigratable & ZMManagedObject

public class EARMigrator: EARMigratorProtocol {

    enum MigrationError: LocalizedError {

        case failedToMigrateInstances(type: ZMManagedObject.Type, reason: String)

        var errorDescription: String? {
            switch self {
            case let .failedToMigrateInstances(type, reason):
                "Failed to migrate all instances of \(type). Reason: \(reason)"
            }
        }

    }

    private let messageEncryptionService: EARMessageEncryptionServiceProtocol

    public init(messageEncryptionService: EARMessageEncryptionServiceProtocol) {
        self.messageEncryptionService = messageEncryptionService
    }

    public func migrateTowardEncryptionAtRest(context: NSManagedObjectContext) throws {
        do {
            WireLogger.ear.info("migrating existing data toward EAR")

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
            WireLogger.ear.error("failed to migrate existing data toward EAR: \(error)")
            context.reset()
            throw error
        }
    }

    public func migrateAwayFromEncryptionAtRest(context: NSManagedObjectContext) throws {
        do {
            WireLogger.ear.info("migrating existing data away from EAR")

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
            WireLogger.ear.error("failed to migrate existing data away from EAR: \(error)")
            context.reset()
            throw error
        }
    }

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
