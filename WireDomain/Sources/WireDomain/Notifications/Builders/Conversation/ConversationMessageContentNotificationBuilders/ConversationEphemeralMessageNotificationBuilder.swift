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

struct ConversationEphemeralMessageNotificationBuilder: ConversationEphemeralMessageNotificationBuilderProtocol {
    let context: Context

    func buildContent(
        ephemeral: Ephemeral,
        conversationID: ConversationID,
        senderID: UserID
    ) async -> UserNotification? {
        let conversation = await context.getConversation(conversationID: conversationID)
        let selfUser = await context.getSelfUser()
        let selfUserID = await context.selfUserID(selfUser: selfUser)

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
            senderID: senderID.id,
            conversationID: conversationID
        )

        if isMention {
            await context.increateUnreadSelfMentionCount(for: conversation)
        }

        if isReply {
            await context.increaseUnreadSelfReplyCount(for: conversation)
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

extension ConversationEphemeralMessageNotificationBuilder {
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

        func selfUserID(selfUser: ZMUser) async -> UUID {
            await userLocalStore.id(for: selfUser)
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
