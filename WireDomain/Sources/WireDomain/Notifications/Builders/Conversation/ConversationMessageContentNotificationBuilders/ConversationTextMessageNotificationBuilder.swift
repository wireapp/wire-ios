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
import WireNetwork

struct ConversationTextMessageNotificationBuilder: ConversationTextMessageNotificationBuilderProtocol {
    let context: Context

    func buildContent(
        text: Text,
        conversationID: ConversationID,
        senderID: UserID
    ) async -> UserNotification? {
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

        let formattedText = text.content.removingExtremeCombiningCharacters

        guard !formattedText.isEmpty else {
            return nil
        }

        let quotedMessageId = UUID(uuidString: text.quote.quotedMessageID)
        let quotedMessage = await context.fetchMessage(
            id: quotedMessageId,
            conversationID: conversationID
        )

        let isMention = await context.isMessageMentionSelf(text: text)
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
            .textWithMention(content: formattedText, senderName: isGroupConversation ? senderName : nil)
        } else if isReply {
            .textWithReply(content: formattedText, senderName: isGroupConversation ? senderName : nil)
        } else {
            .text(content: formattedText, senderName: isGroupConversation ? senderName : nil)
        }

        let body = NotificationBody.singleMessage(
            format
        )

        content.body = body.make()
        content.categoryIdentifier = makeCategory()
        content.sound = makeSound()
        content.userInfo = makeUserInfo(
            selfUserID: selfUserID,
            senderID: senderID.id,
            conversationID: conversationID
        )
        content.threadIdentifier = conversationID.id.transportString()

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

        await context.increaseReadCount(conversation: conversation)

        return .text(content)
    }

    // MARK: - Helpers

    private func makeTitle(
        isGroupConversation: Bool,
        teamName: String?,
        conversationName: String?,
        senderName: String?
    ) -> String? {

        let format: NotificationTitle.MessageTitleDescriptor? = if isGroupConversation, let conversationName {
            if let teamName {
                .conversationInTeam(conversation: conversationName, team: teamName)
            } else {
                .conversation(conversation: conversationName)
            }
        } else if let senderName {
            if let teamName {
                .senderInTeam(sender: senderName, team: teamName)
            } else {
                .sender(sender: senderName)
            }
        } else {
            nil
        }

        guard let format else { return nil }

        return NotificationTitle
            .conversationMessage(format)
            .make()
    }

    private func makeSound() -> UNNotificationSound {
        let soundType = NotificationSound.default
        let notificationSoundName = UNNotificationSoundName(soundType.rawValue)
        return UNNotificationSound(named: notificationSoundName)
    }

    private func makeUserInfo(
        selfUserID: UUID,
        senderID: UUID,
        conversationID: ConversationID
    ) -> [AnyHashable: Any] {
        var userInfo: [AnyHashable: Any] = [:]

        userInfo[NotificationUserInfoKey.selfUserID] = selfUserID.uuidString
        userInfo[NotificationUserInfoKey.senderID] = senderID.uuidString
        userInfo[NotificationUserInfoKey.conversationID] = conversationID.id.uuidString

        return userInfo
    }

    private func makeCategory() -> String {
        let category = NotificationCategory.unmutedConversation
        return category.rawValue
    }
}

extension ConversationTextMessageNotificationBuilder {
    struct Context {
        let conversationLocalStore: any ConversationLocalStoreProtocol
        let userLocalStore: any UserLocalStoreProtocol
        let messageLocalStore: any MessageLocalStoreProtocol

        func getConversation(
            conversationID: ConversationID
        ) async -> ZMConversation {
            await conversationLocalStore.fetchOrCreateConversation(
                id: conversationID.id,
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
                id: senderID.id,
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

        func fetchMessage(
            id: UUID?,
            conversationID: ConversationID
        ) async -> ZMOTRMessage? {
            await messageLocalStore.fetchMessage(
                id: id,
                conversationID: conversationID.id,
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
