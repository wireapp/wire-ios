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

/// Process conversation proteus message add events.

protocol ConversationProteusMessageAddEventProcessorProtocol {

    /// Process a conversation proteus message add event.
    ///
    /// - Parameter event: A conversation proteus message add event.

    func processEvent(_ event: ConversationProteusMessageAddEvent) async throws

}

struct ConversationProteusMessageAddEventProcessor: ConversationProteusMessageAddEventProcessorProtocol {
    
    let messageRepository: any MessageRepositoryProtocol

    func processEvent(_ event: ConversationProteusMessageAddEvent) async throws {
        let senderID = event.senderID
        let conversationID = event.conversationID
        let messageContent = event.message
        let messageExternalData = event.externalData
        let messageSenderClientID = event.messageSenderClientID
        let messageRecipientClientID = event.messageRecipientClientID
        let timestamp = event.timestamp
        

        // Message should be decrypted see `ProteusEventDecryptor`
        guard let decryptedMessage = messageContent.decryptedMessage else {
            return
        }
        
        let messageType: MessageType = .proteus(
            message: decryptedMessage,
            externalData: messageExternalData?.encryptedMessage,
            conversationID: conversationID.uuid,
            conversationDomain: conversationID.domain,
            senderID: senderID.uuid,
            senderDomain: senderID.domain,
            senderClientID: messageSenderClientID,
            recipientClientID: messageRecipientClientID,
            date: timestamp
        )
    }

}
