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

import CallKit
import UserNotifications
import WireAPI
import WireDataModel
import WireLogging

// sourcery: AutoMockable
protocol GenerateNotificationServiceProtocol {
    func process() async
}

struct GenerateNotificationService: GenerateNotificationServiceProtocol {

    private let eventsStream: AsyncStream<[UpdateEvent]>
    private let contentHandler: (UNNotificationContent) -> Void
    private let accountManager: AccountManager
    private let selectedAccount: Account
    private let userLocalStore: any UserLocalStoreProtocol
    private let conversationLocalStore: any ConversationLocalStoreProtocol
    private let messageLocalStore: any MessageLocalStoreProtocol

    init(
        eventsStream: AsyncStream<[UpdateEvent]>,
        contentHandler: @escaping (UNNotificationContent) -> Void,
        accountManager: AccountManager,
        selectedAccount: Account,
        userLocalStore: any UserLocalStoreProtocol,
        conversationLocalStore: any ConversationLocalStoreProtocol,
        messageLocalStore: any MessageLocalStoreProtocol
    ) {
        self.eventsStream = eventsStream
        self.contentHandler = contentHandler
        self.accountManager = accountManager
        self.selectedAccount = selectedAccount
        self.conversationLocalStore = conversationLocalStore
        self.userLocalStore = userLocalStore
        self.messageLocalStore = messageLocalStore
    }

    /// Processes the events stream.
    func process() async {
        for await events in eventsStream {
            await generateNotifications(for: events)
        }
    }

    private func generateNotifications(
        for events: [UpdateEvent]
    ) async {
        guard !events.isEmpty else {
            return contentHandler(.emptyNotification)
        }

        var notifications: [UNMutableNotificationContent] = []

        for event in events {
            var notificationBuilder: NotificationBuilder

            switch event {
            case let .conversation(conversationEvent):
                notificationBuilder = await ConversationEventNotificationBuilder(
                    event: conversationEvent,
                    userLocalStore: userLocalStore,
                    conversationLocalStore: conversationLocalStore,
                    messageLocalStore: messageLocalStore
                )

            case let .user(userEvent):
                notificationBuilder = UserNotificationBuilder(
                    event: userEvent,
                    userLocalStore: userLocalStore
                )

            default:
                continue
            }

            guard await notificationBuilder.shouldBuildNotification() else {
                continue
            }

            do {
                let userNotification = try await notificationBuilder.buildContent()

                switch userNotification {
                case let .text(notificationContent):
                    notifications.append(notificationContent)
                case let .callKit(callKitContent):
                    try await CXProvider.reportNewIncomingVoIPPushPayload(callKitContent)
                }

            } catch {
                WireLogger.notifications.error(
                    "Failed to generate notification: \(error.localizedDescription)"
                )
                notifications.append(.emptyNotification)
            }
        }

        await showNotifications(notifications)
    }

    private func showNotifications(
        _ notifications: [UNMutableNotificationContent]
    ) async {
        var notification: UNMutableNotificationContent

        switch notifications.count {
        case 0:
            // Nothing to show
            notification = .emptyNotification
        case 1:
            notification = notifications[0]
        default:
            notification = UNMutableNotificationContent()
            let body = NotificationBody.bundled(messagesCount: notifications.count)
            notification.body = body.make()
        }

        notification.interruptionLevel = .timeSensitive
        notification.badge = await getNotificationBadge()

        // Displays the notification to the user
        contentHandler(notification)
    }

    private func getNotificationBadge() async -> NSNumber {
        let unreadConversationCount = await Int(conversationLocalStore.unreadConversationCount())
        selectedAccount.unreadConversationCount = unreadConversationCount
        let totalUnreadCount = accountManager.totalUnreadCount

        return NSNumber(value: totalUnreadCount)
    }
}
