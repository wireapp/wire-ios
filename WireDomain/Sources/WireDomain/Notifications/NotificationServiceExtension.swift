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
    private var onGoingTask: Task<Void, Never>?

    public init() {
        registerProviderFactories()
        logger.info("initializing new notification service", attributes: .newNSE)
    }

    // MARK: - Notifications

    public func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {

        onGoingTask = Task {
            guard !Task.isCancelled else {
                // With the "filtering" entitlement, we can tell iOS to not display a user notification by passing empty
                // content to
                // the content handler. See https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_developer_usernotifications_filtering
                return contentHandler(.emptyNotification)
            }

            do {

                let rootComponent = try NotificationServiceExtensionFlow(
                    contentHandler: contentHandler
                )

                try await rootComponent.start(request: request)

            } catch {
                logError(error)
                contentHandler(.emptyNotification)
            }
        }
    }

    public func serviceExtensionTimeWillExpire() {
        logger.warn("new notification service will expire", attributes: .newNSE)
        onGoingTask?.cancel()
        onGoingTask = nil
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
