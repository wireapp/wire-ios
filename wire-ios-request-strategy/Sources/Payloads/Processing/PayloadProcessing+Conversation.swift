// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
import WireDataModel

// MARK: - Conversation

extension Payload.ConversationMember {

    func fetchUserAndRole(in context: NSManagedObjectContext,
                          conversation: ZMConversation) -> (ZMUser, Role?)? {
        guard let userID = id ?? qualifiedID?.uuid else { return nil }
        return (ZMUser.fetchOrCreate(with: userID, domain: qualifiedID?.domain, in: context),
                conversationRole.map({conversation.fetchOrCreateRoleForConversation(name: $0) }))
    }

    // TODO: [John] Delete
    func updateStatus(for conversation: ZMConversation) {

        if let mutedStatus = mutedStatus,
           let mutedReference = mutedReference {
            conversation.updateMutedStatus(status: Int32(mutedStatus), referenceDate: mutedReference)
        }

        if let archived = archived,
           let archivedReference = archivedReference {
            conversation.updateArchivedStatus(archived: archived, referenceDate: archivedReference)
        }

    }

}

extension Payload.ConversationMembers {

    func fetchOtherMembers(in context: NSManagedObjectContext, conversation: ZMConversation) -> [(ZMUser, Role?)] {
        return others.compactMap({ $0.fetchUserAndRole(in: context, conversation: conversation) })
    }

}

private extension ZMConversation {

    func firstSystemMessage(for systemMessageType: ZMSystemMessageType) -> ZMSystemMessage? {

        return allMessages
            .compactMap { $0 as? ZMSystemMessage }
            .first(where: { $0.systemMessageType == systemMessageType })
    }
}

extension Payload.UpdateConversationMLSWelcome {

    func process(in context: NSManagedObjectContext, originalEvent: ZMUpdateEvent) {
        MLSEventProcessor.shared.process(
            welcomeMessage: data,
            in: context
        )
    }

}
