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

import WireAPI
import WireSystem

/// Process conversation member update events.

protocol ConversationMemberUpdateEventProcessorProtocol {

    /// Process a conversation member update event.
    ///
    /// - Parameter event: A conversation member update event.

    func processEvent(_ event: ConversationMemberUpdateEvent) async throws

}

struct ConversationMemberUpdateEventProcessor: ConversationMemberUpdateEventProcessorProtocol {

    let conversationRepository: any ConversationRepositoryProtocol
    let userRepository: any UserRepositoryProtocol
    let localStore: any ConversationLocalStoreProtocol

    func processEvent(_ event: ConversationMemberUpdateEvent) async throws {
        let senderID = event.senderID
        let conversationID = event.conversationID
        let memberChange = event.memberChange
        let muteStatus = memberChange.newMuteStatus
        let muteStatusDate = memberChange.muteStatusReferenceDate
        let archivedStatus = memberChange.newArchivedStatus
        let archivedStatusDate = memberChange.archivedStatusReferenceDate

        let conversation = await conversationRepository.fetchOrCreateConversation(
            with: conversationID.uuid,
            domain: conversationID.domain
        )

        let isSelfUser = try await userRepository.isSelfUser(
            id: senderID.uuid,
            domain: senderID.domain
        )

        if isSelfUser {
            await localStore.updateMemberStatus(
                mutedStatusInfo: (muteStatus, muteStatusDate),
                archivedStatusInfo: (archivedStatus, archivedStatusDate),
                for: conversation
            )
        }

        guard let role = event.memberChange.newRoleName else {
            return
        }

        await conversationRepository.addParticipantToConversation(
            conversationID: conversationID.uuid,
            conversationDomain: conversationID.domain,
            participantID: senderID.uuid,
            participantDomain: senderID.domain,
            participantRole: role
        )
    }

}
