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

        guard
            dInstance.entity.name == ZMUser.entityName(),
            let sInstance = manager.sourceInstances(
                forEntityMappingName: mapping.name,
                destinationInstances: [dInstance]
            ).first,
            let (conversationID, domain) = conversationID(forSourceUser: sInstance),
            let dConversation = ZMConversation.fetch(
                with: conversationID,
                domain: domain,
                in: manager.destinationContext
            )
        else {
            return
        }

        dInstance.setValue(dConversation, forKey: "oneOnOneConversation")
    }

    private func conversationID(forSourceUser user: NSManagedObject) -> (UUID, String?)? {
        guard
            let connection = user.value(forKey: "connection") as? NSManagedObject,
            let conversation = connection.value(forKey: "conversation") as? NSManagedObject,
            let idData = conversation.value(forKey: "remoteIdentifier_data") as? Data,
            let conversationID = UUID(data: idData),
            let domain = conversation.value(forKey: "domain") as? String
        else {
            return nil
        }

        return (conversationID, domain)
    }

}
