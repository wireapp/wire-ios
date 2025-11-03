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

import GenericMessageProtocol
import WireDataModel
import WireLegacyLogging
import WireNetwork

public struct ConversationProtobufMessageProcessor: ConversationProtobufMessageProcessorProtocol {

    let messageLocalStore: any MessageLocalStoreProtocol
    let conversationLocalStore: any ConversationLocalStoreProtocol
    let userLocalStore: any UserLocalStoreProtocol

    public init(
        messageLocalStore: any MessageLocalStoreProtocol,
        conversationLocalStore: any ConversationLocalStoreProtocol,
        userLocalStore: any UserLocalStoreProtocol
    ) {
        self.messageLocalStore = messageLocalStore
        self.conversationLocalStore = conversationLocalStore
        self.userLocalStore = userLocalStore
    }

    public func processProtobufMessage(
        _ message: GenericMessage,
        conversation: ZMConversation,
        conversationID: ConversationID,
        senderID: UserID,
        senderClientID: String?,
        date: Date,
        eventMessage: String
    ) async throws {

        guard message.validateFields(), let content = message.content else {
            throw ProcessProtobufMessageError.invalidMessage
        }

        let logAttributes: LogAttributes = [
            .messageType: eventMessage,
            .conversationId: conversationID.id.safeForLoggingDescription,
            .nonce: UUID(uuidString: message.messageID) ?? "<nil>"
        ]
        WireLogger.eventProcessing.debug("Processing:\n\(message)")
        WireLogger.eventProcessing.debug("Processing message", attributes: logAttributes)

        // Message content types: https://wearezeta.atlassian.net/wiki/spaces/ENGINEERIN/pages/20545866/Messages
        switch content {
        case let .lastRead(lastRead):

            await conversationLocalStore.updateLastReadMessageTimestamp(
                lastRead,
                in: conversation
            )

        case let .cleared(cleared):

            await conversationLocalStore.updateClearedMessageTimestamp(
                cleared,
                in: conversation
            )

        case let .hidden(hidden):

            await messageLocalStore.deleteMessageForSelf(
                hidden,
                in: conversation
            )

        case let .dataTransfer(dataTransfer):
            guard let trackingID = dataTransfer.trackingIdentifierData.flatMap(UUID.init(transportString:)) else {
                break
            }

            await userLocalStore.updateSelfUserTrackingID(
                trackingID: trackingID,
                conversation: conversation
            )

        case let .deleted(deleted):

            await messageLocalStore.deleteMessageForEveryone(
                deleted,
                in: conversation,
                senderID: senderID.id
            )

        case let .reaction(reaction):

            await messageLocalStore.addMessageReaction(
                reaction,
                in: conversation,
                senderID: senderID.id,
                date: date
            )

        case let .confirmation(confirmation):

            await messageLocalStore.addMessageConfirmation(
                confirmation,
                in: conversation,
                senderID: senderID.id,
                senderDomain: senderID.domain,
                date: date
            )

        case let .buttonAction(buttonAction):

            await messageLocalStore.updateButtonStates(
                buttonID: buttonAction.buttonID,
                referenceMessageID: buttonAction.referenceMessageID,
                in: conversation,
                senderID: senderID.id
            )

        case let .buttonActionConfirmation(buttonActionConfirmation):

            // [WPB-17921]: handling ButtonActionConfirmation is currently not needed.
            // It might come back when we can send targeted messages using MLS.
            #if false
                await messageLocalStore.updateButtonStates(
                    buttonID: buttonActionConfirmation.hasButtonID ? buttonActionConfirmation.buttonID : .none,
                    referenceMessageID: buttonActionConfirmation.referenceMessageID,
                    in: conversation,
                    senderID: senderID.id
                )
            #endif

        case let .edited(edited):

            await messageLocalStore.editMessage(
                edited,
                in: conversation,
                senderID: senderID.id,
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
                sender: (senderID.id, senderID.domain),
                senderClientID: senderClientID,
                date: date
            )

            await messageLocalStore.addSystemMessage(
                messageType: systemMessageType,
                conversationID: conversationID.id,
                conversationDomain: conversationID.domain
            )

        case let .availability(availability):
            let userID = WireDataModel.QualifiedID(uuid: senderID.id, domain: senderID.domain)
            let userAvailability = WireDataModel.Availability(proto: availability)
            await userLocalStore.updateUser(
                with: userID,
                availability: userAvailability
            )

        case .calling:

            // case not handled here, see `onProcessedCallEvent`
            break

        case .inCallEmoji:

            // Not supported yet, just discard. TODO: [WPB-11770] implement here
            break

        case .image, .asset:

            try await processAssetMessageContent(
                message: message,
                conversation: conversation,
                sender: (senderID.id, senderID.domain, senderClientID),
                date: date,
                logAttributes: logAttributes
            )

        case let .ephemeral(data):
            switch data.content {
            case .image, .asset:

                try await processAssetMessageContent(
                    message: message,
                    conversation: conversation,
                    sender: (senderID.id, senderID.domain, senderClientID),
                    date: date,
                    logAttributes: logAttributes
                )

            default:
                try await processMessageContent(
                    message: message,
                    conversation: conversation,
                    sender: (senderID.id, senderID.domain, senderClientID),
                    date: date,
                    logAttributes: logAttributes
                )
            }

        case .text, .knock, .location, .composite, .multipart:

            try await processMessageContent(
                message: message,
                conversation: conversation,
                sender: (senderID.id, senderID.domain, senderClientID),
                date: date,
                logAttributes: logAttributes
            )

        case .external:
            // Previously handled in `ConversationProteusMessageAddEventProcessor`.
            // If message content is external, it decrypts the external payload and turns it back into a generic
            // non-external content message.
            // Consequently, we should never fall into that case.
            break

        case .inCallHandRaise:
            break // Not handled yet, TODO: [WPB-11769] implement here
        }
    }

    private func processAssetMessageContent(
        message: GenericMessage,
        conversation: ZMConversation,
        sender: (id: UUID, domain: String, clientID: String?),
        date: Date,
        logAttributes: LogAttributes
    ) async throws {
        let (assetClientMessage, isNew): (ZMAssetClientMessage, Bool)
        do {
            (assetClientMessage, isNew) = try await messageLocalStore.fetchOrCreateAssetClientMessage(
                id: message.messageID,
                conversation: conversation,
                sender: (sender.id, sender.domain, sender.clientID),
                date: date
            )
        } catch let MessageLocalStore.Failure.invalidInsertion(reason: reason) {
            return WireLogger.eventProcessing.warn(
                "failed to process asset message, dropping. Reason: \(reason)",
                attributes: logAttributes
            )
        }

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
        let (clientMessage, isNew): (ZMClientMessage, isNew: Bool)
        do {
            (clientMessage, isNew) = try await messageLocalStore.fetchOrCreateClientMessage(
                id: message.messageID,
                conversation: conversation,
                sender: (sender.id, sender.domain, sender.clientID),
                date: date
            )
        } catch let MessageLocalStore.Failure.invalidInsertion(reason: reason) {
            return WireLogger.eventProcessing.warn(
                "failed to process message, dropping. Reason: \(reason)",
                attributes: logAttributes
            )
        }

        await messageLocalStore.addClientMessage(
            clientMessage,
            isNewMessage: isNew,
            genericMessage: message,
            conversation: conversation,
            senderID: sender.id,
            senderDomain: sender.domain
        )

    }

    private enum ProcessProtobufMessageError: Error {
        /// The `GenericMessage` instance's `validateFields()` method either returned `false` or its `content` is `nil`.
        case invalidMessage
    }

}
