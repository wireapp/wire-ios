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

// Up until model version 2.112, a user was related to their one on one
// conversation via the `connection` relationship, ie `user.connection.conversation`
// and inversely `conversation.connection.to`.

class OneOnOneConversationMigrationPolicy: NSEntityMigrationPolicy {

    override func createRelationships(
        forDestination dInstance: NSManagedObject,
        in mapping: NSEntityMapping,
        manager: NSMigrationManager
    ) throws {
        try super.createRelationships(
            forDestination: dInstance,
            in: mapping,
            manager: manager
        )

        guard dInstance.entity.name == ZMUser.entityName() else {
            return
        }

        guard let sourceUser = manager.sourceInstances(
            forEntityMappingName: mapping.name,
            destinationInstances: [dInstance]
        ).first else {
            return
        }

        if let connection = sourceUser.value(forKey: "connection") as? NSManagedObject {
            print("migrating connection conversation")

            guard
                let sourceConversation = connection.value(forKey: "conversation") as? NSManagedObject,
                let destinationConversation = manager.destinationInstances(
                    forEntityMappingName: "ConversationToConversation",
                    sourceInstances: [sourceConversation]
                ).first
            else {
                return
            }

            dInstance.setValue(destinationConversation, forKey: "oneOnOneConversation")

        } else {
            let sessionRequest = NSFetchRequest<NSManagedObject>()
            sessionRequest.entity = manager.sourceModel.entitiesByName[ZMSession.entityName()]
            let result = try? manager.sourceContext.fetch(sessionRequest)

            guard
                let session = result?.first,
                let selfUser = session.value(forKey: "selfUser") as? NSManagedObject,
                let membership = selfUser.value(forKey: "membership") as? NSManagedObject,
                let selfTeam = membership.value(forKey: "team") as? NSManagedObject
            else {
                return
            }

            guard selfUser != sourceUser else {
                return
            }

            // trying to migrate team one on one
            let request = NSFetchRequest<NSManagedObject>()
            request.entity = manager.sourceModel.entitiesByName[ZMConversation.entityName()]

            let sameTeam = NSPredicate(format: "team == %@", selfTeam)
            let groupConversation = NSPredicate(format: "%K == %d", ZMConversationConversationTypeKey, ZMConversationType.group.rawValue)
            let noUserDefinedName = NSPredicate(format: "%K == NULL", ZMConversationUserDefinedNameKey)
            let sameParticipant = NSPredicate(
                format: "%K.@count == 2 AND ANY %K.user == %@ AND ANY %K.user == %@",
                ZMConversationParticipantRolesKey,
                ZMConversationParticipantRolesKey,
                sourceUser,
                ZMConversationParticipantRolesKey,
                selfUser
            )

            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                sameTeam,
                groupConversation,
                noUserDefinedName,
                sameParticipant
            ])

            guard
                let sourceConversations = try? manager.sourceContext.fetch(request),
                let sourceConversation = sourceConversations.first,
                let destinationConversation = manager.destinationInstances(
                    forEntityMappingName: "ConversationToConversation",
                    sourceInstances: [sourceConversation]
                ).first
            else {
                return
            }

            dInstance.setValue(destinationConversation, forKey: "oneOnOneConversation")
        }
    }

}
