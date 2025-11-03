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
import WireSystem

struct ConversationMLSMessageAddEventProcessor: ConversationMLSMessageAddEventProcessorProtocol,
    ConversationMessageAddEventProcessorProtocol {

    enum Failure: Error {
        case mlsConversationNotFound
    }

    let conversationLocalStore: any ConversationLocalStoreProtocol
    let messageLocalStore: any MessageLocalStoreProtocol
    let userLocalStore: any UserLocalStoreProtocol
    let protobufMessageProcessor: any ConversationProtobufMessageProcessorProtocol
    let onProcessedCallEvent: (CallEventInfo) -> Void

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
                event: event,
                date: date
            )
        }
    }

    private func processDecryptedMessage(
        _ decryptedMessage: ConversationMLSMessageAddEvent.DecryptedMessage,
        conversationID: ConversationID,
        senderID: UserID,
        event: ConversationMLSMessageAddEvent,
        date: Date?
    ) async throws {
        guard let conversation = await conversationLocalStore.fetchConversation(
            id: conversationID.id,
            domain: conversationID.domain
        ) else {
            throw Failure.mlsConversationNotFound
        }

        let logAttributes: LogAttributes = [
            .messageType: "conversation.mls-message-add",
            .conversationId: conversationID.id.safeForLoggingDescription
        ]

        // Ensure is self conversation, sender is self user and conversation is not read-only
        guard await messageLocalStore.canAddMessage(
            conversation: conversation,
            senderID: senderID.id
        ) else {
            return WireLogger.eventProcessing.warn(
                "Ignoring incoming message: illegal sender or conversation",
                attributes: logAttributes
            )
        }

        // Parse into GenericMessage with `validate` being `false`. This way the instance can be created even if the
        // `content` cannot be deserialized (it will be set to `nil`).
        // `GenericMessage`s with `content` set to `nil` will be handled later based on the `unknownStrategy` property.
        guard
            let payload = Data(base64Encoded: decryptedMessage.message),
            let genericMessage = GenericMessage(from: payload, validate: false)
        else {
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

        // If `content` is `nil` it probably means that the message content types have been extended and another client
        // or user sent a message which this version doesn't understand yet.
        if genericMessage.content == nil {
            return await handleMessageContentNil(
                messageID: genericMessage.messageID,
                payload: payload,
                senderID: senderID,
                conversationID: conversationID,
                unknownStrategy: genericMessage.unknownStrategy,
                date: date ?? .now
            )
        }

        // Handle calling if there's one.
        if let callEventInfo = getCallEventInfo(
            event: event,
            decryptedMessage: decryptedMessage,
            genericMessage: genericMessage
        ) {
            return onProcessedCallEvent(callEventInfo)
        }

        await conversationLocalStore.updateSecurityLevelAfterReceivingMessage(
            conversation: conversation,
            genericMessage: genericMessage,
            date: date ?? .now
        )

        // Verifies that a sender of an update event is part of the conversation. If they are not,
        // it means that our local state is out of sync and we need to update the list of participants.
        await conversationLocalStore.addParticipantIfNeeded(
            participantID: senderID.id,
            participantDomain: senderID.domain,
            in: conversation,
            date: date?.addingTimeInterval(-0.01) ?? .now
        )

        // Process protobuf message
        try await protobufMessageProcessor.processProtobufMessage(
            genericMessage,
            conversation: conversation,
            conversationID: conversationID,
            senderID: senderID,
            senderClientID: decryptedMessage.senderClientID,
            date: date ?? .now,
            eventMessage: "conversation.mls-message-add"
        )
    }

    // MARK: - Calling

    func getCallEventInfo(
        event: ConversationMLSMessageAddEvent,
        decryptedMessage: ConversationMLSMessageAddEvent.DecryptedMessage,
        genericMessage: GenericMessage
    ) -> CallEventInfo? {
        guard genericMessage.hasCalling else {
            return nil
        }

        guard let callContent: CallContent = .decode(from: genericMessage.calling) else {
            return nil
        }

        guard let payload = genericMessage.calling.content.data(
            using: .utf8, allowLossyConversion: false
        ) else {
            return nil
        }

        let isRemoteMute = callContent.type == "REMOTEMUTE"
        let callingConversationID = genericMessage.calling.qualifiedConversationID
        let senderID = event.senderID
        let eventTimestamp = event.timestamp
        let clientID = decryptedMessage.senderClientID

        let conversationID = !callingConversationID.id
            .isEmpty ? UUID(uuidString: callingConversationID.id)! : event.conversationID.id

        let conversationDomain = !callingConversationID.domain.isEmpty ? callingConversationID.domain : event
            .conversationID.domain

        guard let clientID, let eventTimestamp else {
            return nil
        }

        return CallEventInfo(
            data: payload,
            conversationID: conversationID,
            conversationDomain: conversationDomain,
            userID: senderID.id,
            userDomain: senderID.domain,
            eventTimestamp: eventTimestamp,
            clientID: clientID,
            isMuted: isRemoteMute
        )
    }

}
