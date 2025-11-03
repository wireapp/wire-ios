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

import Foundation
import GenericMessageProtocol
import WireLogging

extension ZMOTRMessage {

    @objc
    static func createOrUpdate(
        fromUpdateEvent updateEvent: ZMUpdateEvent,
        inManagedObjectContext context: NSManagedObjectContext,
        prefetchResult: ZMFetchRequestBatchResult
    ) -> ZMOTRMessage? {

        let selfUser = ZMUser.selfUser(in: context)

        guard
            let senderID = updateEvent.senderUUID,
            let conversation = conversation(for: updateEvent, in: context, prefetchResult: prefetchResult),
            !isSelf(
                conversation: conversation,
                andIsSenderID: senderID,
                differentFromSelfUserID: selfUser.remoteIdentifier
            )
        else {
            WireLogger.eventProcessing.debug(
                "Illegal sender or conversation, abort processing.",
                attributes: updateEvent.logAttributes
            )
            return nil
        }

        guard !conversation.isForcedReadOnly else {
            WireLogger.eventProcessing.warn(
                "Ignoring incoming message in readonly conversation.",
                attributes: updateEvent.logAttributes
            )
            return nil
        }

        guard let message = GenericMessage(from: updateEvent, validate: false) else {
            WireLogger.eventProcessing.warn(
                "Can't read protobuf, abort processing:\n\(updateEvent.payload)",
                attributes: updateEvent.logAttributes
            )
            return nil
        }

        // handle unsupported message types (protobuf declaration might have been updated, message from newer clients)
        if message.content == nil {
            return switch message.unknownStrategy {
            case .ignore:
                // Throw the message away without informing the user.
                nil
            case .discardAndWarn:
                // Let the user know, that the app should be updated, then ignore the event.
                appendUnknownMessageReceivedSystemMessage(
                    fromSender: senderID,
                    atTime: updateEvent.timestamp ?? .now,
                    to: conversation,
                    in: context
                )
            case .warnUserAllowRetry:
                // Append a placeholder message to the conversation and store the unprocessed event data.
                appendUnknownMessage(
                    for: updateEvent,
                    messageID: message.messageID,
                    conversation: conversation,
                    context: context
                )
            }
        }

        WireLogger.eventProcessing.debug("Processing:\n\(message)")
        let logAttributes: LogAttributes = [
            .eventId: updateEvent.safeUUID,
            .conversationId: updateEvent.safeLoggingConversationId,
            .nonce: updateEvent.messageNonce?.safeForLoggingDescription ?? "<nil>",
            .messageType: updateEvent.safeType
        ]
        WireLogger.eventProcessing.debug("Processing message", attributes: logAttributes)

        // Update the legal hold state in the conversation
        conversation.updateSecurityLevelIfNeededAfterReceiving(
            message: message,
            timestamp: updateEvent.timestamp ?? Date()
        )

        // Verify sender is part of conversation
        conversation.verifySender(of: updateEvent, moc: context)

        // Insert the message
        switch message.content {
        case .lastRead where conversation.isSelfConversation:
            ZMConversation.updateConversation(
                withLastReadFromSelfConversation: message.lastRead,
                in: context
            )

        case .cleared where conversation.isSelfConversation:
            ZMConversation.updateConversation(
                withClearedFromSelfConversation: message.cleared,
                in: context
            )

        case .hidden where conversation.isSelfConversation:
            ZMMessage.remove(remotelyHiddenMessage: message.hidden, inContext: context)

        case let .dataTransfer(dataTransfer) where conversation.isSelfConversation:
            guard let trackingID = dataTransfer.trackingIdentifierData.flatMap(UUID.init(transportString:))
            else { break }
            ZMUser.selfUser(in: context).trackingID = trackingID

        case .deleted:
            ZMMessage.remove(
                remotelyDeletedMessage: message.deleted,
                inConversation: conversation,
                senderID: senderID,
                inContext: context
            )

        case .reaction:
            ZMMessage.add(
                reaction: message.reaction,
                senderID: senderID,
                conversation: conversation,
                creationDate: updateEvent.timestamp,
                inContext: context
            )

        case .confirmation:
            ZMMessageConfirmation.createMessageConfirmations(
                message.confirmation,
                conversation: conversation,
                updateEvent: updateEvent
            )

        case .buttonAction:
            // ignore if the sender is not the self user
            guard senderID == selfUser.remoteIdentifier else { return nil }

            let buttonAction = message.buttonAction
            ZMClientMessage.updateButtonStates(
                buttonID: buttonAction.buttonID,
                referenceMessageID: buttonAction.referenceMessageID,
                for: conversation,
                in: context
            )

        case .buttonActionConfirmation:
            let buttonActionConfirmation = message.buttonActionConfirmation
            ZMClientMessage.updateButtonStates(
                buttonID: buttonActionConfirmation.hasButtonID ? buttonActionConfirmation.buttonID : .none,
                referenceMessageID: message.buttonActionConfirmation.referenceMessageID,
                for: conversation,
                in: context
            )

        case .edited:
            return ZMClientMessage.editMessage(
                withEdit: message.edited,
                forConversation: conversation,
                updateEvent: updateEvent,
                inContext: context,
                prefetchResult: prefetchResult
            )

        case .clientAction(.resetSession):
            let sender = ZMUser.fetchOrCreate(with: senderID, domain: nil, in: context)
            guard
                let senderClientID = updateEvent.senderClientID,
                let senderClient = UserClient.fetchUserClient(
                    withRemoteId: senderClientID,
                    forUser: sender,
                    createIfNeeded: true
                ),
                let timestamp = updateEvent.timestamp
            else {
                WireLogger.eventProcessing.warn(
                    "clientAction resetSession did not create any message",
                    attributes: logAttributes
                )
                return nil
            }
            conversation.appendSessionResetSystemMessage(user: sender, client: senderClient, at: timestamp)

        case .calling, .availability:
            return nil

        case .inCallEmoji:
            // Not supported yet, just discard. TODO: [WPB-11770] implement here
            return nil

        case .inCallHandRaise:
            // Not supported yet, just discard. TODO: [WPB-11769] implement here
            return nil

        default:
            guard
                conversation.shouldAdd(event: updateEvent),
                let nonce = UUID(uuidString: message.messageID)
            else {
                WireLogger.eventProcessing.warn(
                    "Dropping message because no nonce or for self conv",
                    attributes: logAttributes
                )
                return nil
            }

            let messageClass: AnyClass = GenericMessage.entityClass(for: message)
            var clientMessage = messageClass.fetch(
                withNonce: nonce,
                for: conversation,
                in: context,
                prefetchResult: prefetchResult,
                assumeMissingIfNotPrefetched: true
            ) as? ZMOTRMessage

            guard !isZombieObject(clientMessage) else {
                WireLogger.eventProcessing.warn("Dropping message because zombieObject", attributes: logAttributes)
                return nil
            }

            var isNewMessage = false
            if clientMessage == nil {
                isNewMessage = true

                if messageClass is ZMClientMessage.Type {
                    clientMessage = ZMClientMessage(nonce: nonce, managedObjectContext: context)
                } else if messageClass is ZMAssetClientMessage.Type {
                    clientMessage = ZMAssetClientMessage(nonce: nonce, managedObjectContext: context)
                } else {
                    WireLogger.eventProcessing.warn("Dropping unknown type new message", attributes: logAttributes)
                    return nil
                }

                clientMessage?.senderClientID = updateEvent.senderClientID
                clientMessage?.serverTimestamp = updateEvent.timestamp

                if isGroup(
                    conversation: conversation,
                    andIsSenderID: senderID,
                    differentFromSelfUserID: selfUser.remoteIdentifier
                ) {
                    let isComposite = (message as? ConversationCompositeMessage)?.isComposite ?? false
                    clientMessage?.expectsReadConfirmation = conversation.hasReadReceiptsEnabled || isComposite
                }

                if let message = clientMessage {
                    prefetchResult.add([message])
                }

            } else if clientMessage?.senderClientID == nil || clientMessage?.senderClientID != updateEvent
                .senderClientID {
                WireLogger.eventProcessing.warn(
                    "senderClientID (\(String(describing: clientMessage?.senderClientID))) is missing or different from the update event's senderClientID (\(String(describing: updateEvent.senderClientID)))",
                    attributes: logAttributes
                )
                return nil
            }

            // In case of AssetMessages: If the payload does not match the sha265 digest, calling
            // `updateWithGenericMessage:updateEvent` will delete the object.
            clientMessage?.update(with: updateEvent, initialUpdate: isNewMessage)

            // It seems that if the object was inserted and immediately deleted, the isDeleted flag is not set to true.
            // In addition the object will still have a managedObjectContext until the context is finally saved. In this
            // case, we need to check the nonce (which would have previously been set) to avoid setting an invalid
            // relationship between the deleted object and the conversation and / or sender
            guard !isZombieObject(clientMessage), clientMessage?.nonce != nil else {
                WireLogger.eventProcessing.warn("Dropping potential zombie message", attributes: logAttributes)
                return nil
            }

            clientMessage?.update(with: updateEvent, for: conversation)
            clientMessage?.unarchiveIfNeeded(conversation)
            clientMessage?.updateCategoryCache()

            return clientMessage
        }

        return nil
    }

