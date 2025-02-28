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

import WireAPI
import WireDataModel

struct ConversationMLSMessageAddEventNotificationBuilder: NotificationBuilder {

    enum Failure: Error {
        case failedToDecryptMLSMessage
    }

    private enum AssetType {
        case image
        case video
        case audio
        case fileUpload
    }

    struct Context {
        let senderName: String?
        let conversationName: String?
        let isGroupConversation: Bool
        let teamName: String?
        let isMessageSilenced: Bool
        let conversationID: WireAPI.QualifiedID
        let senderID: UUID
        let selfUserID: UUID
        let hidesNotificationContent: Bool
    }

    private let message: GenericMessage
    private let messageLocalStore: any MessageLocalStoreProtocol
    private let context: Context

    init(
        mlsMessageEvent: ConversationMLSMessageAddEvent,
        conversationID: WireAPI.QualifiedID,
        senderID: UserID,
        userLocalStore: any UserLocalStoreProtocol,
        conversationLocalStore: any ConversationLocalStoreProtocol,
        messageLocalStore: any MessageLocalStoreProtocol
    ) async throws {
        self.messageLocalStore = messageLocalStore
        
        let decryptedMessage = mlsMessageEvent.decryptedMessages.first?.message

        guard let decryptedMessage,
              let (genericMessage, _) = ProtobufMessageDecoder.getProtobufMessage(
                  from: decryptedMessage
              ) else {
            throw Failure.failedToDecryptMLSMessage
        }

        self.message = genericMessage

        let conversation = await conversationLocalStore.fetchOrCreateConversation(
            id: conversationID.uuid,
            domain: conversationID.domain
        )

        let sender = await userLocalStore.fetchOrCreateUser(
            id: senderID.uuid,
            domain: senderID.domain
        )

        let senderName = await userLocalStore.name(for: sender)
        let conversationName = await conversationLocalStore.name(for: conversation)
        let isGroupConversation = await conversationLocalStore.isGroupConversation(conversation)
        let selfUser = await userLocalStore.fetchSelfUser()
        let teamName = await userLocalStore.teamName(for: selfUser)
        let isMessageSilenced = await conversationLocalStore.isMessageSilenced(
            message,
            senderID: senderID.uuid,
            conversation: conversation
        )
        let selfUserID = await userLocalStore.id(for: selfUser)
        let shouldHideNotification = await conversationLocalStore.shouldHideNotification()

        self.context = Context(
            senderName: senderName,
            conversationName: conversationName,
            isGroupConversation: isGroupConversation,
            teamName: teamName,
            isMessageSilenced: isMessageSilenced,
            conversationID: conversationID,
            senderID: senderID.uuid,
            selfUserID: selfUserID,
            hidesNotificationContent: shouldHideNotification
        )
    }

    func shouldBuildNotification() async -> Bool {
        !context.isMessageSilenced
    }

    func buildContent() async -> UNMutableNotificationContent {
        guard !context.hidesNotificationContent else {
            return buildHiddenNotification()
        }

        switch message.content {
        case .location:
            return buildLocationNotification()
        case .knock:
            return buildPingNotification()
        case .image:
            return buildAssetNotification(ofType: .image)
        case let .ephemeral(ephemeral):
            return await buildEphemeralNotification(ephemeral: ephemeral)
        case let .text(text):
            return await buildTextNotification(text)
        case let .composite(composite):
            let text = composite.items.compactMap(\.text).first
            return await buildTextNotification(text)
        case let .asset(assetData):
            switch assetData.original.metaData {
            case .audio:
                return buildAssetNotification(ofType: .audio)
            case .video:
                return buildAssetNotification(ofType: .video)
            case .image:
                return buildAssetNotification(ofType: .image)
            default:
                return buildAssetNotification(ofType: .fileUpload)
            }
        case .hidden:
            return buildHiddenNotification()
        default:
            return UNMutableNotificationContent()
        }
    }

    // MARK: - Build notifications

    private func buildAssetNotification(ofType assetType: AssetType) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        let isGroupConversation = context.isGroupConversation
        let senderName = context.senderName

        if let title = makeTitle() {
            content.title = title
        }

        let body: NotificationBody = switch assetType {
        case .image:
            .singleMessage(
                .sharedPicture(senderName: isGroupConversation ? senderName : nil)
            )
        case .video:
            .singleMessage(
                .sharedVideo(senderName: isGroupConversation ? senderName : nil)
            )
        case .audio:
            .singleMessage(
                .sharedAudio(senderName: isGroupConversation ? senderName : nil)
            )
        case .fileUpload:
            .singleMessage(
                .sharedFile(senderName: isGroupConversation ? senderName : nil)
            )
        }

        content.body = body.make()
        content.categoryIdentifier = makeCategory()
        content.sound = makeSound()
        content.userInfo = makeUserInfo()
        content.threadIdentifier = context.conversationID.uuid.transportString()

