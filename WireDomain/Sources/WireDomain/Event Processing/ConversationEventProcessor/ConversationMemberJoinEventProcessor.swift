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
import WireDataModel
import WireSystem

/// Process conversation member join events.

protocol ConversationMemberJoinEventProcessorProtocol {

    /// Process a conversation member join event.
    ///
    /// - Parameter event: A conversation member join event.

    func processEvent(_ event: ConversationMemberJoinEvent) async throws

}

struct ConversationMemberJoinEventProcessor: ConversationMemberJoinEventProcessorProtocol {

    let context: NSManagedObjectContext
    let conversationRepository: any ConversationRepositoryProtocol
    let userRepository: any UserRepositoryProtocol

    func processEvent(_ event: ConversationMemberJoinEvent) async throws {
        let conversationID = event.conversationID
        let id = conversationID.uuid
        let domain = conversationID.domain

        var conversation = await conversationRepository.fetchConversation(
            with: id,
            domain: domain
        )

        if conversation == nil {
            // Sync conversation
            try await conversationRepository.pullConversation(with: conversationID)
            conversation = await conversationRepository.fetchConversation(
                with: id,
                domain: domain
            )
        }

        guard let conversation else {
            return WireLogger.eventProcessing.error(
                "Member join update missing conversation, aborting..."
            )
        }

        try await addParticipants(
            event.members,
            to: conversation,
            senderID: event.senderID,
            timestamp: event.timestamp
        )
    }

    private func addParticipants(
        _ members: [WireAPI.Conversation.Member],
        to conversation: ZMConversation,
        senderID: UserID,
        timestamp: Date
    ) async throws {
        let usersAndRoles = members.compactMap {
            fetchUserAndRole(from: $0, for: conversation)
        }

        let users = Set(usersAndRoles.map(\.user))
        let existingUsers = await context.perform {
            conversation.localParticipants
        }

        let newUsers = users.subtracting(existingUsers)

        if !newUsers.isEmpty, conversation.conversationType == .group {
            let sender = try await userRepository.fetchUser(
                with: senderID.uuid,
                domain: senderID.domain
            )

            let systemMessage = SystemMessage(
                type: .participantsAdded,
                sender: sender,
                users: newUsers,
                clients: nil,
                timestamp: timestamp
            )

            await conversationRepository.addSystemMessage(systemMessage, to: conversation)
        }

        conversation.addParticipantsAndUpdateConversationState(
            usersAndRoles: usersAndRoles
        )
    }

    private func fetchUserAndRole(
        from member: WireAPI.Conversation.Member,
        for conversation: ZMConversation
    ) -> (user: ZMUser, role: Role?)? {
        guard let userID = member.id ?? member.qualifiedID?.uuid else {
            return nil
        }

        let user = userRepository.fetchOrCreateUser(
            with: userID,
            domain: member.qualifiedID?.domain
        )

        let role = member.conversationRole.map {
            Role.fetchOrCreateRole(
                with: $0,
                teamOrConversation: TeamOrConversation.matching(conversation),
                in: context
            )
        }

        return (user, role)
    }

}
