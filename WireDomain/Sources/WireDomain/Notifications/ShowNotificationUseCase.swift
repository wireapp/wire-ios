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
import Foundation
import UserNotifications
import WireDataModel
import WireLogging

protocol ShowNotificationUseCaseProtocol {
    func invoke(
        userNotifications: [UserNotification]
    ) async throws
}

struct ShowNotificationUseCase: ShowNotificationUseCaseProtocol {

    private let contentHandler: (UNNotificationContent) -> Void
    private let conversationLocalStore: any ConversationLocalStoreProtocol
    private let selectedAccount: Account
    private let accountManager: AccountManager
    private let databaseSaver: any DatabaseSaverProtocol

    init(
        contentHandler: @escaping (UNNotificationContent) -> Void,
        conversationLocalStore: any ConversationLocalStoreProtocol,
        selectedAccount: Account,
        accountManager: AccountManager,
        databaseSaver: any DatabaseSaverProtocol
    ) {
        self.contentHandler = contentHandler
        self.conversationLocalStore = conversationLocalStore
        self.selectedAccount = selectedAccount
        self.accountManager = accountManager
        self.databaseSaver = databaseSaver
    }

    func invoke(
        userNotifications: [UserNotification]
    ) async throws {
        var notifications: [UNMutableNotificationContent] = []

        for userNotification in userNotifications {
            switch userNotification {
            case let .text(notificationContent):
                notifications.append(notificationContent)
            case let .callKit(callKitContent):
                do {

                    WireLogger.calling.info(
                        "Detected a call event",
                        attributes: .newNSE, .safePublic
                    )

                    try await CXProvider.reportNewIncomingVoIPPushPayload(callKitContent)
                } catch {
                    WireLogger.calling.error(
                        "failed to wake up main app: \(String(describing: error))",
                        attributes: .newNSE, .safePublic
                    )
                }
            }
        }

        try await showNotifications(notifications)
    }

    private func showNotifications(
        _ notifications: [UNMutableNotificationContent]
    ) async throws {
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
        notification.badge = try await getNotificationBadge()

        WireLogger.notifications.info(
            "Showing notification to the user",
            attributes: .newNSE, .safePublic
        )

        // Displays the notification to the user
        contentHandler(notification)
    }

    private func getNotificationBadge() async throws -> NSNumber {
        // Ensures unread conversations count is up-to-date.
        try await databaseSaver.save()

        let unreadConversationCount = await Int(
            conversationLocalStore.unreadConversationCount()
        )

        selectedAccount.unreadConversationCount = unreadConversationCount
        accountManager.addOrUpdate(selectedAccount)

        let totalUnreadCount = accountManager.totalUnreadCount

        return NSNumber(value: totalUnreadCount)
    }
}
