//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import WireDataModel
import WireNetwork
import WireSystem

struct ConversationMemberJoinEventProcessor: ConversationMemberJoinEventProcessorProtocol {

    let conversationRepository: any ConversationRepositoryProtocol
    let conversationLocalStore: any ConversationLocalStoreProtocol
    let userRepository: any UserRepositoryProtocol

    func processEvent(_ event: ConversationMemberJoinEvent) async throws {
        let conversationID = event.conversationID
        let senderID = event.senderID

        let newParticipants = event.members.compactMap {
            getParticipantInfo(from: $0)
        }

        try await conversationRepository.addParticipants(
            newParticipants,
            sender: (senderID.id, senderID.domain),
            date: event.timestamp,
            conversationID: conversationID.id,
            conversationDomain: conversationID.domain
        )
    }

    private func getParticipantInfo(
        from member: WireNetwork.Conversation.Member
    ) -> (id: UUID, domain: String?, role: String?)? {
        guard let userID = member.id ?? member.qualifiedID?.id else {
            return nil
        }

        return (userID, member.qualifiedID?.domain, member.conversationRole)
    }

}
