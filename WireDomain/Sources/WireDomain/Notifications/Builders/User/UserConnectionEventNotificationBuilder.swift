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

import UserNotifications
import WireAPI

struct UserConnectionEventNotificationBuilder: NotificationBuilder {

    private enum ConnectionStatus {
        case pending
        case accepted
    }

    private struct Context {
        let connectionStatus: ConnectionStatus
        let username: String
        let conversationID: WireAPI.QualifiedID?
        let senderID: UUID?
        let selfUserID: UUID
    }

    private let context: Context

    init(
        userConnectionEvent: UserConnectionEvent,
        conversationID: WireAPI.QualifiedID?,
        senderID: UUID?,
        userLocalStore: any UserLocalStoreProtocol
    ) async {
        let isPendingConnection = userConnectionEvent.connection.status == .pending

        let selfUser = await userLocalStore.fetchSelfUser()
        let selfUserID = await userLocalStore.id(for: selfUser)

        self.context = Context(
            connectionStatus: isPendingConnection ? .pending : .accepted,
            username: userConnectionEvent.userName,
            conversationID: conversationID,
            senderID: senderID,
            selfUserID: selfUserID
        )
    }

    func shouldBuildNotification() async -> Bool {
        true
    }

    func buildContent() async -> UserNotification {
        switch context.connectionStatus {
        case .pending:
            buildConnectionRequestNotification(isPending: true)
        case .accepted:
            buildConnectionRequestNotification(isPending: false)
        }
    }

    // MARK: - Build notifications

    private func buildConnectionRequestNotification(
        isPending: Bool
    ) -> UserNotification {
        let content = UNMutableNotificationContent()

        let connectionStatus = context.connectionStatus

        let body = switch connectionStatus {
        case .pending:
            String.formated(key: "push.notification.body.connectionPending", context.username)
        case .accepted:
            String.formated(key: "push.notification.body.connectionAccepted", context.username)
        }

        content.body = body
        content.categoryIdentifier = makeCategory()
        content.sound = makeSound()
        content.userInfo = makeUserInfo()

        return .text(content)
    }

    // MARK: - Helpers

    private func makeSound(type: NotificationSound = .default) -> UNNotificationSound {
        let notificationSoundName = UNNotificationSoundName(type.rawValue)
        return UNNotificationSound(named: notificationSoundName)
    }

    private func makeCategory() -> String {
        switch context.connectionStatus {
        case .accepted:
            NotificationCategory.nonActionable.rawValue
        case .pending:
            NotificationCategory.incomingConnectionRequest.rawValue
        }
    }

    private func makeUserInfo() -> [AnyHashable: Any] {
        var userInfo: [AnyHashable: Any] = [:]

        userInfo[NotificationUserInfoKey.selfUserID] = context.selfUserID
        userInfo[NotificationUserInfoKey.senderID] = context.senderID
        userInfo[NotificationUserInfoKey.conversationID] = context.conversationID?.uuid

        return userInfo
    }

}
