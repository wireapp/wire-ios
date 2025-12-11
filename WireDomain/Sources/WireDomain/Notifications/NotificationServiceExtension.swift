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

/// Receives and process a push notification through a flow of several steps:
/// 1. Process push notification request (`ProcessNotificationRequestStep`)
/// 2. Verify user session (`VerifyUserStep`)
/// 3. Pull pending update events (`PullEventsStep`)
/// 4. Generate notification content (`GenerateNotificationStep`)
/// 5. Show notification to the user (`ShowNotificationStep`)
///
/// These sequential steps represents the NSE dependency graph (using Needle).

public final class NotificationServiceExtension: NotificationServiceProtocol {

    // MARK: - Properties

    private let logger = WireLogger.notifications
    private var onGoingTask: Task<Void, Never>?

    private let currentAppVersion: String
    private let currentBuildNumber: String
    private let appContainerURL: URL
    private let sharedUserDefaults: UserDefaults
    private let cookieEncryptionKey: Data
    private let minTLSVersion: String?
    private let preferredAPIVersion: UInt?

    public init(
        currentAppVersion: String,
        currentBuildNumber: String,
        appContainerURL: URL,
        sharedUserDefaults: UserDefaults,
        cookieEncryptionKey: Data,
        minTLSVersion: String?,
        preferredAPIVersion: UInt?
    ) {
        self.currentAppVersion = currentAppVersion
        self.currentBuildNumber = currentBuildNumber
        self.appContainerURL = appContainerURL
        self.sharedUserDefaults = sharedUserDefaults
        self.cookieEncryptionKey = cookieEncryptionKey
        self.minTLSVersion = minTLSVersion
        self.preferredAPIVersion = preferredAPIVersion
        registerProviderFactories()
        logger.info("initializing new notification service", attributes: .newNSE, .safePublic)
    }

    // MARK: - Notifications

    public func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {

        if onGoingTask != nil {
            logger.warn(
                "onGoingtask not null: a notification is already being processed",
                attributes: .newNSE, .safePublic
            )
        }

        let notificationContentHandler: (UNNotificationContent) -> Void = { [weak self] in
            contentHandler($0) // Finishes current notification flow by calling system built-in handler.
            self?.onGoingTask = nil // Current notification flow was completed, nil out the task.
        }

        onGoingTask = Task {
            do {
                try Task.checkCancellation()
            } catch {
                // With the "filtering" entitlement, we can tell iOS to not display a user notification by passing empty
                // content to the content handler. See https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_developer_usernotifications_filtering
                logger.warn("onGoingtask got cancelled: showing no notifications", attributes: .newNSE, .safePublic)
                return notificationContentHandler(.emptyNotification)
            }

            do {
                let nseFlow = try NSEFlow(
                    currentAppVersion: currentAppVersion,
                    currentBuildNumber: currentBuildNumber,
                    appContainerURL: appContainerURL,
                    sharedUserDefaults: sharedUserDefaults,
                    cookieEncryptionKey: cookieEncryptionKey,
                    minTLSVersion: minTLSVersion,
                    preferredAPIVersion: preferredAPIVersion
                )

                try await nseFlow.start(
                    request: request,
                    contentHandler: notificationContentHandler
                )
            } catch {
                // TODO: [WPB-19762] show errors
                logError(error)
                notificationContentHandler(.emptyNotification)
            }
        }
    }

    public func serviceExtensionTimeWillExpire() {
        logger.warn("new notification service will expire", attributes: .newNSE, .safePublic)
        onGoingTask?.cancel()
    }
}

// MARK: - Error logger

