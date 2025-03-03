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

struct ConversationDeleteEventNotificationBuilder: NotificationBuilder {

    private let context: Context
    private let userLocalStore: any UserLocalStoreProtocol
    private let conversationLocalStore: any ConversationLocalStoreProtocol

    struct Context {
        let senderName: String?
        let conversationName: String?
        let isGroupConversation: Bool
        let teamName: String?
        let conversationID: WireAPI.QualifiedID
        let senderID: UUID
        let selfUserID: UUID
    }

    init(
        conversationID: WireAPI.QualifiedID,
        senderID: UserID,
        userLocalStore: any UserLocalStoreProtocol,
        conversationLocalStore: any ConversationLocalStoreProtocol
    ) async {
        self.userLocalStore = userLocalStore
        self.conversationLocalStore = conversationLocalStore

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

        let selfUserID = await userLocalStore.id(for: selfUser)
        let shouldHideNotification = await conversationLocalStore.shouldHideNotification()

        self.context = Context(
            senderName: senderName,
            conversationName: conversationName,
            isGroupConversation: isGroupConversation,
            teamName: teamName,
            conversationID: conversationID,
            senderID: senderID.uuid,
            selfUserID: selfUserID
        )

    }

    func shouldBuildNotification() async -> Bool {
        context.isGroupConversation
    }

    func buildContent() async -> UserNotification {
        buildDeletedConversationNotification()
    }

    // MARK: - Build notifications

    private func buildDeletedConversationNotification() -> UserNotification {
        let content = UNMutableNotificationContent()

        if let title = makeTitle() {
            content.title = title
        }

        let body = if let senderName = context.senderName {
            "\(senderName) deleted the group"
        } else {
            "Someone deleted the group"
        }

        content.body = body
        content.categoryIdentifier = makeCategory()
        content.sound = makeSound()
        content.userInfo = makeUserInfo()
        content.threadIdentifier = context.conversationID.uuid.transportString()

        return .text(content)
    }

    // MARK: - Helpers

    private func makeTitle() -> String? {
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
