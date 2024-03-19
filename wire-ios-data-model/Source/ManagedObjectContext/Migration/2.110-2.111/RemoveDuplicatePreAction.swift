////
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

    private enum Keys: String {
        case needsToBeUpdatedFromBackend
        case primaryKey
    }

    let entityNames = [ZMUser.entityName(), ZMConversation.entityName(), Team.entityName()]

    override func execute(in context: NSManagedObjectContext) {
        entityNames.forEach { entityName in
            removeDuplicates(for: entityName, context: context)
        }
    }

    private func removeDuplicates(for entityName: String, context: NSManagedObjectContext) {
        print("🕵🏽", entityName)
        let duplicateObjects: [Data: [NSManagedObject]] = context.findDuplicated(
            entityName: entityName,
            by: ZMManagedObject.remoteIdentifierDataKey()
        )

        var duplicates = [String: [NSManagedObject]]()

        duplicateObjects.forEach { (_, objects: [NSManagedObject]) in
            objects.forEach { object in

                let uniqueKey = PrimaryKeyGenerator.generateKey(for: object, entityName: entityName)
                if duplicates[uniqueKey] == nil {
                    duplicates[uniqueKey] = []
                }
                duplicates[uniqueKey]?.append(object)
            }
        }

        WireLogger.localStorage.info("found \(duplicates.count) different duplicate(s) of \(entityName)")

        var needsSlowSync = false

        duplicates.forEach { (key, objects: [NSManagedObject]) in
            guard objects.count > 1 else {
                WireLogger.localStorage.info("skipping object with different domain if any: \(key)")
                return
            }
            WireLogger.localStorage.debug("processing \(key)")
            // for now we just keep one object and mark to sync and drop the rest.
            // Marking needsToBeUpdatedFromBackend will recover the data from backend
            objects.first?.setValue(true, forKey: Keys.needsToBeUpdatedFromBackend.rawValue)
            objects.dropFirst().forEach(context.delete)

            WireLogger.localStorage.warn("removed \(objects.count - 1) occurence of duplicate \(entityName) for key \(key)", attributes: .safePublic)

            if !needsSlowSync {
                needsSlowSync = true
            }
        }

        if needsSlowSync {
            markNeedsSlowSync(context: context,
                              forEntityName: entityName)
        }
    }

    private func markNeedsSlowSync(context: NSManagedObjectContext, forEntityName entityName: String) {
        do {
            try context.setMigrationNeedsSlowSync()
        } catch {
            WireLogger.localStorage.error("Failed to trigger slow sync on migration \(entityName): \(error.localizedDescription)", attributes: .safePublic)
        }
    }
}
