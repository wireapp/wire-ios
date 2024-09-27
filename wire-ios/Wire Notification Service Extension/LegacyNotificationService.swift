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

import CallKit
import UIKit
import UserNotifications
import WireCommonComponents
import WireDataModel
import WireNotificationEngine
import WireRequestStrategy
import WireSyncEngine
import WireUtilities

// MARK: - CallEventHandlerProtocol

protocol CallEventHandlerProtocol {
    func reportIncomingVoIPCall(_ payload: [String: Any])
}

// MARK: - CallEventHandler

final class CallEventHandler: CallEventHandlerProtocol {
    func reportIncomingVoIPCall(_ payload: [String: Any]) {
        WireLogger.calling.info("waking up main app to handle call event")
        CXProvider.reportNewIncomingVoIPPushPayload(payload) { error in
            if let error {
                WireLogger.calling.error("failed to wake up main app: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - LegacyNotificationService

final class LegacyNotificationService: UNNotificationServiceExtension, NotificationSessionDelegate {
    // MARK: Lifecycle

    override init() {
        WireLogger.notifications.info("initializing new legacy notification service")
        super.init()
    }

    // MARK: Internal

    // MARK: - Properties

    var callEventHandler: CallEventHandlerProtocol = CallEventHandler()

    // MARK: - Methods

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        WireLogger.notifications.info("legacy notification service will process request (\(request.identifier))")

        self.contentHandler = contentHandler

        guard let accountID = request.content.accountID else {
            WireLogger.notifications.error("failed to process request: payload missing account ID")
            return finishWithoutShowingNotification()
        }

        do {
            session = try createSession(accountID: accountID)
        } catch {
            WireLogger.notifications
                .error("failed to process process request: could not create session: \(error.localizedDescription)")
            return finishWithoutShowingNotification()
        }

        session?.processPushNotification(with: request.content.userInfo)
    }

    override func serviceExtensionTimeWillExpire() {
        WireLogger.notifications.warn("legacy service extension will expire")
        finishWithoutShowingNotification()
    }

    func notificationSessionDidGenerateNotification(
        _ notification: ZMLocalNotification?,
        unreadConversationCount: Int
    ) {
        guard let notification else {
            WireLogger.notifications.info("session did not generate a notification")
            return finishWithoutShowingNotification()
        }

        removeNotification(withSameMessageId: notification.messageNonce)

        WireLogger.notifications.info("session did generate a notification")

        defer { tearDown() }

        guard let contentHandler else { return }

        guard let content = notification.content as? UNMutableNotificationContent else {
            WireLogger.notifications.error("generated notification is not mutable")
            return finishWithoutShowingNotification()
        }

        content.interruptionLevel = .timeSensitive

        if let badgeCount = totalUnreadCount(unreadConversationCount) {
            WireLogger.notifications.info("setting badge count to \(badgeCount.intValue)")
            content.badge = badgeCount
        }

        WireLogger.notifications.info("showing notification to user")
        contentHandler(content)
    }

    func reportCallEvent(
        _ callEvent: CallEventPayload,
        currentTimestamp: TimeInterval
    ) {
        callEventHandler.reportIncomingVoIPCall([
            "accountID": callEvent.accountID,
            "conversationID": callEvent.conversationID,
            "shouldRing": callEvent.shouldRing,
            "callerName": callEvent.callerName,
            "hasVideo": callEvent.hasVideo,
        ])
    }

    func notificationSessionDidFailWithError(error: NotificationSessionError) {
        switch error {
        case .alreadyFetchedEvent:
            WireLogger.notifications.warn("session failed with error: \(error.localizedDescription)")
        default:
            WireLogger.notifications.error("session failed with error: \(error.localizedDescription)")
        }

        finishWithoutShowingNotification()
    }

    // MARK: Private

    private var session: NotificationSession?
    private var contentHandler: ((UNNotificationContent) -> Void)?

    private lazy var accountManager: AccountManager = {
        let sharedContainerURL = FileManager.sharedContainerDirectory(for: appGroupID)
        return AccountManager(sharedDirectory: sharedContainerURL)
    }()

    private var appGroupID: String {
        guard let groupID = Bundle.main.applicationGroupIdentifier else {
            fatalError("cannot get app group identifier")
        }

        return groupID
    }

    private func finishWithoutShowingNotification() {
        WireLogger.notifications.info("finishing without showing notification")
        contentHandler?(.empty)
        tearDown()
    }

    private func removeNotification(withSameMessageId messageNonce: UUID?) {
        guard let messageNonce else { return }

        let notificationCenter = UNUserNotificationCenter.current()

        notificationCenter.getDeliveredNotifications { notifications in
            let matched = notifications.first(where: { $0.userInfo.messageNonce == messageNonce })
            if let id = matched?.request.identifier {
                notificationCenter.removeDeliveredNotifications(withIdentifiers: [id])
            }
        }
    }

    // MARK: - Helpers

    private func tearDown() {
        // Content and handler should only be consumed once.
        contentHandler = nil

        // Let the session deinit so it can tear down.
        session = nil
    }

    private func createSession(accountID: UUID) throws -> NotificationSession {
        let session = try NotificationSession(
            applicationGroupIdentifier: appGroupID,
            accountIdentifier: accountID,
            environment: BackendEnvironment.shared,
            analytics: nil,
            sharedUserDefaults: .applicationGroup,
            minTLSVersion: SecurityFlags.minTLSVersion.stringValue
        )

        session.delegate = self
        return session
    }

    private func totalUnreadCount(_ unreadConversationCount: Int) -> NSNumber? {
        guard let session else {
            return nil
        }
        let account = accountManager.account(with: session.accountIdentifier)
        account?.unreadConversationCount = unreadConversationCount
        let totalUnreadCount = accountManager.totalUnreadCount

        return NSNumber(value: totalUnreadCount)
    }
}

// MARK: - Extensions

extension UNNotificationContent {
    // With the "filtering" entitlement, we can tell iOS to not display a user notification by
    // passing empty content to the content handler.
    // See https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_developer_usernotifications_filtering

    static var empty: Self {
        Self()
    }

    var accountID: UUID? {
        guard
            let data = userInfo["data"] as? [String: Any],
            let userIDString = data["user"] as? String,
            let userID = UUID(uuidString: userIDString)
        else {
            return nil
        }

        return userID
    }
}
