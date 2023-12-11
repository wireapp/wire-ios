//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

import UIKit
import UserNotifications
import WireRequestStrategy
import WireNotificationEngine
import WireCommonComponents
import WireDataModel
import WireSyncEngine
import WireUtilities

final class LegacyNotificationService: UNNotificationServiceExtension, NotificationSessionDelegate {

    // MARK: - Properties

    var callEventHandler: CallEventHandlerProtocol = CallEventHandler()

    private var session: NotificationSession?
    private var contentHandler: ((UNNotificationContent) -> Void)?

    private lazy var accountManager: AccountManager = {
        let sharedContainerURL = FileManager.sharedContainerDirectory(for: appGroupID)
        let account = AccountManager(sharedDirectory: sharedContainerURL)
        return account
    }()

    private var appGroupID: String {
        guard let groupID = Bundle.main.applicationGroupIdentifier else {
            fatalError("cannot get app group identifier")
        }

        return groupID
    }

    // MARK: - Life cycle

    override init() {
        WireLogger.notifications.info("initializing new legacy notification service")
        super.init()
    }

    // MARK: - Methods

    public override func didReceive(
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
            session = try createSession(accountIdentifier: accountID)
        } catch {
            WireLogger.notifications.error("failed to process process request: could not create session: \(error.localizedDescription)")
            return finishWithoutShowingNotification()
        }

        session?.processPushNotification(with: request.content.userInfo)
    }

    public override func serviceExtensionTimeWillExpire() {
        WireLogger.notifications.warn("legacy service extension will expire")
        finishWithoutShowingNotification()
    }

    private func finishWithoutShowingNotification() {
        WireLogger.notifications.info("finishing without showing notification")
        contentHandler?(.empty)
        tearDown()
    }

    public func notificationSessionDidGenerateNotification(
        _ notification: ZMLocalNotification?,
        unreadConversationCount: Int
    ) {
        guard let notification = notification else {
            WireLogger.notifications.info("session did not generate a notification")
            return finishWithoutShowingNotification()
        }

        WireLogger.notifications.info("session did generate a notification")

        defer { tearDown() }

        guard let contentHandler = contentHandler else { return }

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

    public func reportCallEvent(
        _ callEvent: CallEventPayload,
        currentTimestamp: TimeInterval
    ) {
        callEventHandler.reportIncomingVoIPCall([
            "accountID": callEvent.accountID,
            "conversationID": callEvent.conversationID,
            "shouldRing": callEvent.shouldRing,
            "callerName": callEvent.callerName,
            "hasVideo": callEvent.hasVideo
        ])
    }

    public func notificationSessionDidFailWithError(error: NotificationSessionError) {
        WireLogger.notifications.error("session failed with error: \(error.localizedDescription)")
        finishWithoutShowingNotification()
    }

    // MARK: - Helpers

    private func tearDown() {
        // Content and handler should only be consumed once.
        contentHandler = nil

        // Let the session deinit so it can tear down.
        session = nil
    }

    private func createSession(accountIdentifier: UUID) throws -> NotificationSession {
        let coreDataStack = try createCoreDataStack(applicationGroupIdentifier: appGroupID, accountIdentifier: accountIdentifier)
        try setUpCoreCryptoStack(
            accountContainer: coreDataStack.accountContainer,
            applicationContainer: coreDataStack.applicationContainer,
            syncContext: coreDataStack.syncContext,
            cryptoboxMigrationManager: CryptoboxMigrationManager()
        )

        let session = NotificationSession(
            applicationGroupIdentifier: appGroupID,
            accountIdentifier: accountIdentifier,
            coreDataStack: coreDataStack,
            environment: BackendEnvironment.shared,
            analytics: nil,
            sharedUserDefaults: .applicationGroup,
            minTLSVersion: SecurityFlags.minTLSVersion.stringValue
        )

        session.delegate = self
        return session
    }

    private func totalUnreadCount(_ unreadConversationCount: Int) -> NSNumber? {
        guard let session = session else {
            return nil
        }
        let account = self.accountManager.account(with: session.accountIdentifier)
        account?.unreadConversationCount = unreadConversationCount
        let totalUnreadCount = self.accountManager.totalUnreadCount

        return NSNumber(value: totalUnreadCount)
    }

}

// MARK: - Extensions

private extension UNNotificationContent {
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
