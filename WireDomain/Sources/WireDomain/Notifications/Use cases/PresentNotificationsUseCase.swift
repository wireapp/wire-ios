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

struct PresentNotificationsUseCase {
    
    private let accountManager: AccountManager
    private let selectedAccount: Account
    private let conversationStore: any ConversationLocalStoreProtocol
    private let contentHandler: (UNNotificationContent) -> Void
    
    func invoke(notifications: [UserNotification]) async {
        var standardContent = [UNMutableNotificationContent]()
        var callKitContent = [CallKitContent]()
        
        for notification in notifications {
            switch notification {
            case let .text(content):
                standardContent.append(content)
            case let .callKit(content):
                callKitContent.append(content)
            case .notDisplayed:
                break
            }
        }
        
        await presentStandardNotitification(content: standardContent)
        await presentCallKitNotification(content: callKitContent)
    }
    
    private func presentStandardNotitification(content: [UNMutableNotificationContent]) async {
        var notification: UNMutableNotificationContent

        switch content.count {
        case 0:
            // Nothing to show
            notification = .emptyNotification
        case 1:
            notification = content[0]
        default:
            notification = UNMutableNotificationContent()
            let body = NotificationBody.bundled(messagesCount: content.count)
            notification.body = body.make()
        }

        notification.interruptionLevel = .timeSensitive
        notification.badge = await getNotificationBadge()

        WireLogger.notifications.info("Displaying push notification", attributes: .newNSE)
        
        // Displays the notification to the user
        contentHandler(notification)
    }
    
    private func getNotificationBadge() async -> NSNumber {
        let unreadConversationCount = await Int(conversationStore.unreadConversationCount())
        selectedAccount.unreadConversationCount = unreadConversationCount
        let totalUnreadCount = accountManager.totalUnreadCount
        return NSNumber(value: totalUnreadCount)
    }
    
    private func presentCallKitNotification(content: [CallKitContent]) async {
        // TODO: check... is this correct?
        guard let lastContent = content.last else {
            return
        }
        
        do {
            try await CXProvider.reportNewIncomingVoIPPushPayload(lastContent)
        } catch {
            WireLogger.calling.error(
                "failed to wake up main app: \(error.localizedDescription)",
                attributes: .newNSE
            )
        }
    }
    
}
