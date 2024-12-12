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
import WireDataModel
import WireSystem
import WireLogging

/// Process conversation mls message add events.

protocol ConversationMLSMessageAddEventProcessorProtocol {

    /// Process a conversation mls message add event.
    ///
    /// - Parameter event: A conversation mls message add event.

    func processEvent(_ event: ConversationMLSMessageAddEvent) async throws

}

struct ConversationMLSMessageAddEventProcessor: ConversationMLSMessageAddEventProcessorProtocol {
    
    enum Failure: Error {
        case mlsConversationNotFound
    }

    let conversationLocalStore: any ConversationLocalStoreProtocol
    let messageLocalStore: any MessageLocalStoreProtocol
    let userLocalStore: any UserLocalStoreProtocol
    let protobufMessageProcessor: any ConversationProtobufMessageProcessorProtocol

    func processEvent(_ event: ConversationMLSMessageAddEvent) async throws {
        let conversationID = event.conversationID
        let senderID = event.senderID
        let date = event.timestamp
        let decryptedMessages = event.decryptedMessages
        
        guard !decryptedMessages.isEmpty else {
            return WireLogger.proteus.warn(
                "failed to add MLS message: there are no decrypted messages to process"
            )
        }

        for decryptedMessage in decryptedMessages {
            try await processDecryptedMessage(
                decryptedMessage,
                conversationID: conversationID,
                senderID: senderID,
                date: date
            )
        }
    }

    private func processDecryptedMessage(
        _ decryptedMessage: ConversationMLSMessageAddEvent.DecryptedMessage,
        conversationID: ConversationID,
        senderID: UserID,
        date: Date?
    ) async throws {
        guard let conversation = await conversationLocalStore.fetchConversation(
            id: conversationID.uuid,
            domain: conversationID.domain
        ) else {
            throw Failure.mlsConversationNotFound
        }

        let logAttributes: LogAttributes = [
            .messageType: "conversation.mls-message-add",
            .conversationId: conversationID.uuid.safeForLoggingDescription
        ]

        // Ensure is self conversation, sender is self user and conversation is not read-only
        guard await messageLocalStore.canAddMessage(
            conversation: conversation,
            senderID: senderID.uuid
        ) else {
            return WireLogger.eventProcessing.warn(
                "Ignoring incoming message: illegal sender or conversation",
                attributes: logAttributes
            )
        }

        // Get protobuf message
        let protobufMessage = await getProtobufMessage(
            from: decryptedMessage.message
        )

        guard let (genericMessage, content) = protobufMessage else {
            WireLogger.eventProcessing.warn(
                "Can't read protobuf, abort processing",
                attributes: logAttributes
            )

            return await addInvalidSystemMessage(
                senderID: senderID,
                conversationID: conversationID,
                date: date ?? .now
            )
        }

        await conversationLocalStore.updateSecurityLevelAfterReceivingMessage(
            conversation: conversation,
            genericMessage: genericMessage,
            date: date ?? .now
        )

        // Verifies that a sender of an update event is part of the conversation. If they are not,
        // it means that our local state is out of sync and we need to update the list of participants.
        await conversationLocalStore.addParticipantIfNeeded(
            participantID: senderID.uuid,
            participantDomain: senderID.domain,
            in: conversation,
            date: date?.addingTimeInterval(-0.01) ?? .now
        )

        // Process protobuf message
        try await protobufMessageProcessor.processProtobufMessage(
            genericMessage,
            content: content,
            conversation: conversation,
            conversationID: conversationID,
            senderID: senderID,
            senderClientID: decryptedMessage.senderClientID,
            date: date ?? .now,
            eventMessage: "conversation.mls-message-add"
        )
    }

    private func getProtobufMessage(
        from base64Message: String
    ) async -> (GenericMessage, GenericMessage.OneOf_Content)? {
        let genericMessage = GenericMessage(withBase64String: base64Message)

        guard let genericMessage, let content = genericMessage.content else {
            return nil
        }

        return (genericMessage, content)
    }

    private func addInvalidSystemMessage(
        senderID: UserID,
        conversationID: ConversationID,
        date: Date
    ) async {
        let systemMessageType: SystemMessageType = .invalid(
            sender: (senderID.uuid, senderID.domain),
            date: date
        )

        await messageLocalStore.addSystemMessage(
            messageType: systemMessageType,
            conversationID: conversationID.uuid,
            conversationDomain: conversationID.domain
        )
    }

}
