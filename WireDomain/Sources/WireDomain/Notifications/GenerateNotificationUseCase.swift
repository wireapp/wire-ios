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

import CallKit
import UserNotifications
import WireDataModel
import WireLogging
import WireNetwork

// sourcery: AutoMockable
protocol GenerateNotificationUseCaseProtocol {
    func invoke(
        updateEvents: AsyncStream<[UpdateEvent]>
    ) async throws -> [UserNotification]
}

struct GenerateNotificationUseCase: GenerateNotificationUseCaseProtocol {

    private let conversationEventBuilder: any ConversationEventNotificationBuilderProtocol
    private let userEventBuilder: any UserEventNotificationBuilderProtocol
    private let eventID: UUID
    private let logger = WireLogger.notifications

    init(
        conversationEventBuilder: any ConversationEventNotificationBuilderProtocol,
        userEventBuilder: any UserEventNotificationBuilderProtocol,
        eventID: UUID
    ) {
        self.conversationEventBuilder = conversationEventBuilder
        self.userEventBuilder = userEventBuilder
        self.eventID = eventID
    }

    /// Processes the events stream.
    func invoke(
        updateEvents: AsyncStream<[UpdateEvent]>
    ) async throws -> [UserNotification] {

        var allNotifications = [UserNotification]()

        for await events in updateEvents {
            logger.info(
                "Processing \(events.count) pending events...",
                attributes: .newNSE, .safePublic
            )

            for event in events {
                if let notifications = await generateNotification(for: event) {
                    logger.info(
                        "Generated \(notifications.count) notifications from an event",
                        attributes: .newNSE, .safePublic
                    )
                    allNotifications.append(contentsOf: notifications)
                }
            }
        }

        return allNotifications
    }

    private func generateNotification(
        for event: UpdateEvent
    ) async -> [UserNotification]? {
        switch event {
        case let .conversation(conversationEvent):
            do {
                return try await conversationEventBuilder.buildContent(
                    event: conversationEvent
                )
            } catch ProtobufMessageDecoder.Failure.unknownMessageContent {
                // Can't show notifications for unknown message types,
                // so just ignore.
                return nil
            } catch {
                var attributes = LogAttributes.newNSE + .safePublic
                attributes[.eventId] = eventID.safeForLoggingDescription

                logger.error(
                    "Failed generating notification: \(String(describing: error))",
                    attributes: attributes
                )

                return nil
            }

        case let .user(userEvent):
            let notification = await userEventBuilder.buildContent(
                event: userEvent
            )
            return notification.flatMap { [$0] }

        default:
            var attributes = LogAttributes.newNSE
            attributes[.eventId] = eventID.safeForLoggingDescription

            logger.info(
                "Ignoring event",
                attributes: attributes
            )

            return nil
        }
    }
}
