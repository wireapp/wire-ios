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

import NeedleFoundation
import UserNotifications
import WireDataModel
import WireLogging

/// Receives push notifications, process the pending events through the `NotificationSession` to generate a notification
/// content based on these events.
public final class NotificationServiceExtension: NotificationServiceProtocol {

    // MARK: - Properties

    private let logger = WireLogger.notifications
    private var onGoingtask: Task<Void, Never>?

    public init() {
        registerProviderFactories()
        logger.info("initializing new notification service", attributes: .newNSE)
    }

    // MARK: - Notifications

    public func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {

        if onGoingtask != nil {
            logger.warn(
                "onGoingtask not null: a notification is already being processed",
                attributes: .newNSE
            )
        }

        let notificationContentHandler: (UNNotificationContent) -> Void = { [weak self] in
            contentHandler($0) // Finishes current notification flow by calling system built-in handler.
            self?.onGoingtask = nil // Current notification flow was completed, nil out the task.
        }

        onGoingtask = Task {

            guard !Task.isCancelled else {
                // With the "filtering" entitlement, we can tell iOS to not display a user notification by passing empty
                // content to the content handler. See https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_developer_usernotifications_filtering
                return notificationContentHandler(.emptyNotification)
            }

            do {
                let rootComponent = try NotificationServiceExtensionFlow(
                    contentHandler: notificationContentHandler
                )

                try await rootComponent.start(request: request)

            } catch {
                logError(error)
                notificationContentHandler(.emptyNotification)
            }
        }
    }

    public func serviceExtensionTimeWillExpire() {
        logger.warn("new notification service will expire", attributes: .newNSE)
        onGoingtask?.cancel()
    }
}

// MARK: - Error logger

extension NotificationServiceExtension {
    private func logError(_ error: any Error) {
        switch error {
        case let verifyUserSessionError as VerifyUserSessionUseCase.Failure:
            switch verifyUserSessionError {
            case .userUnauthenticated:
                WireLogger.notifications.error(
                    "Not displaying notification because app is not authenticated",
                    attributes: .newNSE
                )
            case .coreDataMissingSharedContainer:
                WireLogger.notifications.error(
                    "Core data missing shared container",
                    attributes: .newNSE
                )
            case .coreDataMigrationRequired:
                WireLogger.notifications.error(
                    "Core data migration required",
                    attributes: .newNSE
                )
            case .unableToLoadStores:
                WireLogger.notifications.error(
                    "Loading coreDataStack with error",
                    attributes: .newNSE
                )
            }
        case let pullEventsServiceError as PullEventsUseCase.Failure:
            switch pullEventsServiceError {
            case let .unableToPullPendingEvents(error):
                logger.error(
                    "failed to process notification: could not pull pending events: \(error.localizedDescription)",
                    attributes: .newNSE
                )
            }
        case let notificationServiceError as NotificationServiceExtensionFlow.Failure:
            switch notificationServiceError {
            case .missingAppGroupID:
                logger.error(
                    "failed to process notification: missing app group id",
                    attributes: .newNSE
                )
            }
        case let verifyUserError as VerifyUserStep.Failure:
            switch verifyUserError {
            case .noAccountFound:
                logger.error(
                    "failed to process notification: no selected account found",
                    attributes: .newNSE
                )
            }
        default:
            logger.error(
                "Unable to create a session: \(error.localizedDescription)",
                attributes: .newNSE
            )
        }
    }
}
