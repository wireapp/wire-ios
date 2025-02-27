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
import WireDataModel
import WireLogging

/// Receives push notifications, process the pending events through the `NotificationSession` to generate a notification
/// content based on these events.
final class NotificationServiceExtension: UNNotificationServiceExtension {

    // MARK: - Properties

    private let logger = WireLogger.notifications
    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var onGoingTask: Task<Void, Never>?

    // MARK: - Object lifecycle

    override init() {
        logger.info("initializing notification service")
        super.init()
    }

    // MARK: - Notifications

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        onGoingTask?.cancel()
        self.contentHandler = contentHandler

        onGoingTask = Task {
            do {
                let notificationPayload = try NotificationPayload(
                    userInfo: request.content.userInfo
                )
                
                let userID = notificationPayload.userID
                let eventID = notificationPayload.eventID
                
                let rootComponent = RootComponent(
                    userID: userID,
                    contentHandler: contentHandler
                )
                
                let verifyUserSession = rootComponent.verifyUserSession
                let startSyncingEvents: () async throws -> Void = {
                    try await verifyUserSession.startSyncingEvents(eventID: eventID)
                }
                
                try await verifyUserSession.verify(
                    userID: userID,
                    then: startSyncingEvents
                )
                
            } catch {
                logError(error)
                finishWithEmptyNotification()
            }
        }
    }

    override func serviceExtensionTimeWillExpire() {
        logger.warn("legacy service extension will expire")
        finishWithEmptyNotification()
    }
    
    // With the "filtering" entitlement, we can tell iOS to not display a user notification by passing empty content to the content handler. See https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_developer_usernotifications_filtering
    private func finishWithEmptyNotification() {
        logger.info("finishing without showing notification")
        let emptyNotification = UNNotificationContent()
        contentHandler?(emptyNotification)
        terminate()
    }

    private func terminate() {
        // Content handler should only be consumed once.
        contentHandler = nil
        onGoingTask = nil
    }
}

// MARK: - Error logger

extension NotificationServiceExtension {
    private func logError(_ error: any Error) {
        switch error {
        case let payloadError as NotificationPayload.Failure:
            switch payloadError {
            case .missingUserID:
                logger.error(
                    "failed to decode notification payload: missing user ID"
                )
            case .missingEventID:
                logger.error(
                    "failed to decode notification payload: missing event ID"
                )
            }
        case let verifyUserSessionError as VerifyUserSession.Failure:
            switch verifyUserSessionError {
            case .userUnauthenticated:
                WireLogger.notifications.error(
                    "Not displaying notification because app is not authenticated"
                )
            case .missingUserClient:
                WireLogger.notifications.error(
                    "Not displaying notification because user client is missing"
                )
            }
        case let pullEventsServiceError as PullEventsService.Failure:
            switch pullEventsServiceError {
            case let .unableToLoadStores(error):
                WireLogger.notifications.error(
                    "Loading coreDataStack with error: \(error.localizedDescription)"
                )
            case let .unableToPullPendingEvents(error):
                logger.error(
                    "failed to process notification: could not pull pending events: \(error.localizedDescription)"
                )
            }
        default:
            logger.error(
                "Unable to create a session: \(error.localizedDescription)"
            )
        }
    }
}
