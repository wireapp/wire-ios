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

struct NewSystemMessageNotificationBuilder: NotificationBuilder {

    enum SystemMessage {
        case memberLeave(removedUserIDs: Set<UUID>)
        case conversationCreated
        case memberJoin(addedUserIDs: Set<UUID>)
        case conversationDeleted
        case messageTimerUpdate(newTimer: Int64?)
    }

    private let context: Context

    struct Context {
        let senderName: String?
        let conversationName: String?
        let isGroupConversation: Bool
        let teamName: String?
        let conversationID: WireAPI.QualifiedID
        let senderID: UUID
        let selfUserID: UUID
        let hidesNotificationContent: Bool
        let systemMessage: SystemMessage
    }

    init(
        systemMessage: SystemMessage,
        conversationID: WireAPI.QualifiedID,
        senderID: UserID
    ) async {

        let conversationLocalStore: ConversationLocalStoreProtocol = Injector.resolve()
        let userLocalStore: UserLocalStoreProtocol = Injector.resolve()

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
            selfUserID: selfUserID,
            hidesNotificationContent: shouldHideNotification,
            systemMessage: systemMessage
        )

    }

    func shouldBuildNotification() async -> Bool {
        switch context.systemMessage {
        case let .memberLeave(removedUserIDs):
            removedUserIDs.contains(context.selfUserID)
        case let .memberJoin(addedUserIDs):
            addedUserIDs.contains(context.selfUserID)
        case .conversationCreated, .conversationDeleted, .messageTimerUpdate:
            true
        }
    }

    func buildContent() async -> UNMutableNotificationContent {
        switch context.systemMessage {
        case .memberLeave:
            return buildMemberLeaveNotification()
        case .memberJoin:
            return buildMemberJoinNotification()
        case .conversationCreated:
            return buildConversationCreatedNotification()
        case .conversationDeleted:
            // TODO: [WPB-11658]
            break
        case let .messageTimerUpdate(timeoutValue):
            var timeoutStrValue: String?

            if let timeoutValue {
                let timerInMilliseconds = Double(timeoutValue)
                let timeoutValue = timerInMilliseconds / 1000
                let timeout: MessageDestructionTimeoutValue = .init(rawValue: timeoutValue)

                timeoutStrValue = timeout.displayString
            }

            return buildTimerUpdateNotification(timeout: timeoutStrValue)
        }

        return UNMutableNotificationContent()
    }

    // MARK: - Build notifications

    private func buildMemberLeaveNotification() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()

        if let title = makeTitle() {
            content.title = title
        }

        let body = NotificationBody.newSystemMessage(
            .removedYou(senderName: context.senderName)
        )

        content.body = body.make()
        content.categoryIdentifier = makeCategory()
        content.sound = makeSound()
        content.userInfo = makeUserInfo()
        content.threadIdentifier = context.conversationID.uuid.transportString()

        return content
    }
    
    private func buildMemberJoinNotification() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()

        if let title = makeTitle() {
            content.title = title
        }
        
        let body = NotificationBody.newSystemMessage(
            .addedYou(senderName: context.senderName)
        )
            
        content.body = body.make()
        content.categoryIdentifier = makeCategory()
        content.sound = makeSound()
        content.userInfo = makeUserInfo()
        content.threadIdentifier = context.conversationID.uuid.transportString()

        return content
    }

    private func buildConversationCreatedNotification() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()

        if let title = makeTitle() {
            content.title = title
        }

        let body = NotificationBody.newSystemMessage(
            .createdConversation(senderName: context.senderName)
        )

        content.body = body.make()
        content.categoryIdentifier = makeCategory()
        content.sound = makeSound()
        content.userInfo = makeUserInfo()
        content.threadIdentifier = context.conversationID.uuid.transportString()

        return content
    }
    
    private func buildTimerUpdateNotification(timeout: String?) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()

        if let title = makeTitle() {
            content.title = title
        }

        let bodyFormat: NotificationBody.SystemMessageBodyFormat = if let timeout {
            .setMessageTimer(senderName: context.senderName, timeoutValue: timeout)
        } else {
            .turnedOffMessageTimer(senderName: context.senderName)
        }
        
        let body = NotificationBody.newSystemMessage(
            bodyFormat
        )
            
        content.body = body.make()
        content.categoryIdentifier = makeCategory()
        content.sound = makeSound()
        content.userInfo = makeUserInfo()
        content.threadIdentifier = context.conversationID.uuid.transportString()

        return content
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

        let format: NotificationTitle.MessageTitleFormat = if isGroupConversation {
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
            .newMessage(format)
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

        userInfo["selfUserIDString"] = context.selfUserID
        userInfo["senderIDString"] = context.senderID
        userInfo["conversationIDString"] = context.conversationID.uuid

        return userInfo
    }

}
