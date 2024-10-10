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

// Up until model version 2.113, a user was related to their one on one
// conversation via the `connection` relationship, ie `user.connection.conversation`
// and inversely `conversation.connection.to`.
final class OneOnOneConversationMigrationAction: CoreDataMigrationAction {
    let batchSize = 200

    override func execute(in context: NSManagedObjectContext) throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: ZMUser.entityName())
        request.fetchBatchSize = batchSize
        let users = try context.fetch(request)

        for user in users {
            if let connection = user.value(forKey: "connection") as? NSManagedObject {
                migrateConnectionOneOnOne(user: user, connection: connection)
            } else {
                do {
                    try migrateTeamOneOnOne(user: user, context: context)
                } catch {
                    WireLogger.localStorage.error("failed to migrate non connected user: \(user)")
                }
            }
        }
    }

    private func migrateConnectionOneOnOne(user: NSManagedObject, connection: NSManagedObject) {
        guard
            let conversation = connection.value(forKey: "conversation") as? NSManagedObject
        else {
            return
        }

        user.setValue(conversation, forKey: "oneOnOneConversation")
    }

    private func migrateTeamOneOnOne(user: NSManagedObject, context: NSManagedObjectContext) throws {
        let sessionRequest = NSFetchRequest<NSManagedObject>(entityName: ZMSession.entityName())
        let result = try context.fetch(sessionRequest)

        guard
            let session = result.first,
            let selfUser = session.value(forKey: "selfUser") as? NSManagedObject,
            let membership = selfUser.value(forKey: "membership") as? NSManagedObject,
            let selfTeam = membership.value(forKey: "team") as? NSManagedObject
        else {
            // user is not a member of the self team there won't exist any one-on-one conversation
            return
        }

        guard selfUser != user else {
            return
        }

        // Look for an existing "fake" one on one team conversation,
        // a special group conversation pretending to be a one on one.
        let request = NSFetchRequest<NSManagedObject>(entityName: ZMConversation.entityName())

        // We consider a conversation being an existing 1:1 team conversation in case the following points are true:
        //  1. It is a conversation inside the team
        //  2. The only participants are the current user and the selected user
        //  3. It does not have a custom display name
        let sameTeam = NSPredicate(format: "team == %@", selfTeam)
        let groupConversation = NSPredicate(format: "%K == %d", ZMConversationConversationTypeKey, ZMConversationType.group.rawValue)
        let noUserDefinedName = NSPredicate(format: "%K == NULL", ZMConversationUserDefinedNameKey)
        let sameParticipant = NSPredicate(
            format: "%K.@count == 2 AND ANY %K.user == %@ AND ANY %K.user == %@",
            ZMConversationParticipantRolesKey,
            ZMConversationParticipantRolesKey,
            user,
            ZMConversationParticipantRolesKey,
            selfUser
        )

        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            sameTeam,
            groupConversation,
            noUserDefinedName,
            sameParticipant
        ])

        //  4. sort by their fully qualified conversation ID in ascending oder, and use the first one.
        // primary_key is basically the qualified id
        request.sortDescriptors = [NSSortDescriptor(key: "primaryKey", ascending: true)]

        guard
            let conversation = try context.fetch(request).first
        else {
            return
        }

        user.setValue(conversation, forKey: "oneOnOneConversation")
    }
}
