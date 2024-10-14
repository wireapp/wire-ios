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

import CoreData
import WireAPI

/// Process conversation access update events.

protocol ConversationAccessUpdateEventProcessorProtocol {

    /// Process a conversation access update event.
    ///
    /// - Parameter event: A conversation access update event.

    func processEvent(_ event: ConversationAccessUpdateEvent) async

}

struct ConversationAccessUpdateEventProcessor: ConversationAccessUpdateEventProcessorProtocol {

    let context: NSManagedObjectContext
    let repository: any ConversationRepositoryProtocol

    func processEvent(_ event: ConversationAccessUpdateEvent) async {
        let conversationID = event.conversationID

        let localConversation = await repository.fetchOrCreateConversation(
            with: conversationID.uuid,
            domain: conversationID.domain
        )

        let accessRoles = if let legacyAccessRole = event.legacyAccessRole {
            getAccessRoles(from: legacyAccessRole)
        } else {
            event.accessRoles
        }

        await context.perform {
            localConversation.accessModeStrings = event.accessModes.map(\.rawValue)
            localConversation.accessRoleStringsV2 = accessRoles.map(\.rawValue)
        }
    }

    private func getAccessRoles(
        from legacyRole: ConversationAccessRoleLegacy
    ) -> Set<ConversationAccessRole> {
        switch legacyRole {
        case .team:
            [.teamMember]
        case .activated:
            [.teamMember, .nonTeamMember, .guest]
        case .nonActivated:
            [.teamMember, .nonTeamMember, .guest, .service]
        case .private:
            []
        }
    }

}
