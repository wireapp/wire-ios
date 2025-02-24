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

struct UserConnectionNotificationBuilder: NotificationBuilder {

    enum ConnectionStatus {
        case joined
        case pending
        case accepted
    }

    struct Context {
        let connectionStatus: ConnectionStatus
        let username: String
    }

    private let context: Context

    init(
        connectionStatus: ConnectionStatus,
        username: String
    ) {
        self.context = Context(
            connectionStatus: connectionStatus,
            username: username
        )
    }

    func shouldBuildNotification() async -> Bool {
        true
    }

    func buildContent() async -> UNMutableNotificationContent {
        switch context.connectionStatus {
        case .joined:
            buildUserJoinNotification()
        case .pending:
            buildConnectionRequestNotification(isPending: true)
        case .accepted:
            buildConnectionRequestNotification(isPending: false)
        }
    }

    // MARK: - Build notifications

    private func buildUserJoinNotification() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()

        let body = NotificationBody.userConnection(
            .userJoined(username: context.username)
        )

        content.body = body.make()
        content.categoryIdentifier = makeCategory()
        content.sound = makeSound()

        return content
    }

    private func buildConnectionRequestNotification(
        isPending: Bool
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()

        let body = NotificationBody.userConnection(
            isPending ? .userWantsToConnect(username: context.username) : .usersConnected(username: context.username)
        )

        content.body = body.make()
        content.categoryIdentifier = makeCategory()
        content.sound = makeSound()

        return content
    }

    // MARK: - Helpers

    private func makeSound(type: NotificationSound = .default) -> UNNotificationSound {
        let notificationSoundName = UNNotificationSoundName(type.rawValue)
        return UNNotificationSound(named: notificationSoundName)
    }

    private func makeCategory() -> String {
        switch context.connectionStatus {
        case .joined, .accepted:
            NotificationCategory.nonActionable.rawValue
        case .pending:
            NotificationCategory.incomingConnectionRequest.rawValue
        }
    }

}
