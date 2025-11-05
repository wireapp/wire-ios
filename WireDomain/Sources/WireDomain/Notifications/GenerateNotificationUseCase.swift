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

        var notifications = [UserNotification]()

        for await events in updateEvents {
            logger.info(
                "Processing \(events.count) pending events...",
                attributes: .newNSE, .safePublic
            )

            for event in events {
                logger.info(
                    "[CALLING-DEBUG] event: \(event)",
                    attributes: .newNSE, .safePublic
                )

                // DEBUG: Log calling-related events with more details
                if case let .conversation(conversationEvent) = event {
//                    logger.info(
//                        "[CALLING-DEBUG] Backend event received - conversationID:
//                        \(conversationEvent.conversationID.id.safeForLoggingDescription), senderID:
//                        \(conversationEvent.senderID.id.safeForLoggingDescription), type: \(String(describing:
//                        conversationEvent))",
//                        attributes: .newNSE, .safePublic
//                    )
                }

                if let notification = await generateNotification(for: event) {
                    logger.info(
                        "Generated a notification from an event",
                        attributes: .newNSE, .safePublic
                    )
                    notifications.append(notification)
                } else {
                    logger.info(
                        "[CALLING-DEBUG] No notification generated for event",
                        attributes: .newNSE, .safePublic
                    )
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
            do {
                return try await conversationEventBuilder.buildContent(
                    event: conversationEvent
                )
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
            return await userEventBuilder.buildContent(
                event: userEvent
            )

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
