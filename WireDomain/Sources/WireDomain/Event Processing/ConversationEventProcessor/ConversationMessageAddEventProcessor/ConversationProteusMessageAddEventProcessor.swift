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

struct ConversationProteusMessageAddEventProcessor: ConversationProteusMessageAddEventProcessorProtocol,
    ConversationMessageAddEventProcessorProtocol {

    let conversationLocalStore: any ConversationLocalStoreProtocol
    let messageLocalStore: any MessageLocalStoreProtocol
    let userLocalStore: any UserLocalStoreProtocol
    let protobufMessageProcessor: any ConversationProtobufMessageProcessorProtocol
    let onProcessedCallEvent: (CallEventInfo) -> Void

    func processEvent(_ event: ConversationProteusMessageAddEvent) async throws {
        let senderID = event.senderID
        let conversationID = event.conversationID
        let messageContent = event.message
        let messageExternalData = event.externalData
        let messageSenderClientID = event.messageSenderClientID
        let date = event.timestamp

        // Message should be decrypted see `ProteusEventDecryptor`
        guard let decryptedMessage = messageContent.decryptedMessage else {
            return WireLogger.proteus.error(
                "failed to add proteus message: there is no decrypted message to process"
            )
        }

        guard let conversation = await conversationLocalStore.fetchConversation(
            id: conversationID.id,
            domain: conversationID.domain
        ) else {
            return WireLogger.proteus.error(
                "failed to add proteus message: conversation not found in db"
            )
        }

        let logAttributes: LogAttributes = [
            .messageType: "conversation.otr-message-add",
            .conversationId: conversationID.id.safeForLoggingDescription
        ]

        // Ensure is not self conversation, sender is self user and conversation is not read-only
        guard await messageLocalStore.canAddMessage(
            conversation: conversation,
            senderID: senderID.id
        ) else {
            return WireLogger.eventProcessing.warn(
                "Ignoring incoming message: illegal sender or conversation",
                attributes: logAttributes
            )
        }

        // Deserialize the GenericMessage instance and handle `content` being `nil` if needed.
        let payload = await getProtobufPayload(
            from: decryptedMessage,
            externalData: messageExternalData?.encryptedMessage
        )
        guard let payload, let genericMessage = GenericMessage(from: payload, validate: false) else {
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

        if genericMessage.content == nil {
            return await handleMessageContentNil(
                messageID: genericMessage.messageID,
                payload: payload,
                senderID: senderID,
                conversationID: conversationID,
                unknownStrategy: genericMessage.unknownStrategy,
                date: date
            )
        }

        // Handle calling if there's one.
        if let callEventInfo = getCallEventInfo(
            event: event,
            genericMessage: genericMessage
        ) {
            return onProcessedCallEvent(callEventInfo)
        }

        await conversationLocalStore.updateSecurityLevelAfterReceivingMessage(
            conversation: conversation,
            genericMessage: genericMessage,
            date: date
        )

        // Verifies that a sender of an update event is part of the conversation. If they are not,
        // it means that our local state is out of sync and we need to update the list of participants.
        await conversationLocalStore.addParticipantIfNeeded(
            participantID: senderID.id,
            participantDomain: senderID.domain,
            in: conversation,
            date: date.addingTimeInterval(-0.01)
        )

        // Process protobuf message
        try await protobufMessageProcessor.processProtobufMessage(
            genericMessage,
            conversation: conversation,
            conversationID: conversationID,
            senderID: senderID,
            senderClientID: messageSenderClientID,
            date: date,
            eventMessage: "conversation.otr-message-add"
        )
    }

    private func getProtobufPayload(
        from base64Message: String,
        externalData: String?
    ) async -> Data? {
        guard let payload = Data(base64Encoded: base64Message) else { return nil }

        if
            let externalData,
            let genericMessage = GenericMessage(from: payload, validate: false),
            case let .some(.external(external)) = genericMessage.content {
            /// Content message is external, we decrypt the external payload
            /// and turns it back into a generic non-external content message.
            if let externalPayload = decryptExternalPayload(externalData: externalData, external: external) {
                return externalPayload
            } else {
                return nil
            }
        }

        return payload
    }

    private func decryptExternalPayload(
        externalData: String,
        external: External
    ) -> Data? {
        /// If the encrypted payload is bigger than a certain size, an External Message is sent instead of a regular
        /// message.
        /// See `External` section from https://github.com/wireapp/generic-message-proto
        /// See `External messages` section from
        /// https://wearezeta.atlassian.net/wiki/spaces/ENGINEERIN/pages/20545866/Messages

        let externalData = Data(base64Encoded: externalData)
        let externalSha256 = externalData?.zmSHA256Digest()

        guard externalSha256 == external.sha256 else {
            WireLogger.eventProcessing
                .error("Invalid hash for external data: \(externalSha256 ?? Data()) != \(external.sha256)")
            return nil
        }

        return externalData?.zmDecryptPrefixedPlainTextIV(
            key: external.otrKey
        )
    }

    // MARK: - Calling

    func getCallEventInfo(
        event: ConversationProteusMessageAddEvent,
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
        let clientID = event.messageSenderClientID

        let conversationID = !callingConversationID.id
            .isEmpty ? UUID(uuidString: callingConversationID.id)! : event.conversationID.id

        let conversationDomain = !callingConversationID.domain.isEmpty ? callingConversationID.domain : event
            .conversationID.domain

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
