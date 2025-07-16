//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import WireLogging
import WireNetwork
import WireSystem

struct ConversationReceiptModeUpdateEventProcessor: ConversationReceiptModeUpdateEventProcessorProtocol {

    let userRepository: any UserRepositoryProtocol
    let conversationRepository: any ConversationRepositoryProtocol
    let conversationLocalStore: any ConversationLocalStoreProtocol
    let messageRepository: any MessageRepositoryProtocol

    func processEvent(_ event: ConversationReceiptModeUpdateEvent) async throws {
        let senderID = event.senderID
        let conversationID = event.conversationID
        let isEnabled = event.newReceiptMode == 1

        let sender = try await userRepository.fetchUser(
            id: senderID.id,
            domain: senderID.domain
        )

        let conversation = await conversationRepository.fetchConversation(
            id: conversationID.id,
            domain: conversationID.domain
        )

        guard let conversation else {
            return WireLogger.eventProcessing.error(
                "Converation receipt mode update missing conversation, aborting..."
            )
        }

        await conversationLocalStore.storeConversation(
            hasReadReceiptsEnabled: isEnabled,
            for: conversation
        )

        _ = SystemMessage(
            type: isEnabled ? .readReceiptsEnabled : .readReceiptsDisabled,
            sender: sender,
            timestamp: .now
        )

        let systemMessageType: SystemMessageType = .readReceiptsStatus(
            isEnabled: isEnabled,
            sender: (senderID.id, senderID.domain),
            date: .now
        )

        await messageRepository.addSystemMessage(
            messageType: systemMessageType,
            conversationID: conversationID.id,
            conversationDomain: conversationID.domain
        )
    }

}
