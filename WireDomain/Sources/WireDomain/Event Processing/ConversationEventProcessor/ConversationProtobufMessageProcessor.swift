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

import WireProtos
import WireDataModel
import WireAPI

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
        logAttributes: LogAttributes,
        date: Date
    ) async
    
}

struct ConversationProtobufMessageProcessor: ConversationProtobufMessageProcessorProtocol {
    
    let messageLocalStore: any MessageLocalStoreProtocol
    let userLocalStore: any UserLocalStoreProtocol
    
    func processProtobufMessage(
        _ message: GenericMessage,
        content: GenericMessage.OneOf_Content,
        conversation: ZMConversation,
        conversationID: ConversationID,
        senderID: UserID,
        senderClientID: String?,
        logAttributes: LogAttributes,
        date: Date
    ) async {
        var logAttributes = logAttributes
        WireLogger.eventProcessing.debug("Processing:\n\(message)")
        logAttributes[.nonce] = UUID(uuidString: message.messageID) ?? "<nil>"
        WireLogger.eventProcessing.debug("Processing message", attributes: logAttributes)
        
        // Message content types: https://wearezeta.atlassian.net/wiki/spaces/ENGINEERIN/pages/20545866/Messages
        switch content {
        case .lastRead:
            
            await messageLocalStore.updateSelfConversation(
                message.lastRead,
                in: conversation
            )
            
        case .cleared:
            
            await messageLocalStore.deleteOlderMessages(
                message.cleared,
                in: conversation
            )

        case .hidden:
            
            await messageLocalStore.deleteMessageForSelf(
                message.hidden,
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

        case .deleted:
            
            await messageLocalStore.deleteMessageForEveryone(
                message.deleted,
                in: conversation,
                senderID: senderID.uuid
            )

        case .reaction:
            
            await messageLocalStore.addMessageReaction(
                message.reaction,
                in: conversation,
                senderID: senderID.uuid,
                date: date
            )

        case .confirmation:
            
            // Some logic was done here but it seems unnecessary - see legacy `ZMOTRMessage+UpdateEvent`
            break
            
        case .buttonActionConfirmation:
            
            await messageLocalStore.updateButtonStates(
                message.buttonActionConfirmation,
                in: conversation
            )

        case .edited:
            
            await messageLocalStore.editMessage(
                message.edited,
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

        default:
            
            await messageLocalStore.addTextMessage(
                message,
                in: conversation,
                senderID: senderID.uuid,
                senderDomain: senderID.domain,
                senderClientID: senderClientID,
                date: date,
                logAttributes: logAttributes
            )
            
        }
    }
    
}