        return content
    }

    private func buildPingNotification() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        let senderName = context.senderName

        if let title = makeTitle() {
            content.title = title
        }

        let body = NotificationBody.singleMessage(
            .ping(senderName: context.isGroupConversation ? senderName : nil)
        )

        content.body = body.make()
        content.categoryIdentifier = makeCategory()
        content.sound = makeSound(type: .ping)
        content.userInfo = makeUserInfo()
        content.threadIdentifier = context.conversationID.uuid.transportString()

        return content
    }

    private func buildHiddenNotification() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()

        // No title for hidden message, only a body.
        let body: NotificationBody = .singleMessage(.hidden)
        content.body = body.make()
        content.categoryIdentifier = makeCategory()
        content.sound = makeSound()
        content.userInfo = makeUserInfo()
        content.threadIdentifier = context.conversationID.uuid.transportString()

        return content
    }

    private func buildTextNotification(_ text: Text?) async -> UNMutableNotificationContent {
        guard let textMessageData = text else {
            return UNMutableNotificationContent()
        }

        let text = textMessageData.content.removingExtremeCombiningCharacters

        guard !text.isEmpty else {
            return UNMutableNotificationContent()
        }

        let quotedMessageId = UUID(uuidString: textMessageData.quote.quotedMessageID)
        let quotedMessage = await messageLocalStore.fetchMessage(
            id: quotedMessageId,
            conversationID: context.conversationID.uuid,
            conversationDomain: context.conversationID.domain
        )

        let isMention = await messageLocalStore.isMessageMentioningSelf(text: textMessageData)
        let isReply = await messageLocalStore.isMessageQuotingSelf(quotedMessage: quotedMessage)
        let senderName = context.senderName

        let content = UNMutableNotificationContent()

        if let title = makeTitle() {
            content.title = title
        }

        let format: NotificationBody.NewMessageBodyDescriptor = if isMention {
            .textWithMention(content: text, senderName: senderName)
        } else if isReply {
            .textWithReply(content: text, senderName: senderName)
        } else {
            .text(content: text, senderName: senderName)
        }

        let body = NotificationBody.singleMessage(
            format
        )

        content.body = body.make()
        content.categoryIdentifier = makeCategory()
        content.sound = makeSound()
        content.userInfo = makeUserInfo()
        content.threadIdentifier = context.conversationID.uuid.transportString()

        return content
    }

    private func buildLocationNotification() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        let isGroupConversation = context.isGroupConversation
        let senderName = context.senderName

        if let title = makeTitle() {
            content.title = title
        }

        let body = NotificationBody.singleMessage(
            .sharedLocation(senderName: isGroupConversation ? senderName : nil)
        )

        content.body = body.make()
        content.categoryIdentifier = makeCategory()
        content.sound = makeSound()
        content.userInfo = makeUserInfo()
        content.threadIdentifier = context.conversationID.uuid.transportString()

        return content
    }

    private func buildEphemeralNotification(
        ephemeral: Ephemeral
    ) async -> UNMutableNotificationContent {
        let isMention: Bool
        let isReply: Bool

        if ephemeral.hasText {
            let textMessageData = ephemeral.text
            let quotedMessageId = UUID(uuidString: textMessageData.quote.quotedMessageID)
            let quotedMessage = await messageLocalStore.fetchMessage(
                id: quotedMessageId,
                conversationID: context.conversationID.uuid,
                conversationDomain: context.conversationID.domain
            )

            isMention = await messageLocalStore.isMessageMentioningSelf(text: textMessageData)
            isReply = await messageLocalStore.isMessageQuotingSelf(quotedMessage: quotedMessage)

        } else {
            isMention = false
            isReply = false
        }

        let content = UNMutableNotificationContent()

        let format: NotificationBody.NewMessageBodyDescriptor = if isMention {
            .mentionedWithUnknownSender
        } else if isReply {
            .repliedWithUnknownSender
        } else {
            .sentWithUnknownSender
        }

        let body = NotificationBody.singleMessage(
            format
        )

        // No thread identifier for ephemeral messages as we only want to group non ephemeral ones.
        content.body = body.make()
        content.categoryIdentifier = makeCategory()
        content.sound = makeSound()
        content.userInfo = makeUserInfo()

        return content
    }

    // MARK: - Helpers

    private func makeTitle(
    ) -> String? {
        let isGroupConversation = context.isGroupConversation
        let teamName = context.teamName
        let conversationName = context.conversationName
        let senderName = context.senderName

        guard let conversationName, let senderName else {
            return nil
        }

        let format: NotificationTitle.MessageTitleDescriptor = if isGroupConversation {
            if let teamName {
                .conversationInTeam(conversation: conversationName, team: teamName)
            } else {
                .conversation(conversation: conversationName)
            }
        } else {
            if let teamName {
                .senderInTeam(sender: senderName, team: teamName)
            } else {
                .sender(sender: senderName)
            }
        }

        return NotificationTitle
            .conversationMessage(format)
            .make()
    }

    private func makeSound(type: NotificationSound = .default) -> UNNotificationSound {
        let notificationSoundName = UNNotificationSoundName(type.rawValue)
        return UNNotificationSound(named: notificationSoundName)
    }

    private func makeCategory() -> String {
        let category = NotificationCategory.unmutedConversation
        return category.rawValue
    }

    private func makeUserInfo() -> [AnyHashable: Any] {
        var userInfo: [AnyHashable: Any] = [:]

        userInfo[NotificationUserInfoKey.selfUserID] = context.selfUserID
        userInfo[NotificationUserInfoKey.senderID] = context.senderID
        userInfo[NotificationUserInfoKey.conversationID] = context.conversationID.uuid

        return userInfo
    }

}
