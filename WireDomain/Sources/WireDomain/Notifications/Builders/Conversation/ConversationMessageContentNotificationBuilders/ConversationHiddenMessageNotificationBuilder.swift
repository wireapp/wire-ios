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

struct ConversationHiddenMessageNotificationBuilder: ConversationHiddenMessageNotificationBuilderProtocol {
    let context: Context

    func buildContent(
        conversationID: ConversationID,
        senderID: UserID
    ) async -> UserNotification {
        let selfUser = await context.getSelfUser()
        let selfUserID = await context.selfUserID(selfUser: selfUser)
        let conversation = await context.getConversation(conversationID: conversationID)

        let content = UNMutableNotificationContent()

        // No title for hidden message, only a body.
        let body: NotificationBody = .singleMessage(.hidden)
        content.body = body.make()
        content.categoryIdentifier = makeCategory()
        content.sound = makeSound()
        content.userInfo = makeUserInfo(
            selfUserID: selfUserID,
            senderID: senderID.id,
            conversationID: conversationID
        )
        content.threadIdentifier = conversationID.id.transportString()

        await context.increaseReadCount(conversation: conversation)

        return .text(content)
    }

    // MARK: - Helpers

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

extension ConversationHiddenMessageNotificationBuilder {
    struct Context {
        let userLocalStore: any UserLocalStoreProtocol
        let conversationLocalStore: any ConversationLocalStoreProtocol

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

        func increaseReadCount(
            conversation: ZMConversation
        ) async {
            await conversationLocalStore.increaseUnreadCount(
                for: conversation
            )
        }
    }
}
