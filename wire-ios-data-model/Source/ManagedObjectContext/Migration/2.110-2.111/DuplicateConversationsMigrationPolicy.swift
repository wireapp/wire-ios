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

    private let zmLog = ZMSLog(tag: "core-data")

    override func begin(_ mapping: NSEntityMapping, with manager: NSMigrationManager) throws {
        zmLog.safePublic("beginning duplicate conversations migration", level: .info)
        WireLogger.localStorage.info("beginning duplicate conversations migration")

        let context = manager.sourceContext

        let duplicateObjects: [NSManagedObject] = context.findDuplicated(
            entityName: ZMConversation.entityName(),
            by: ZMConversation.remoteIdentifierDataKey()!,
            and: #keyPath(ZMConversation.domain)
        )

        let duplicates = duplicateObjects.map { object in
            guard
                let remoteIdentifierData = object.value(forKeyPath: ZMConversation.remoteIdentifierDataKey()!) as? Data,
                let remoteIdentifier = UUID(data: remoteIdentifierData),
                let domain = object.value(forKeyPath: #keyPath(ZMConversation.domain)) as? String else {
                return TupleKeyArray<String, NSManagedObject>?.none
            }
            return TupleKeyArray(key: "\(remoteIdentifier.uuidString)_\(domain)", value: [object])
        }.compactMap { $0 }.merge()

        zmLog.safePublic(SanitizedString(stringLiteral: "found (\(duplicates.count)) occurences of duplicate conversations"), level: .info)
        WireLogger.localStorage.info("found (\(duplicates.count)) occurences of duplicate conversations")

        duplicates.forEach { (_, conversations: [NSManagedObject]) in
            guard conversations.count > 1 else {
                return
            }

            // for now we just keep one conversation and mark to sync and drop the rest.
            // Marking needsToBeUpdatedFromBackend supposes we recover the data from backend
            conversations.first?.setValue(true, forKey: Keys.needsToBeUpdatedFromBackend.rawValue)
            conversations.dropFirst().forEach(context.delete)

            zmLog.safePublic("removed 1 occurence of duplicate conversations", level: .warn)
            WireLogger.localStorage.info("removed 1 occurence of duplicate conversations")
        }
    }

    // method to populate primaryKey called after beginMapping on all occurences of ZMUser
    @objc(primaryKey::)
    func primaryKey(_ remoteIdentifierData: Data?, domain: String?) -> String {
       return ZMConversation.primaryKey(from: remoteIdentifierData.flatMap(UUID.init(data: )), domain: domain)
    }

}
