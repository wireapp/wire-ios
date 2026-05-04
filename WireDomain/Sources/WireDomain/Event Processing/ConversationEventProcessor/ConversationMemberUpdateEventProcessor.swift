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

import WireNetwork
import WireSystem

struct ConversationMemberUpdateEventProcessor: ConversationMemberUpdateEventProcessorProtocol {

    let conversationRepository: any ConversationRepositoryProtocol
    let userRepository: any UserRepositoryProtocol
    let localStore: any ConversationLocalStoreProtocol

    func processEvent(_ event: ConversationMemberUpdateEvent) async throws {
        let conversationID = event.conversationID
        let memberChange = event.memberChange
        let memberChangeID = memberChange.id
        let muteStatus = memberChange.newMuteStatus
        let muteStatusDate = memberChange.muteStatusReferenceDate
        let archivedStatus = memberChange.newArchivedStatus
        let archivedStatusDate = memberChange.archivedStatusReferenceDate

        let conversation = await conversationRepository.fetchOrCreateConversation(
            id: conversationID.id,
            domain: conversationID.domain
        )

        let isSelfUser = try await userRepository.isSelfUser(
            id: memberChangeID.id,
            domain: memberChangeID.domain
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

        await conversationRepository.addOrUpdateParticipant(
            participantID: memberChangeID.id,
            participantDomain: memberChangeID.domain,
            participantRole: role,
            conversationID: conversationID.id,
            conversationDomain: conversationID.domain
        )
    }

}
