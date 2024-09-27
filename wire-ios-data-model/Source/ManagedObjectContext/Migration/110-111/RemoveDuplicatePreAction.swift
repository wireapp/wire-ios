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

class RemoveDuplicatePreAction: CoreDataMigrationAction {
    // MARK: Internal

    let entityNames = [ZMUser.entityName(), ZMConversation.entityName(), Team.entityName()]

    override func execute(in context: NSManagedObjectContext) {
        for entityName in entityNames {
            removeNilPrimaryKey(for: entityName, context: context)
            removeDuplicates(for: entityName, context: context)
        }
    }

    // MARK: Private

    private enum Keys: String {
        case needsToBeUpdatedFromBackend
        case primaryKey
    }

    // Method to cleanup objects without remoteIdentifierDataKey before removeDuplicates
    private func removeNilPrimaryKey(for entityName: String, context: NSManagedObjectContext) {
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        request.predicate = NSPredicate(format: "%K = nil", ZMManagedObject.remoteIdentifierDataKey())
        do {
            let objectsWithNil = try context.fetch(request)

            for object in objectsWithNil {
                context.delete(object)
            }
            WireLogger.localStorage.info(
                "Deleted \(objectsWithNil.count) \(entityName) objects with no remoteIdentifierData",
                attributes: .safePublic
            )
        } catch {
            WireLogger.localStorage.error(
                "error fetching object \(entityName) with no remoteIdentifierData \(error.localizedDescription)",
                attributes: .safePublic
            )
        }
    }

    private func removeDuplicates(for entityName: String, context: NSManagedObjectContext) {
        let duplicateObjects: [Data: [NSManagedObject]] = context.findDuplicated(
            entityName: entityName,
            by: ZMManagedObject.remoteIdentifierDataKey()
        )

        var duplicates = [String: [NSManagedObject]]()

        for (_, objects) in duplicateObjects {
            for object in objects {
                let uniqueKey = PrimaryKeyGenerator.generateKey(for: object, entityName: entityName)
                if duplicates[uniqueKey] == nil {
                    duplicates[uniqueKey] = []
                }
                duplicates[uniqueKey]?.append(object)
            }
        }

        WireLogger.localStorage.info(
            "found \(duplicates.count) different duplicate(s) of \(entityName)",
            attributes: .safePublic
        )

        var needsSlowSync = false

        for (key, objects) in duplicates {
            guard objects.count > 1 else {
                WireLogger.localStorage.info(
                    "skipping object with different domain if any: \(key)",
                    attributes: .safePublic
                )
                continue
            }
            WireLogger.localStorage.debug("processing \(key)", attributes: .safePublic)
            // for now we just keep one object and mark to sync and drop the rest.
            // Marking needsToBeUpdatedFromBackend will recover the data from backend
            objects.first?.setValue(true, forKey: Keys.needsToBeUpdatedFromBackend.rawValue)
            objects.dropFirst().forEach(context.delete)

            WireLogger.localStorage.warn(
                "removed \(objects.count - 1) occurence of duplicate \(entityName) for key \(key)",
                attributes: .safePublic
            )

            if !needsSlowSync {
                needsSlowSync = true
            }
        }

        if needsSlowSync {
            markNeedsSlowSync(
                context: context,
                forEntityName: entityName
            )
        }
    }

    private func markNeedsSlowSync(context: NSManagedObjectContext, forEntityName entityName: String) {
        do {
            try context.setMigrationNeedsSlowSync()
        } catch {
            WireLogger.localStorage.error(
                "Failed to trigger slow sync on migration \(entityName): \(error.localizedDescription)",
                attributes: .safePublic
            )
        }
    }
}
