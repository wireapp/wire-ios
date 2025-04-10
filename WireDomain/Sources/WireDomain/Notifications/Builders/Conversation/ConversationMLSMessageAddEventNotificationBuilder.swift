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

struct ConversationMLSMessageAddEventNotificationBuilder {

    private enum AssetType {
        case image
        case video
        case audio
        case fileUpload
    }

    let context: Context
    let validator: Validator

    func buildContent(
        event: ConversationMLSMessageAddEvent
    ) async -> UserNotification? {

        let decryptedMessage = event.decryptedMessages.first?.message
        let senderID = event.senderID
        let conversationID = event.conversationID

        guard let message = decryptMessage(
            decryptedMessage: decryptedMessage
        ) else {
            return nil
        }

        let canDisplayNotification = await validator.validate(
            message: message,
            senderID: senderID,
            conversationID: conversationID
        )

        guard canDisplayNotification else {
            return nil
        }

        let hidesNotificationContent = await context.shouldHideNotification()
        let conversation = await context.getConversation(conversationID: conversationID)
        let sender = await context.getSender(senderID: senderID)
        let selfUser = await context.getSelfUser()
        let selfUserID = await context.selfUserID(selfUser: selfUser)
        let senderName = await context.senderName(sender: sender)
        let conversationName = await context.conversationName(conversation: conversation)
        let teamName = await context.teamName(selfUser: selfUser)
        let isGroupConversation = await context.isGroupConversation(
            conversation: conversation
        )

        guard !hidesNotificationContent else {
            return buildHiddenNotification(
                selfUserID: selfUserID,
                senderID: senderID,
                conversationID: conversationID
            )
        }

        await updateConversationUnreadCount(
            conversation: conversation,
            content: message.content
        )

        switch message.content {
        case .location:
            return buildLocationNotification(
                senderName: senderName,
                isGroupConversation: isGroupConversation,
                teamName: teamName,
                conversationName: conversationName,
                selfUserID: selfUserID,
                senderID: senderID,
                conversationID: conversationID
            )
        case .knock:
            return buildPingNotification(
                senderName: senderName,
                isGroupConversation: isGroupConversation,
                teamName: teamName,
                conversationName: conversationName,
                selfUserID: selfUserID,
                senderID: senderID,
                conversationID: conversationID
            )
        case .image:
            return buildAssetNotification(
                ofType: .image,
                senderName: senderName,
                isGroupConversation: isGroupConversation,
                teamName: teamName,
                conversationName: conversationName,
                selfUserID: selfUserID,
                senderID: senderID,
                conversationID: conversationID
            )
        case let .ephemeral(ephemeral):
            return await buildEphemeralNotification(
                conversation: conversation,
                conversationID: conversationID,
                ephemeral: ephemeral,
                selfUserID: selfUserID,
                senderID: senderID
            )
        case let .text(text):
            return await buildTextNotification(
                text,
                conversation: conversation,
                conversationID: conversationID,
                senderName: senderName,
                isGroupConversation: isGroupConversation,
                teamName: teamName,
                conversationName: conversationName,
                selfUserID: selfUserID,
                senderID: senderID
            )
        case let .composite(composite):
            let text = composite.items.compactMap(\.text).first
            return await buildTextNotification(
                text,
                conversation: conversation,
                conversationID: conversationID,
                senderName: senderName,
                isGroupConversation: isGroupConversation,
                teamName: teamName,
                conversationName: conversationName,
                selfUserID: selfUserID,
                senderID: senderID
            )
        case let .asset(assetData):
            switch assetData.original.metaData {
            case .audio:
                return buildAssetNotification(
                    ofType: .audio,
                    senderName: senderName,
                    isGroupConversation: isGroupConversation,
                    teamName: teamName,
                    conversationName: conversationName,
                    selfUserID: selfUserID,
                    senderID: senderID,
                    conversationID: conversationID
                )
            case .video:
                return buildAssetNotification(
                    ofType: .video,
                    senderName: senderName,
                    isGroupConversation: isGroupConversation,
                    teamName: teamName,
                    conversationName: conversationName,
                    selfUserID: selfUserID,
                    senderID: senderID,
                    conversationID: conversationID
                )
            case .image:
                return buildAssetNotification(
                    ofType: .image,
                    senderName: senderName,
                    isGroupConversation: isGroupConversation,
                    teamName: teamName,
                    conversationName: conversationName,
                    selfUserID: selfUserID,
                    senderID: senderID,
                    conversationID: conversationID
                )
            default:
                return buildAssetNotification(
                    ofType: .fileUpload,
                    senderName: senderName,
                    isGroupConversation: isGroupConversation,
                    teamName: teamName,
                    conversationName: conversationName,
                    selfUserID: selfUserID,
                    senderID: senderID,
                    conversationID: conversationID
                )
            }
        case .hidden:
            return buildHiddenNotification(
                selfUserID: selfUserID,
                senderID: senderID,
                conversationID: conversationID
            )
        default:
            return nil
        }
    }

