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
import WireFoundation
import WireNetwork
import WireLogging

struct ConversationMessageAddEventNotificationBuilder: ConversationMessageAddEventNotificationBuilderProtocol {

    enum Failure: Error {
        case failedToDecryptMLSMessage
        case failedToDecryptProteusMessage
    }

    let context: Context
    let validator: Validator

    let conversationCallingEventNotificationBuilder: any ConversationCallingEventNotificationBuilderProtocol
    let conversationAudioMessageNotificationBuilder: any ConversationAudioMessageNotificationBuilderProtocol
    let conversationEphemeralMessageNotificationBuilder: any ConversationEphemeralMessageNotificationBuilderProtocol
    let conversationFileUploadMessageNotificationBuilder: any ConversationFileUploadMessageNotificationBuilderProtocol
    let conversationHiddenMessageNotificationBuilder: any ConversationHiddenMessageNotificationBuilderProtocol
    let conversationImageMessageNotificationBuilder: any ConversationImageMessageNotificationBuilderProtocol
    let conversationLocationMessageNotificationBuilder: any ConversationLocationMessageNotificationBuilderProtocol
    let conversationPingMessageNotificationBuilder: any ConversationPingMessageNotificationBuilderProtocol
    let conversationVideoMessageNotificationBuilder: any ConversationVideoMessageNotificationBuilderProtocol
    let conversationTextMessageNotificationBuilder: any ConversationTextMessageNotificationBuilderProtocol

    func buildContent(
        event: Either<ConversationMLSMessageAddEvent, ConversationProteusMessageAddEvent>
    ) async throws -> UserNotification? {

        var message: GenericMessage
        var senderID: UserID
        var conversationID: ConversationID
        var timestamp: Date?

        switch event {
        case let .left(mlsMessageEvent):
            let decryptedMessage = mlsMessageEvent.decryptedMessages.first?.message

            message = try decryptMessage(
                decryptedMessage: decryptedMessage,
                isProteus: false
            )

            senderID = mlsMessageEvent.senderID
            conversationID = mlsMessageEvent.conversationID
            timestamp = mlsMessageEvent.timestamp

        case let .right(proteusMessageEvent):
            let decryptedMessage = proteusMessageEvent.message.decryptedMessage
            let external = proteusMessageEvent.externalData?.encryptedMessage

            message = try decryptMessage(
                decryptedMessage: decryptedMessage,
                external: external
            )

            senderID = proteusMessageEvent.senderID
            conversationID = proteusMessageEvent.conversationID
            timestamp = proteusMessageEvent.timestamp
        }

        // DEBUG: Log if this is a calling message
        if message.hasCalling {
            WireLogger.notifications.info(
                "[CALLING-DEBUG] Calling message detected - conversationID: \(conversationID.id.safeForLoggingDescription), senderID: \(senderID.id.safeForLoggingDescription), calling content: \(message.calling.content)",
                attributes: .newNSE, .safePublic
            )
        }

        if let callingNotification = await conversationCallingEventNotificationBuilder.buildContent(
            calling: message.calling,
            at: timestamp,
            conversationID: conversationID,
            senderID: senderID
        ) {
            WireLogger.notifications.info(
                "[CALLING-DEBUG] Calling notification generated successfully",
                attributes: .newNSE, .safePublic
            )
            return callingNotification
        } else {
            if message.hasCalling {
                WireLogger.notifications.info(
                    "[CALLING-DEBUG] Calling message but NO notification generated",
                    attributes: .newNSE, .safePublic
                )
            }
            return await buildMessageContentNotification(
                message: message,
                senderID: senderID,
                conversationID: conversationID
            )
        }
    }

    private func buildMessageContentNotification(
        message: GenericMessage,
        senderID: UserID,
        conversationID: ConversationID
    ) async -> UserNotification? {
        let canDisplayNotification = await validator.validate(
            message: message,
            senderID: senderID,
            conversationID: conversationID
        )

        guard canDisplayNotification else {
            return nil
        }

        let hidesNotificationContent = await context.shouldHideNotification()

        guard !hidesNotificationContent else {
            return await conversationHiddenMessageNotificationBuilder.buildContent(
                conversationID: conversationID,
                senderID: senderID
            )
        }

        switch message.content {
        case .location:
            return await conversationLocationMessageNotificationBuilder.buildContent(
                conversationID: conversationID,
                senderID: senderID
            )
        case .knock:
            return await conversationPingMessageNotificationBuilder.buildContent(
                conversationID: conversationID,
                senderID: senderID
            )
        case .image:
            return await conversationImageMessageNotificationBuilder.buildContent(
                conversationID: conversationID,
                senderID: senderID
            )
        case let .ephemeral(ephemeral):
            return await conversationEphemeralMessageNotificationBuilder.buildContent(
                ephemeral: ephemeral,
                conversationID: conversationID,
                senderID: senderID
            )
        case let .text(text):
            return await conversationTextMessageNotificationBuilder.buildContent(
                text: text,
                conversationID: conversationID,
                senderID: senderID
            )
        case let .composite(composite):
            let text = composite.items.compactMap(\.text).first
            guard let text else { return nil }

            return await conversationTextMessageNotificationBuilder.buildContent(
                text: text,
                conversationID: conversationID,
                senderID: senderID
            )
        case let .asset(assetData):
            switch assetData.original.metaData {
            case .audio:
                return await conversationAudioMessageNotificationBuilder.buildContent(
                    conversationID: conversationID,
                    senderID: senderID
                )
            case .video:
                return await conversationVideoMessageNotificationBuilder.buildContent(
                    conversationID: conversationID,
                    senderID: senderID
                )
            case .image:
                return await conversationImageMessageNotificationBuilder.buildContent(
                    conversationID: conversationID,
                    senderID: senderID
                )
            default:
                return await conversationFileUploadMessageNotificationBuilder.buildContent(
                    conversationID: conversationID,
                    senderID: senderID
                )
            }
        case .hidden:
            return await conversationHiddenMessageNotificationBuilder.buildContent(
                conversationID: conversationID,
                senderID: senderID
            )
        default:
            return nil
        }
    }

    private func decryptMessage(
        decryptedMessage: String?,
        external: String? = nil,
        isProteus: Bool = true
    ) throws -> GenericMessage {
        guard let decryptedMessage,
              let (genericMessage, _) = ProtobufMessageDecoder.getProtobufMessage(
                  from: decryptedMessage,
                  externalData: external
              ) else {
            throw isProteus ? Failure.failedToDecryptProteusMessage : Failure.failedToDecryptMLSMessage
        }

        return genericMessage
    }
}

extension ConversationMessageAddEventNotificationBuilder {
    struct Validator {
        let conversationLocalStore: any ConversationLocalStoreProtocol

        func validate(
            message: GenericMessage,
            senderID: UserID,
            conversationID: ConversationID
        ) async -> Bool {
            let conversation = await conversationLocalStore.fetchOrCreateConversation(
                id: conversationID.id,
                domain: conversationID.domain
            )

            let isMessageSilenced = await conversationLocalStore.isMessageSilenced(
                message,
                senderID: senderID.id,
                conversation: conversation
            )

            return !isMessageSilenced
        }
    }

    struct Context {
        let conversationLocalStore: any ConversationLocalStoreProtocol

        func shouldHideNotification() async -> Bool {
            await conversationLocalStore.shouldHideNotification()
        }

    }
}
