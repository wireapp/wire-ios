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

import WireDataModel
import WireNetwork

struct ConversationDeleteEventNotificationBuilder: ConversationDeleteEventNotificationBuilderProtocol {

    let context: Context
    let validator: Validator

    func buildContent(
        event: ConversationDeleteEvent
    ) async -> UserNotification? {
        let conversationID = event.conversationID

        let canBuildNotification = await validator.validate(
            conversationID: conversationID
        )

        guard canBuildNotification else {
            return nil
        }

        let senderID = event.senderID
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

        return await buildDeletedConversationNotification(
            conversation: conversation,
            isGroupConversation: isGroupConversation,
            teamName: teamName,
            conversationName: conversationName,
            senderName: senderName,
            selfUserID: selfUserID,
            senderID: senderID.id,
            conversationID: conversationID
        )
    }

    // MARK: - Build notifications

    private func buildDeletedConversationNotification(
        conversation: ZMConversation,
        isGroupConversation: Bool,
        teamName: String?,
        conversationName: String?,
        senderName: String?,
        selfUserID: UUID,
        senderID: UUID,
        conversationID: ConversationID
    ) async -> UserNotification {
        let content = UNMutableNotificationContent()

        if let title = makeTitle(
            isGroupConversation: isGroupConversation,
            teamName: teamName,
            conversationName: conversationName,
            senderName: senderName
        ) {
            content.title = title
        }

        let body = if let senderName {
            String.formated(key: "push.notification.body.senderDeletedGroup", bundle: .module, senderName)
        } else {
            String.localized(key: "push.notification.body.deletedGroup", bundle: .module)
        }

        content.body = body
        content.categoryIdentifier = makeCategory()
        content.sound = makeSound()
        content.userInfo = makeUserInfo(
            selfUserID: selfUserID,
            senderID: senderID,
            conversationID: conversationID
        )
        content.threadIdentifier = conversationID.id.transportString()

        await context.decreaseUnreadCount(
            conversation: conversation
        )

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
        userInfo[NotificationUserInfoKey.conversationID] = conversationID.id.uuidString

        return userInfo
    }

}

extension ConversationDeleteEventNotificationBuilder {
    struct Validator {
        let conversationLocalStore: any ConversationLocalStoreProtocol

        func validate(conversationID: ConversationID) async -> Bool {
            let conversation = await conversationLocalStore.fetchOrCreateConversation(
                id: conversationID.id,
                domain: conversationID.domain
            )

            return await conversationLocalStore.isGroupConversation(conversation)
        }
    }

    struct Context {
        let conversationLocalStore: any ConversationLocalStoreProtocol
        let userLocalStore: any UserLocalStoreProtocol

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

        func senderName(
            sender: ZMUser
        ) async -> String? {
            await userLocalStore.name(for: sender)
        }

        func isGroupConversation(conversation: ZMConversation) async -> Bool {
            await conversationLocalStore.isGroupConversation(conversation)
        }

        func selfUserID(selfUser: ZMUser) async -> UUID {
            await userLocalStore.id(for: selfUser)
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

        func decreaseUnreadCount(conversation: ZMConversation) async {
            await conversationLocalStore.decreaseUnreadCount(
                for: conversation
            )
        }

    }
}
