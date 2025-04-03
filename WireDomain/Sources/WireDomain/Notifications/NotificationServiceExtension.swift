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

    enum Failure: Error {
        case noAccountFound
    }

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

                let userInfo = request.content.userInfo
                let data = try JSONSerialization.data(
                    withJSONObject: userInfo
                )
                let notificationPayload = try JSONDecoder().decode(
                    NotificationPayload.self,
                    from: data
                )

                let userID = notificationPayload.userID

                let rootComponent = try setupRootComponent(
                    userID: userID,
                    notificationHandler: contentHandler
                )

                let verifyUserSession = rootComponent.verifyUserSession
                let startSyncingEvents: () async throws -> Void = {
                    try await verifyUserSession.startSyncingEvents(
                        eventID: notificationPayload.eventID
                    )
                }

                try await verifyUserSession.verify(
                    userID: userID,
                    then: startSyncingEvents
                )

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

    private func setupRootComponent(
        userID: UUID,
        notificationHandler: @escaping (UNNotificationContent) -> Void
    ) throws -> RootComponent {
        let infoDictionary = Bundle.main.infoDictionary
        guard let appGroupID = infoDictionary?["WireGroupId"] as? String else {
            fatalError()
        }

        let applicationIdentifier = "group.\(appGroupID)"
        let applicationContainer = FileManager.sharedContainerDirectory(
            for: applicationIdentifier
        )

        let accountManager = AccountManager(
            sharedDirectory: applicationContainer
        )

        guard let selectedAccount = accountManager.account(
            with: userID
        ) else {
            throw Failure.noAccountFound
        }

        return RootComponent(
            accountManager: accountManager,
            userID: userID,
            applicationIdentifier: applicationIdentifier,
            applicationContainer: applicationContainer,
            selectedAccount: selectedAccount,
            contentHandler: notificationHandler
        )
    }
}

// MARK: - Error logger

extension NotificationServiceExtension {
    private func logError(_ error: any Error) {
        switch error {
        case let verifyUserSessionError as VerifyUserSession.Failure:
            switch verifyUserSessionError {
            case .userUnauthenticated:
                WireLogger.notifications.error(
                    "Not displaying notification because app is not authenticated",
                    attributes: .newNSE
                )
            case .missingUserClient:
                WireLogger.notifications.error(
                    "Not displaying notification because user client is missing",
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
        case let pullEventsServiceError as PullEventsService.Failure:
            switch pullEventsServiceError {
            case let .unableToPullPendingEvents(error):
                logger.error(
                    "failed to process notification: could not pull pending events: \(error.localizedDescription)",
                    attributes: .newNSE
                )
            }
        case let serviceSetupError as NotificationServiceExtension.Failure:
            switch serviceSetupError {
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
