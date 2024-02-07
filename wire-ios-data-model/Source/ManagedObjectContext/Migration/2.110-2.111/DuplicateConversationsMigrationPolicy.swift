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
import WireSystem

class DuplicateConversationsMigrationPolicy: NSEntityMigrationPolicy {

    private enum Keys: String {
        case needsToBeUpdatedFromBackend
        case primaryKey
    }

    override func begin(_ mapping: NSEntityMapping, with manager: NSMigrationManager) throws {
        WireLogger.localStorage.info("beginning duplicate conversations migration", attributes: .safePublic)

        let context = manager.sourceContext

        let duplicateObjects: [Data: [NSManagedObject]] = context.findDuplicated(
            entityName: ZMConversation.entityName(),
            by: ZMConversation.remoteIdentifierDataKey()!
        )

        var duplicates = [String: [NSManagedObject]]()

        duplicateObjects.forEach { (remoteIdentifierData: Data, objects: [NSManagedObject]) in
            objects.forEach { object in
                let domain = object.value(forKeyPath: #keyPath(ZMConversation.domain)) as? String
                let uniqueKey = self.primaryKey(remoteIdentifierData, domain: domain)
                if duplicates[uniqueKey] == nil {
                    duplicates[uniqueKey] = []
                }
                duplicates[uniqueKey]?.append(object)
            }
        }

        WireLogger.localStorage.info("found (\(duplicates.count)) occurences of duplicate conversations", attributes: .safePublic)

        duplicates.forEach { (key, conversations: [NSManagedObject]) in
            guard conversations.count > 1 else {
                WireLogger.localStorage.info("skipping user with different domain: \(key)", attributes: .safePublic)
                return
            }
            WireLogger.localStorage.debug("processing \(key)", attributes: .safePublic)
            // for now we just keep one user and mark to sync and drop the rest.
            // Marking needsToBeUpdatedFromBackend supposes we recover the data from backend
            conversations.first?.setValue(true, forKey: Keys.needsToBeUpdatedFromBackend.rawValue)
            conversations.dropFirst().forEach(context.delete)

             WireLogger.localStorage.info("removed  \(conversations.count - 1) occurence of duplicate conversations", attributes: .safePublic)
        }
    }

    // method to populate primaryKey called after beginMapping on all occurences of ZMConversation
    @objc(primaryKey::)
    func primaryKey(_ remoteIdentifierData: Data?, domain: String?) -> String {
       return ZMConversation.primaryKey(from: remoteIdentifierData.flatMap(UUID.init(data: )), domain: domain)
    }

}
