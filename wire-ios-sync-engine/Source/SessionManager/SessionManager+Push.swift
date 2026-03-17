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

import Foundation
import PushKit
import UserNotifications
import WireDomain
import WireLogging
import WireRequestStrategy

protocol PushRegistry {

    var delegate: PKPushRegistryDelegate? { get set }
    var desiredPushTypes: Set<PKPushType>? { get set }

    func pushToken(for type: PKPushType) -> Data?

}

extension PKPushRegistry: PushRegistry {}

// MARK: - UNUserNotificationCenterDelegate

private enum UserNotificationHandlingError: Error {
    case missingSelfID
    case missingAccount
}

/// **note**: `UNUserNotificationCenterDelegate` methods are annotated as `@MainActor`. This seems to be an undocumented
/// requirement. Without this annotation, the app may crash even with empty delegate method implementations.
@objc
extension SessionManager: UNUserNotificationCenterDelegate {

    // Called by the OS when the app receives a notification while in the
    // foreground.
    @MainActor
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // route to user session
        do {
            let userSession = try await loadSession(userInfo: notification.userInfo)
            return await userSession.userNotificationCenter(center, willPresent: notification)
        } catch let error as NSError {
            WireLogger.notifications.error(
                "Will present notification failed: \(error.safeForLoggingDescription)",
                attributes: .safePublic
            )
            return []
        }
    }

    // Called when the user engages a notification action.
    @MainActor
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        // Resume background task creation.
        BackgroundActivityFactory.shared.resume()
        // route to user session
        do {
            let userSession = try await loadSession(userInfo: response.notification.userInfo)
            await userSession.userNotificationCenter(center, didReceive: response)
        } catch let error as NSError {
            let errorString = error.safeForLoggingDescription
            let responseString = response.safeForLoggingDescription
            WireLogger.notifications.error(
                "Did receive notification response failed: \(errorString), response: \(responseString)",
                attributes: .safePublic
            )
        }
    }

    // MARK: Helpers

    public func configureUserNotifications() {
        guard (application as? NotificationSettingsRegistrable)?.shouldRegisterUserNotificationSettings ?? true
        else { return }
        let newSyncNotificationCategories = WireDomain.NotificationCategory.allCategories
        notificationCenter.setNotificationCategories(newSyncNotificationCategories)

        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { _, error in
            if let error {
                WireLogger.notifications.error("Failed to request authorization for user notifications: \(error)")
            }
        })
        notificationCenter.delegate = self
    }

    @MainActor
    func loadSession(userInfo: NotificationUserInfo) async throws -> ZMUserSession {
        guard let selfID = userInfo.selfUserID else {
            WireLogger.notifications.error("userInfo has no self ID")
            throw UserNotificationHandlingError.missingSelfID
        }
        guard let account = accountManager.account(with: selfID) else {
            throw UserNotificationHandlingError.missingAccount
        }

        return try await withSession(for: account)
    }

    fileprivate func activateAccount(for session: ZMUserSession, completion: @escaping () -> Void) {
        if session == activeUserSession {
            completion()
            return
        }

        var foundSession = false
        backgroundUserSessions.forEach { accountId, backgroundSession in
            if session == backgroundSession, let account = self.accountManager.account(with: accountId) {

                self.select(account, completion: { _ in
                    completion()
                })
                foundSession = true
                return
            }
        }

        if !foundSession {
            fatalError("User session \(session) is not present in backgroundSessions")
        }
    }
}

public extension SessionManager {

    func showConversation(
        _ conversation: ZMConversation,
        at message: ZMConversationMessage? = nil,
        in session: ZMUserSession
    ) {
        guard !conversation.isDeletedRemotely else {
            return
        }

        activateAccount(for: session) {
            self.presentationDelegate?.showConversation(conversation, at: message)
        }
    }

    func showConversationList(in session: ZMUserSession) {
        activateAccount(for: session) {
            self.presentationDelegate?.showConversationList()
        }
    }

    func showUserProfile(user: UserType) {
        presentationDelegate?.showUserProfile(user: user)
    }
}
