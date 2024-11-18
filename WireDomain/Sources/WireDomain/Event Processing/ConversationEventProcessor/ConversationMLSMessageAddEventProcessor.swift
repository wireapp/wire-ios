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

/// Process conversation mls message add events.

protocol ConversationMLSMessageAddEventProcessorProtocol {

    /// Process a conversation mls message add event.
    ///
    /// - Parameter event: A conversation mls message add event.

    func processEvent(_ event: ConversationMLSMessageAddEvent) async throws

}

struct ConversationMLSMessageAddEventProcessor: ConversationMLSMessageAddEventProcessorProtocol {
    
    let repository: any MessageRepositoryProtocol

    func processEvent(_ event: ConversationMLSMessageAddEvent) async throws {
        let message = event.message
        let conversationID = event.conversationID
        let senderID = event.senderID
        let subconversation = event.subconversation
        let date = event.timestamp
        
        let decryptedMessages = event.decryptedMessages.map {
            (message: $0.message, senderClientID: $0.senderClientID)
        }
        
        await repository.addMessage(
            .mls(decryptedMessages: decryptedMessages,
                 conversationID: conversationID.uuid,
                 conversationDomain: conversationID.domain,
                 senderID: senderID.uuid,
                 senderDomain: senderID.domain,
                 date: date)
        )
        
    }

}
