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
import WireProtos
import WireLogging

// sourcery: AutoMockable
/// A common processor for processing MLS / Proteus protobuf message.
/// Used by `ConversationMLSMessageAddEventProcessor` and `ConversationProteusMessageAddEventProcessor`
/// The message content is encoded using protocol buffers. There is a common protocol buffer definition adopted by all Wire client.
public protocol ConversationProtobufMessageProcessorProtocol {

    func processProtobufMessage(
        _ message: GenericMessage,
        content: GenericMessage.OneOf_Content,
        conversation: ZMConversation,
        conversationID: ConversationID,
        senderID: UserID,
        senderClientID: String?,
        date: Date
    ) async throws

}

struct ConversationProtobufMessageProcessor: ConversationProtobufMessageProcessorProtocol {

    let messageLocalStore: any MessageLocalStoreProtocol
    let conversationLocalStore: any ConversationLocalStoreProtocol
    let userLocalStore: any UserLocalStoreProtocol
    let logAttributes: LogAttributes

    func processProtobufMessage(
        _ message: GenericMessage,
        content: GenericMessage.OneOf_Content,
        conversation: ZMConversation,
        conversationID: ConversationID,
        senderID: UserID,
        senderClientID: String?,
        date: Date
    ) async throws {
        var logAttributes = logAttributes
        WireLogger.eventProcessing.debug("Processing:\n\(message)")
        logAttributes[.nonce] = UUID(uuidString: message.messageID) ?? "<nil>"
        WireLogger.eventProcessing.debug("Processing message", attributes: logAttributes)

        // Message content types: https://wearezeta.atlassian.net/wiki/spaces/ENGINEERIN/pages/20545866/Messages
        switch content {
        case .lastRead(let lastRead):

            await conversationLocalStore.updateLastReadMessageTimestamp(
                lastRead,
                in: conversation
            )

        case .cleared(let cleared):

            await conversationLocalStore.updateClearedMessageTimestamp(
                cleared,
                in: conversation
            )

        case .hidden(let hidden):

            await messageLocalStore.deleteMessageForSelf(
                hidden,
                in: conversation
            )

        case .dataTransfer(let dataTransfer):
            guard let trackingIdentifier = dataTransfer.trackingIdentifierData else {
                break
            }

            await userLocalStore.updateSelfUserAnalyticsID(
                analyticsID: trackingIdentifier,
                conversation: conversation
            )

        case .deleted(let deleted):

            await messageLocalStore.deleteMessageForEveryone(
                deleted,
                in: conversation,
                senderID: senderID.uuid
            )

        case .reaction(let reaction):

            await messageLocalStore.addMessageReaction(
                reaction,
                in: conversation,
                senderID: senderID.uuid,
                date: date
            )

        case .confirmation:

            // Some logic was done here but it seems unnecessary - see legacy `ZMOTRMessage+UpdateEvent`
            break

        case .buttonActionConfirmation(let buttonActionConfirmation):

            await messageLocalStore.updateButtonStates(
                buttonActionConfirmation,
                in: conversation
            )

        case .edited(let edited):

            await messageLocalStore.editMessage(
                edited,
                in: conversation,
                senderID: senderID.uuid,
                genericMessage: message,
                date: date
            )

        case .clientAction(.resetSession):

            guard let senderClientID else {
                return WireLogger.eventProcessing.warn(
                    "clientAction resetSession did not create any message",
                    attributes: logAttributes
                )
            }

            let systemMessageType: SystemMessageType = .sessionReset(
                sender: (senderID.uuid, senderID.domain),
                senderClientID: senderClientID,
                date: date
            )

            await messageLocalStore.addSystemMessage(
                messageType: systemMessageType,
                conversationID: conversationID.uuid,
                conversationDomain: conversationID.domain
            )

        case .calling, .availability:

            // cases not handled
            break
            
        case .inCallEmoji:
            
            // Not supported yet, just discard.
            break
            
        case .image, .asset:
            
            try await processAssetMessageContent(
                message: message,
                conversation: conversation,
                sender: (senderID.uuid, senderID.domain, senderClientID),
                date: date,
                logAttributes: logAttributes
            )
            
        case .ephemeral(let data):
            switch data.content {
            case .image, .asset:
                
                try await processAssetMessageContent(
                    message: message,
                    conversation: conversation,
                    sender: (senderID.uuid, senderID.domain, senderClientID),
                    date: date,
                    logAttributes: logAttributes
                )
                
            default:
                try await processMessageContent(
                    message: message,
                    conversation: conversation,
                    sender: (senderID.uuid, senderID.domain, senderClientID),
                    date: date,
                    logAttributes: logAttributes
                )
            }

        case .text, .knock, .location, .composite, .buttonAction:
            
            try await processMessageContent(
                message: message,
                conversation: conversation,
                sender: (senderID.uuid, senderID.domain, senderClientID),
                date: date,
                logAttributes: logAttributes
            )
            
        case .external:
            // Previously handled in `ConversationProteusMessageAddEventProcessor`.
            // If message content is external, it decrypts the external payload and turns it back into a generic non-external content message.
            // Consequently, we should never fall into that case.
            break
        }
    }
    
    private func processAssetMessageContent(
        message: GenericMessage,
        conversation: ZMConversation,
        sender: (id: UUID, domain: String, clientID: String?),
        date: Date,
        logAttributes: LogAttributes
    ) async throws {
        let (assetClientMessage, isNew) = try await messageLocalStore.fetchOrCreateAssetClientMessage(
            id: message.messageID,
            conversation: conversation,
            sender: (sender.id, sender.domain, sender.clientID),
            date: date
        )
        
        await messageLocalStore.addAssetClientMessage(
            assetClientMessage,
            isNewMessage: isNew,
            genericMessage: message,
            conversation: conversation,
            senderID: sender.id,
            senderDomain: sender.domain
        )
    }
    
    private func processMessageContent(
        message: GenericMessage,
        conversation: ZMConversation,
        sender: (id: UUID, domain: String, clientID: String?),
        date: Date,
        logAttributes: LogAttributes
    ) async throws {
        let (clientMessage, isNew) = try await messageLocalStore.fetchOrCreateClientMessage(
            id: message.messageID,
            conversation: conversation,
            sender: (sender.id, sender.domain, sender.clientID),
            date: date
        )
        
        await messageLocalStore.addClientMessage(
            clientMessage,
            isNewMessage: isNew,
            genericMessage: message,
            conversation: conversation,
            senderID: sender.id,
            senderDomain: sender.domain
        )
    }

}