    private static func isZombieObject(_ message: ZMOTRMessage?) -> Bool {
        guard let message else { return false }
        return message.isZombieObject
    }

    private static func isSelf(
        conversation: ZMConversation,
        andIsSenderID senderID: UUID,
        differentFromSelfUserID selfUserID: UUID
    ) -> Bool {
        conversation.isSelfConversation && senderID != selfUserID
    }

    private static func isGroup(
        conversation: ZMConversation,
        andIsSenderID senderID: UUID,
        differentFromSelfUserID selfUserID: UUID
    ) -> Bool {
        conversation.conversationType == .group && senderID != selfUserID
    }

    private static func appendUnknownMessageReceivedSystemMessage(
        fromSender senderID: UUID,
        atTime time: Date,
        to conversation: ZMConversation,
        in context: NSManagedObjectContext
    ) -> ZMOTRMessage? {
        let sender = ZMUser.fetchOrCreate(
            with: senderID,
            domain: nil,
            in: context
        )
        conversation.appendSystemMessage(
            type: .unknownMessageContentTypeReceived,
            sender: sender,
            users: nil,
            clients: nil,
            timestamp: time
        )
        return nil
    }

    private static func appendUnknownMessage(
        for updateEvent: ZMUpdateEvent,
        messageID: String?,
        conversation: ZMConversation,
        context: NSManagedObjectContext
    ) -> ZMOTRMessage? {
        do {
            let logAttributes = updateEvent.logAttributes
            WireLogger.eventProcessing.warn("Failed to parse GenericMessage from payload, inserting unknown message")

            guard let messageID, let messageID = UUID(transportString: messageID) else {
                WireLogger.eventProcessing.warn("Failed to convert message ID to UUID", attributes: logAttributes)
                return nil
            }
            guard let senderID = updateEvent.senderUUID else {
                WireLogger.eventProcessing.warn("updateEvent.senderUUID is nil", attributes: logAttributes)
                return nil
            }
            guard let base64Payload = updateEvent.genericMessageBase64Content,
                  let payload = Data(base64Encoded: base64Payload) else {
                WireLogger.eventProcessing.warn("Failed to convert base64 string to Data", attributes: logAttributes)
                return nil
            }

            let sender = ZMUser.fetchOrCreate(
                with: senderID,
                domain: nil,
                in: context
            )

            return try conversation.appendUnknownMessage(
                messageID: messageID,
                sender: sender,
                serverTimestamp: updateEvent.timestamp ?? .now,
                payload: payload
            )

        } catch {
            WireLogger.eventProcessing.warn("Failed to insert UnknownMessage placeholder")
            return nil
        }

    }

}