extension NotificationServiceExtension {
    private func logError(_ error: any Error) {
        switch error {
        case let verifyUserSessionUseCaseError as VerifyUserSessionUseCase.Failure:
            logVerifyUserSessionUseCaseError(verifyUserSessionUseCaseError)
        case let pullEventsUseCaseError as PullEventsUseCase.Failure:
            logPullEventsUseCaseError(pullEventsUseCaseError)
        case let nseFlowError as NSEFlow.Failure:
            logFlowError(nseFlowError)
        case let nseUserError as NSEUserScope.Failure:
            logUserError(nseUserError)
        case let pullEventsStepError as NSEClientScope.Failure:
            logClientError(pullEventsStepError)
        default:
            logDefaultError(error)
        }
    }

    private func logVerifyUserSessionUseCaseError(_ error: VerifyUserSessionUseCase.Failure) {
        switch error {
        case .syncV2IsNotEnabled:
            logger.error(
                "Not displaying notification because sync v2 is not enabled yet",
                attributes: .newNSE, .safePublic
            )
        case .userUnauthenticated:
            logger.error(
                "Not displaying notification because app is not authenticated",
                attributes: .newNSE, .safePublic
            )
        case .coreDataMissingSharedContainer:
            logger.error(
                "Core data missing shared container",
                attributes: .newNSE, .safePublic
            )
        case .coreDataMigrationRequired:
            logger.error(
                "Core data migration required",
                attributes: .newNSE, .safePublic
            )
        case let .unableToLoadStores(loadStoresError):
            logger.error(
                "Loading coreDataStack with error: \(String(describing: loadStoresError))",
                attributes: .newNSE, .safePublic
            )
        }
    }

    private func logPullEventsUseCaseError(_ error: PullEventsUseCase.Failure) {
        switch error {
        case let .unableToPullPendingEvents(error):
            logger.error(
                "Could not pull pending events: \(String(describing: error))",
                attributes: .newNSE, .safePublic
            )
        }
    }

    private func logUserError(_ error: NSEUserScope.Failure) {
        switch error {
        case let .mainAppRequired(message):
            logger.error(
                "Main app required, need to open main app: \(String(describing: error))",
                attributes: .newNSE, .safePublic
            )
        case let .failedToFetchBackendEnvironment(error):
            logger.error(
                "Failed to fetch backend environment: \(String(describing: error))",
                attributes: .newNSE, .safePublic
            )
        case let .failedToFetchProxyCredentials(error):
            logger.error(
                "Failed to fetch proxy credentials: \(String(describing: error))",
                attributes: .newNSE, .safePublic
            )
        case let .failedToStoreMetadata(error):
            logger.error(
                "Failed to store metadata: \(String(describing: error))",
                attributes: .newNSE, .safePublic
            )
        case .persistenceStoresNotFound:
            logger.error(
                "Persistence stores not found",
                attributes: .newNSE, .safePublic
            )
        case let .failedToLoadPersistenceStack(error):
            logger.error(
                "Failed to load persistence stack: \(String(describing: error))",
                attributes: .newNSE, .safePublic
            )
        case let .failedToFetchCookies(error):
            logger.error(
                "Failed to fetch cookies: \(String(describing: error))",
                attributes: .newNSE, .safePublic
            )
        case .userNotAuthenticated:
            logger.error(
                "Use not authenticated",
                attributes: .newNSE, .safePublic
            )
        case let .buildIsBlacklisted(buildNumber):
            logger.error(
                "Build is blacklisted: \(buildNumber)",
                attributes: .newNSE, .safePublic
            )
        }
    }

    private func logFlowError(_ error: NSEFlow.Failure) {
        switch error {
        case let .accountNotFound(accountID):
            logger.error(
                "Account not found, id: \(accountID)",
                attributes: .newNSE, .safePublic
            )
        }
    }

    private func logClientError(_ error: NSEClientScope.Failure) {
        switch error {
        case .pushChannelAlreadyOpened:
            logger.error(
                "Main app is running in foreground with push channel open",
                attributes: .newNSE
            )
        }
    }

    private func logDefaultError(_ error: any Error) {
        logger.error(
            "Unable to create a session: \(String(describing: error))",
            attributes: .newNSE, .safePublic
        )
    }
}