    // MARK: - Build notifications

    private func buildAssetNotification(
        ofType assetType: AssetType,
        senderName: String?,
        isGroupConversation: Bool,
        teamName: String?,
        conversationName: String?,
        selfUserID: UUID,
        senderID: UserID,
        conversationID: ConversationID
    ) -> UserNotification {
        let content = UNMutableNotificationContent()

        if let title = makeTitle(
            isGroupConversation: isGroupConversation,
            teamName: teamName,
            conversationName: conversationName,
            senderName: senderName
        ) {
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
        content.userInfo = makeUserInfo(
            selfUserID: selfUserID,
            senderID: senderID.uuid,
            conversationID: conversationID
        )
        content.threadIdentifier = conversationID.uuid.transportString()

        return .text(content)
    }

    private func buildPingNotification(
        senderName: String?,
        isGroupConversation: Bool,
        teamName: String?,
        conversationName: String?,
        selfUserID: UUID,
        senderID: UserID,
        conversationID: ConversationID
    ) -> UserNotification {
        let content = UNMutableNotificationContent()

        if let title = makeTitle(
            isGroupConversation: isGroupConversation,
            teamName: teamName,
            conversationName: conversationName,
            senderName: senderName
        ) {
            content.title = title
        }

        let body = NotificationBody.singleMessage(
            .ping(senderName: isGroupConversation ? senderName : nil)
        )

        content.body = body.make()
        content.categoryIdentifier = makeCategory()
        content.sound = makeSound(type: .ping)
        content.userInfo = makeUserInfo(
            selfUserID: selfUserID,
            senderID: senderID.uuid,
            conversationID: conversationID
        )
        content.threadIdentifier = conversationID.uuid.transportString()

        return .text(content)
    }

    private func buildHiddenNotification(
        selfUserID: UUID,
        senderID: UserID,
        conversationID: ConversationID
    ) -> UserNotification {
        let content = UNMutableNotificationContent()

        // No title for hidden message, only a body.
        let body: NotificationBody = .singleMessage(.hidden)
        content.body = body.make()
        content.categoryIdentifier = makeCategory()
        content.sound = makeSound()
        content.userInfo = makeUserInfo(
            selfUserID: selfUserID,
            senderID: senderID.uuid,
            conversationID: conversationID
        )
        content.threadIdentifier = conversationID.uuid.transportString()

        return .text(content)
    }

    private func buildTextNotification(
        _ text: Text?,
        conversation: ZMConversation,
        conversationID: ConversationID,
        senderName: String?,
        isGroupConversation: Bool,
        teamName: String?,
        conversationName: String?,
        selfUserID: UUID,
        senderID: UserID
    ) async -> UserNotification? {
        guard let textMessageData = text else {
            return nil
        }

        let text = textMessageData.content.removingExtremeCombiningCharacters

        guard !text.isEmpty else {
            return nil
        }

        let quotedMessageId = UUID(uuidString: textMessageData.quote.quotedMessageID)
        let quotedMessage = await context.fetchMessage(
            id: quotedMessageId,
            conversationID: conversationID
        )

        let isMention = await context.isMessageMentionSelf(text: textMessageData)
        let isReply = await context.isMessageQuotingSelf(message: quotedMessage)

        let content = UNMutableNotificationContent()

        if let title = makeTitle(
            isGroupConversation: isGroupConversation,
            teamName: teamName,
            conversationName: conversationName,
            senderName: senderName
        ) {
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
        content.userInfo = makeUserInfo(
            selfUserID: selfUserID,
            senderID: senderID.uuid,
            conversationID: conversationID
        )
        content.threadIdentifier = conversationID.uuid.transportString()

        if isMention {
            await context.increateUnreadSelfMentionCount(
                for: conversation
            )
        }

        if isReply {
            await context.increaseUnreadSelfReplyCount(
                for: conversation
            )
        }

        return .text(content)
    }

    private func buildLocationNotification(
        senderName: String?,
        isGroupConversation: Bool,
        teamName: String?,
        conversationName: String?,
        selfUserID: UUID,
        senderID: UserID,
        conversationID: ConversationID
    ) -> UserNotification {
        let content = UNMutableNotificationContent()

        if let title = makeTitle(
            isGroupConversation: isGroupConversation,
            teamName: teamName,
            conversationName: conversationName,
            senderName: senderName
        ) {
            content.title = title
        }

        let body = NotificationBody.singleMessage(
            .sharedLocation(senderName: isGroupConversation ? senderName : nil)
        )

        content.body = body.make()
        content.categoryIdentifier = makeCategory()
        content.sound = makeSound()
        content.userInfo = makeUserInfo(
            selfUserID: selfUserID,
            senderID: senderID.uuid,
            conversationID: conversationID
        )
        content.threadIdentifier = conversationID.uuid.transportString()

        return .text(content)
    }

    private func buildEphemeralNotification(
        conversation: ZMConversation,
        conversationID: ConversationID,
        ephemeral: Ephemeral,
        selfUserID: UUID,
        senderID: UserID
    ) async -> UserNotification {
        let isMention: Bool
        let isReply: Bool

        if ephemeral.hasText {
            let textMessageData = ephemeral.text
            let quotedMessageId = UUID(uuidString: textMessageData.quote.quotedMessageID)
            let quotedMessage = await context.fetchMessage(
                id: quotedMessageId,
                conversationID: conversationID
            )

            isMention = await context.isMessageMentionSelf(text: textMessageData)
            isReply = await context.isMessageQuotingSelf(message: quotedMessage)

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
        content.userInfo = makeUserInfo(
            selfUserID: selfUserID,
            senderID: senderID.uuid,
            conversationID: conversationID
        )

        if isMention {
            await context.increateUnreadSelfMentionCount(for: conversation)
        }

        if isReply {
            await context.increaseUnreadSelfReplyCount(for: conversation)
        }

        return .text(content)
    }

    // MARK: - Helpers

    private func makeTitle(
        isGroupConversation: Bool,
        teamName: String?,
        conversationName: String?,
        senderName: String?
    ) -> String? {

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

    private func makeUserInfo(
        selfUserID: UUID,
        senderID: UUID,
        conversationID: ConversationID
    ) -> [AnyHashable: Any] {
        var userInfo: [AnyHashable: Any] = [:]

        userInfo[NotificationUserInfoKey.selfUserID] = selfUserID.uuidString
        userInfo[NotificationUserInfoKey.senderID] = senderID.uuidString
        userInfo[NotificationUserInfoKey.conversationID] = conversationID.uuid.uuidString

        return userInfo
    }

    private func updateConversationUnreadCount(
        conversation: ZMConversation,
        content: GenericMessage.OneOf_Content?
    ) async {
        guard let content else { return }

        switch content {
        case .image, .asset, .location, .knock, .hidden, .ephemeral, .text:
            await context.increaseReadCount(conversation: conversation)
        default:
            return
        }
    }

    private func decryptMessage(
        decryptedMessage: String?
    ) -> GenericMessage? {
        guard let decryptedMessage,
              let (genericMessage, _) = ProtobufMessageDecoder.getProtobufMessage(
                  from: decryptedMessage
              ) else { return nil }

        return genericMessage
    }

}

extension ConversationMLSMessageAddEventNotificationBuilder {
    struct Validator {
        let conversationLocalStore: any ConversationLocalStoreProtocol

        func validate(
            message: GenericMessage,
            senderID: UserID,
            conversationID: ConversationID
        ) async -> Bool {
            let conversation = await conversationLocalStore.fetchOrCreateConversation(
                id: conversationID.uuid,
                domain: conversationID.domain
            )

            let isMessageSilenced = await conversationLocalStore.isMessageSilenced(
                message,
                senderID: senderID.uuid,
                conversation: conversation
            )

            return !isMessageSilenced
        }
    }

    struct Context {
        let conversationLocalStore: any ConversationLocalStoreProtocol
        let userLocalStore: any UserLocalStoreProtocol
        let messageLocalStore: any MessageLocalStoreProtocol

        func getConversation(
            conversationID: ConversationID
        ) async -> ZMConversation {
            await conversationLocalStore.fetchOrCreateConversation(
                id: conversationID.uuid,
                domain: conversationID.domain
            )
        }

        func getSelfUser() async -> ZMUser {
            await userLocalStore.fetchSelfUser()
        }

        func getSender(
            senderID: UserID
        ) async -> ZMUser {
            await userLocalStore.fetchOrCreateUser(
                id: senderID.uuid,
                domain: senderID.domain
            )
        }

        func isGroupConversation(conversation: ZMConversation) async -> Bool {
            await conversationLocalStore.isGroupConversation(conversation)
        }

        func selfUserID(selfUser: ZMUser) async -> UUID {
            await userLocalStore.id(for: selfUser)
        }

        func senderName(
            sender: ZMUser
        ) async -> String? {
            await userLocalStore.name(for: sender)
        }

        func conversationName(
            conversation: ZMConversation
        ) async -> String? {
            await conversationLocalStore.name(for: conversation)
        }

        func teamName(
            selfUser: ZMUser
        ) async -> String? {
            await userLocalStore.teamName(for: selfUser)
        }

        func callerID(
            callContent: CallContent
        ) -> UUID? {
            callContent.callerUserID.flatMap(UUID.init(transportString:))
        }

        func shouldHideNotification() async -> Bool {
            await conversationLocalStore.shouldHideNotification()
        }

        func fetchMessage(
            id: UUID?,
            conversationID: ConversationID
        ) async -> ZMOTRMessage? {
            await messageLocalStore.fetchMessage(
                id: id,
                conversationID: conversationID.uuid,
                conversationDomain: conversationID.domain
            )
        }

        func isMessageMentionSelf(
            text: Text
        ) async -> Bool {
            await messageLocalStore.isMessageMentioningSelf(
                text: text
            )
        }

        func isMessageQuotingSelf(
            message: ZMOTRMessage?
        ) async -> Bool {
            await messageLocalStore.isMessageQuotingSelf(
                quotedMessage: message
            )
        }

        func increateUnreadSelfMentionCount(
            for conversation: ZMConversation
        ) async {
            await conversationLocalStore.increaseUnreadSelfMentionCount(
                for: conversation
            )
        }

        func increaseUnreadSelfReplyCount(
            for conversation: ZMConversation
        ) async {
            await conversationLocalStore.increaseUnreadSelfReplyCount(
                for: conversation
            )
        }

        func increaseReadCount(
            conversation: ZMConversation
        ) async {
            await conversationLocalStore.increaseUnreadCount(
                for: conversation
            )
        }
    }
}
