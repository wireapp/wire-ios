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
import UserNotifications
import WireLogging

struct GenerateNotificationService {
    
    private let eventsStream: AsyncStream<[UpdateEvent]>
    private let contentHandler: (UNNotificationContent) -> Void
    private let userLocalStore: any UserLocalStoreProtocol
    private let conversationLocalStore: any ConversationLocalStoreProtocol
    private let messageLocalStore: any MessageLocalStoreProtocol
    
    init(
        eventsStream: AsyncStream<[UpdateEvent]>,
        contentHandler: @escaping (UNNotificationContent) -> Void,
        userLocalStore: any UserLocalStoreProtocol,
        conversationLocalStore: any ConversationLocalStoreProtocol,
        messageLocalStore: any MessageLocalStoreProtocol
    ) {
        self.eventsStream = eventsStream
        self.contentHandler = contentHandler
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
            return contentHandler(UNMutableNotificationContent())
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
                let notificationContent = try await notificationBuilder.buildContent()
                notifications.append(notificationContent)
            } catch {
                WireLogger.notifications.error(
                    "Failed to build notification: \(error.localizedDescription)"
                )
                notifications.append(UNMutableNotificationContent())
            }
        }
        
        showNotifications(notifications)
    }
    
    private func showNotifications(_ notifications: [UNMutableNotificationContent]) {
        var notification: UNMutableNotificationContent
        
        switch notifications.count {
        case 0:
            // Nothing to show
            notification = UNMutableNotificationContent()
        case 1:
            notification = notifications[0]
        default:
            notification = UNMutableNotificationContent()
            let body = NotificationBody.bundled(messagesCount: notifications.count)
            notification.body = body.make()
        }
        
        // Displays the notification to the user
        contentHandler(notification)
    }
}
