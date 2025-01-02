//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
final class NotificationService: UNNotificationServiceExtension {

    // MARK: - Failure

    enum Failure: Error {
        case missingSelfClientID
    }

    // MARK: - Properties

    private let logger = WireLogger.notifications
    private var notificationSession: NotificationSession?
    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var ongoingTask: Task<Void, Never>?

    // MARK: - Object lifecycle

    override init() {
        logger.info("initializing new legacy notification service")
        super.init()
    }

    // MARK: - Notifications

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        ongoingTask?.cancel()
        let cookieStorage: ZMPersistentCookieStorage = Injector.resolve()
        let isAuthenticated = cookieStorage.isAuthenticated

        guard isAuthenticated else {
            logger.error(
                "Not displaying notification because app is not authenticated"
            )

            return finishWithEmptyNotification()
        }

        self.contentHandler = contentHandler

        ongoingTask = Task {
            do {
                let notificationUserInfo = request.content.userInfo

                let notification = try NotificationPayload(
                    userInfo: notificationUserInfo
                )

                notificationSession = try await createNotificationSession(
                    userID: notification.userID
                )

                try await notificationSession?.processPushNotification(
                    eventID: notification.eventID
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

    private func createNotificationSession(
        userID: UUID
    ) async throws -> NotificationSession {
        let userLocalStore: UserLocalStoreProtocol = Injector.resolve()
        let selfUserInfo = await userLocalStore.selfUserInfo()

        guard let selfClientID = selfUserInfo.clientId else {
            throw Failure.missingSelfClientID
        }

        let updateEventsRepository = UpdateEventsRepository(
            userID: userID,
            selfClientID: selfClientID,
            // these dependencies were already initialized, resolving them
            updateEventsAPI: Injector.resolve(),
            pushChannel: Injector.resolve(),
            updateEventDecryptor: Injector.resolve(),
            updateEventsLocalStore: Injector.resolve()
        )

        return NotificationSession(
            updateEventsRepository: updateEventsRepository
        ) { [weak self] notificationContent in
            self?.finishWithNotification(content: notificationContent)
        }
    }

    private func finishWithNotification(content: UNNotificationContent) {
        contentHandler?(content)
    }

    private func finishWithEmptyNotification() {
        logger.info("finishing without showing notification")
        let emptyNotification = UNNotificationContent()
        contentHandler?(emptyNotification)
        terminate()
    }

    private func logError(_ error: any Error) {
        switch error {
        case let sessionError as NotificationSession.Failure:
            switch sessionError {
            case let .unableToPullPendingEvents(error):
                logger.error(
                    "failed to process notification: could not pull pending events: \(error.localizedDescription)"
                )
            }

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

        case let serviceError as NotificationService.Failure:
            switch serviceError {
            case .missingSelfClientID:
                logger.error(
                    "failed to create notification session: missing self client ID"
                )
            }

        default:
            logger.error(
                "failed to process notification: \(error.localizedDescription)"
            )
        }
    }

    private func terminate() {
        // Content handler should only be consumed once.
        contentHandler = nil
        notificationSession = nil
        ongoingTask = nil
    }
}
