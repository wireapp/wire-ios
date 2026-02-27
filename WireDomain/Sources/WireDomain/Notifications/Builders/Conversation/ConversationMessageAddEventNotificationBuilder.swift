//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import WireLogging
import WireNetwork

struct ConversationMessageAddEventNotificationBuilder: ConversationMessageAddEventNotificationBuilderProtocol {

    enum Failure: Error {

        case failedToDecodeGenericMessage
        case unknownMessageContent
        case proteusMessageMissing
        case externalProteusDataMissing
        case failedToDecodeExternalProteusData
        case externalProteusDataSHAMismatch
        case failedToDecryptExternalProteusData

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

    struct MessageContent {
        var message: GenericMessage
        var senderID: UserID
        var conversationID: ConversationID
        var timestamp: Date?
    }

    func buildContent(
        event: Either<ConversationMLSMessageAddEvent, ConversationProteusMessageAddEvent>
    ) async throws -> [UserNotification]? {
        switch event {
        case let .left(mlsMessageEvent):
            var userNotifications = [UserNotification]()

            for decryptedMessage in mlsMessageEvent.decryptedMessages {
                do {
                    let message = try extractMessageContent(from: decryptedMessage.message)

                    let messageContent =
                        MessageContent(
                            message: message,
                            senderID: mlsMessageEvent.senderID,
                            conversationID: mlsMessageEvent.conversationID,
                            timestamp: mlsMessageEvent.timestamp
                        )

                    if let userNotification = try await buildUserNotification(for: messageContent) {
                        userNotifications.append(userNotification)
                    }
                } catch {
                    WireLogger.sync.error(
                        "Failed to build notification for message",
                        attributes: [.conversationId: mlsMessageEvent.conversationID.id.safeForLoggingDescription]
                    )
                }
            }

            return userNotifications.isEmpty ? nil : userNotifications

        case let .right(proteusMessageEvent):
            guard let decryptedMessage = proteusMessageEvent.message.decryptedMessage else {
                throw Failure.proteusMessageMissing
            }

            var message = try extractMessageContent(from: decryptedMessage)

            // Extra large proteus messages (many recipients) are contained
            // in external data.
            if case let .external(externalMessage) = message.content {
                guard let externalData = proteusMessageEvent.externalData?.encryptedMessage else {
                    throw Failure.externalProteusDataMissing
                }

                message = try decryptExternalProteusData(
                    external: externalMessage,
                    externalData: externalData
                )
            }

            let messageContent = MessageContent(
                message: message,
                senderID: proteusMessageEvent.senderID,
                conversationID: proteusMessageEvent.conversationID,
                timestamp: proteusMessageEvent.timestamp
            )
            let userNotification = try await buildUserNotification(for: messageContent)
            return userNotification.flatMap { [$0] }
        }
    }

    private func buildUserNotification(for content: MessageContent) async throws -> UserNotification? {

        if let callingNotification = await conversationCallingEventNotificationBuilder.buildContent(
            calling: content.message.calling,
            at: content.timestamp,
            conversationID: content.conversationID,
            senderID: content.senderID
        ) {
            callingNotification
        } else {
            await buildMessageContentNotification(
                message: content.message,
                senderID: content.senderID,
                conversationID: content.conversationID
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

    // MARK: - Message Processing

    private func extractMessageContent(from base64Message: String) throws -> GenericMessage {
        // Decode the protobuf message.
        guard let genericMessage = GenericMessage(
            from: base64Message,
            validate: true
        ) else {
            throw Failure.failedToDecodeGenericMessage
        }

        // Ensure the content is understood.
        if genericMessage.content == nil {
            throw Failure.unknownMessageContent
        }

        return genericMessage
    }

    private func decryptExternalProteusData(
        external: External,
        externalData: String
    ) throws -> GenericMessage {
        // Decode the base64 external data.
        guard let encryptedData = Data(base64Encoded: externalData) else {
            throw Failure.failedToDecodeExternalProteusData
        }

        // Verify SHA256 hash.
        guard encryptedData.zmSHA256Digest() == external.sha256 else {
            throw Failure.externalProteusDataSHAMismatch
        }

        // Decrypt the data.
        guard let decryptedData = encryptedData.zmDecryptPrefixedPlainTextIV(
            key: external.otrKey
        ) else {
            throw Failure.failedToDecryptExternalProteusData
        }

        // Decode the decrypted message.
        guard let message = GenericMessage(
            from: decryptedData.base64String(),
            validate: true
        ) else {
            throw Failure.failedToDecryptExternalProteusData
        }

        return message
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
