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

import WireDataModel
import WireAPI

/// Process conversation proteus message add events.

protocol ConversationProteusMessageAddEventProcessorProtocol {

    /// Process a conversation proteus message add event.
    ///
    /// - Parameter event: A conversation proteus message add event.

    func processEvent(_ event: ConversationProteusMessageAddEvent) async throws

}

struct ConversationProteusMessageAddEventProcessor: ConversationProteusMessageAddEventProcessorProtocol {

    let conversationLocalStore: any ConversationLocalStoreProtocol
    let messageLocalStore: any MessageLocalStoreProtocol
    let userLocalStore: any UserLocalStoreProtocol
    let protobufMessageProcessor: any ConversationProtobufMessageProcessorProtocol

    func processEvent(_ event: ConversationProteusMessageAddEvent) async throws {
        let senderID = event.senderID
        let conversationID = event.conversationID
        let messageContent = event.message
        let messageExternalData = event.externalData
        let messageSenderClientID = event.messageSenderClientID
        let date = event.timestamp

        // Message should be decrypted see `ProteusEventDecryptor`
        guard let decryptedMessage = messageContent.decryptedMessage else {
            return
        }
        
        guard let conversation = await conversationLocalStore.fetchConversation(
            id: conversationID.uuid,
            domain: conversationID.domain
        ) else {
            return WireLogger.proteus.error(
                "failed to add proteus message: conversation not found in db"
            )
        }
        
        let logAttributes: LogAttributes = [
            .messageType: "conversation.otr-message-add",
            .conversationId: conversationID.uuid.safeForLoggingDescription
        ]
        
        // Ensure is self conversation, sender is self user and conversation is not read-only
        guard await messageLocalStore.canAddMessage(
            conversation: conversation,
            senderID: senderID.uuid,
            logAttributes: logAttributes
        ) else {
            return
        }
        
        // Read protobuf message
        let (protobufMessage) = await readProtobufMessage(
            from: decryptedMessage,
            externalData: messageExternalData?.encryptedMessage
        )
        
        guard let (genericMessage, content) = protobufMessage else {
            WireLogger.eventProcessing.warn(
                "Can't read protobuf, abort processing",
                attributes: logAttributes
            )
            
            return await addInvalidSystemMessage(
                senderID: senderID,
                conversationID: conversationID,
                date: date
            )
        }
        
        await conversationLocalStore.updateSecurityLevelAfterReceivingMessage(
            conversation: conversation,
            genericMessage: genericMessage,
            date: date
        )
        
        await conversationLocalStore.addParticipant(
            participantID: senderID.uuid,
            participantDomain: senderID.domain,
            in: conversation,
            date: date.addingTimeInterval(-0.01)
        )
        
        // Process protobuf message
        await protobufMessageProcessor.processProtobufMessage(
            genericMessage,
            content: content,
            conversation: conversation,
            conversationID: conversationID,
            senderID: senderID,
            senderClientID: messageSenderClientID,
            logAttributes: logAttributes,
            date: date
        )

    }
    
    private func readProtobufMessage(
        from base64Message: String,
        externalData: String?
    ) async -> (GenericMessage, GenericMessage.OneOf_Content)? {
        var genericMessage = GenericMessage(withBase64String: base64Message)

        /// If the encrypted payload is bigger than a certain size, an External Message is sent instead of a regular message.
        /// See `External` section from https://github.com/wireapp/generic-message-proto
        /// See `External messages` section from https://wearezeta.atlassian.net/wiki/spaces/ENGINEERIN/pages/20545866/Messages
        if let externalData,
           case .some(.external(let external)) = genericMessage?.content {
            let externalData = Data(base64Encoded: externalData)
            let externalSha256 = externalData?.zmSHA256Digest()

            guard externalSha256 == external.sha256 else {
                WireLogger.eventProcessing.error("Invalid hash for external data: \(externalSha256 ?? Data()) != \(external.sha256)")
                return nil
            }

            let decryptedData = externalData?.zmDecryptPrefixedPlainTextIV(
                key: external.otrKey
            )

            guard let message = GenericMessage(
                withBase64String: decryptedData?.base64String()
            ) else {
                return nil
            }

            genericMessage = message
        }

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
