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

/// Process conversation receipt mode update events.

protocol ConversationReceiptModeUpdateEventProcessorProtocol {

    /// Process a conversation receipt mode update event.
    ///
    /// - Parameter event: A conversation receipt mode update event.

    func processEvent(_ event: ConversationReceiptModeUpdateEvent) async throws

}

struct ConversationReceiptModeUpdateEventProcessor: ConversationReceiptModeUpdateEventProcessorProtocol {
    
    let userRepository: any UserRepositoryProtocol
    let conversationRepository: any ConversationRepositoryProtocol
    let conversationLocalStore: any ConversationLocalStoreProtocol

    func processEvent(_ event: ConversationReceiptModeUpdateEvent) async throws {
        let senderID = event.senderID
        let conversationID = event.conversationID
        let isEnabled = event.newRecieptMode == 1
        
        let sender = try await userRepository.fetchUser(
            with: senderID.uuid,
            domain: senderID.domain
        )
        
        let conversation = await conversationRepository.fetchConversation(
            with: conversationID.uuid,
            domain: conversationID.domain
        )
        
        guard let conversation else {
            return WireLogger.eventProcessing.error(
                "Converation receipt mode update missing conversation, aborting..."
            )
        }
        
        await conversationLocalStore.storeConversationHasReadReceiptsEnabled(
            isEnabled,
            for: conversation
        )
        
        let systemMessage = SystemMessage(
            type: isEnabled ? .readReceiptsEnabled : .readReceiptsDisabled,
            sender: sender,
            timestamp: .now
        )
        
        await conversationRepository.addSystemMessage(
            systemMessage,
            to: conversation
        )
        
        let isConversationArchived = await conversationLocalStore.isConversationArchived(conversation)
        let mutedMessageTypes = await conversationLocalStore.conversationMutedMessageTypes(conversation)
        
        if isConversationArchived && mutedMessageTypes == .none {
            await conversationLocalStore.storeConversationIsArchived(
                false,
                for: conversation
            )
        }

    }

}
