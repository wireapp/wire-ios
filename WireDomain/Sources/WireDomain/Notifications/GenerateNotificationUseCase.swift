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
protocol GenerateNotificationUseCaseProtocol {
    func invoke(
        updateEvents: AsyncStream<[UpdateEvent]>
    ) async throws -> [UserNotification]
}

struct GenerateNotificationUseCase: GenerateNotificationUseCaseProtocol {

    private let conversationEventBuilder: ConversationEventNotificationBuilder
    private let userEventBuilder: UserNotificationBuilder

    init(
        conversationEventBuilder: ConversationEventNotificationBuilder,
        userEventBuilder: UserNotificationBuilder
    ) {
        self.conversationEventBuilder = conversationEventBuilder
        self.userEventBuilder = userEventBuilder
    }

    /// Processes the events stream.
    func invoke(updateEvents: AsyncStream<[UpdateEvent]>) async throws -> [UserNotification] {
         var notifications = [UserNotification]()
         
         for await events in updateEvents {
             for event in events {
                 if let notification = await generateNotification(for: event) {
                     notifications.append(notification)
                 }
             }
         }
         
         return notifications
     }
    
    private func generateNotification(
        for event: UpdateEvent
    ) async -> UserNotification? {
        switch event {
        case let .conversation(conversationEvent):
            // TODO: implement reusable builder
            //return conversationNotificationBuilder.buildContent(for: conversationEvent)
            return nil
            
        case let .user(userEvent):
            // TODO: implement reusable builder
            //return userNotificationBuilder.buildContent(for: userEvent)
            return nil
            
        default:
            return nil
        }
    }
}
