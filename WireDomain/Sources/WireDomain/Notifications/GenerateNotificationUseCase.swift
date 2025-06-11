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

    let conversationEventBuilder: any ConversationEventNotificationBuilderProtocol
    let userEventBuilder: any UserEventNotificationBuilderProtocol
    let databaseSaver: any DatabaseSaverProtocol
    let eventID: UUID

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

        // Ensures unread conversations count is up-to-date.
        try await databaseSaver.save()

        return notifications
    }

    private func generateNotification(
        for event: UpdateEvent
    ) async -> UserNotification? {
        switch event {
        case let .conversation(conversationEvent):
            do {
                return try await conversationEventBuilder.buildContent(
                    event: conversationEvent
                )
            } catch {
                var attributes = LogAttributes.newNSE
                attributes[.eventId] = eventID.safeForLoggingDescription

                WireLogger.notifications.error(
                    "An error occured when building the conversation notification content \(error)",
                    attributes: attributes
                )

                return nil
            }

        case let .user(userEvent):
            return await userEventBuilder.buildContent(
                event: userEvent
            )

        default:
            return nil
        }
    }
}
