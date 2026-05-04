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
import UserNotifications
import WireDomain
import WireLogging
import WireRequestStrategy
import WireTransport

struct PushTokenMetadata {
    let isSandbox: Bool

    /// @brief There are 4 different application identifiers which map to each of the bundle id's used
    /// @discussion
    /// com.wearezeta.zclient.ios-development (dev) - <b>com.wire.dev.ent</b>
    ///
    /// com.wearezeta.zclient.ios-internal (internal) - <b>com.wire.int.ent</b>
    ///
    /// com.wearezeta.zclient-alpha - <b>com.wire.ent</b>
    ///
    /// com.wearezeta.zclient.ios (app store) - <b>com.wire</b>
    ///
    /// @sa https://github.com/zinfra/backend-wiki/wiki/Native-Push-Notifications

    let appIdentifier: String

    /// @brief There are 4 transport types which depend on the token type and the environment
    /// @discussion <b>APNS</b> -> ZMAPNSTypeNormal (deprecated)
    ///
    /// <b>APNS_VOIP</b> -> ZMAPNSTypeVoIP
    ///
    /// <b>APNS_SANDBOX</b> -> ZMAPNSTypeNormal + Sandbox environment (deprecated)
    ///
    /// <b>APNS_VOIP_SANDBOX</b> -> ZMAPNSTypeVoIP + Sandbox environment
    ///
    /// The non-VoIP types are deprecated at the moment.
    ///
    /// @sa https://github.com/zinfra/backend-wiki/wiki/Native-Push-Notifications

    var transportType: String {
        isSandbox ? "APNS_SANDBOX" : "APNS"
    }

    static func current() -> PushTokenMetadata {
        let appId = Bundle.main.bundleIdentifier ?? ""
        let buildType = BuildType(bundleID: appId)

        let isSandbox = ZMMobileProvisionParser().apsEnvironment == .sandbox
        let appIdentifier = buildType.certificateName

        return PushTokenMetadata(isSandbox: isSandbox, appIdentifier: appIdentifier)
    }
}

// MARK: - Register current push token

public extension ZMUserSession {

    @objc static let registerCurrentPushTokenNotificationName = Notification
        .Name(rawValue: "ZMUserSessionResetPushTokensNotification")

    func registerForRegisteringPushTokenNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ZMUserSession.registerCurrentPushToken),
            name: ZMUserSession.registerCurrentPushTokenNotificationName,
            object: nil
        )
    }

    internal func registerCurrentPushToken() {
        managedObjectContext.performGroupedBlock {
            self.sessionManager?.configurePushToken(session: self)
        }
    }

}

// MARK: - Register, delete and update push token

public extension ZMUserSession {

    /// Generates the local push token if needed, then syncs it with the backend.

    func validatePushToken() {
        sessionManager?.configurePushToken(session: self)
    }

}

// MARK: - UNUserNotificationCenterDelegate

// The `SessionManager` forwards `UNUserNotificationCenterDelegate` calls to a suitable `ZMUserSession` instance.
extension ZMUserSession {

    // Called by the SessionManager when a notification is received while the app
    // is in the foreground.
    @MainActor
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        WireLogger.notifications.info("Notification center wants to present in-app notification: \(notification)")
        let categoryIdentifier = notification.request.content.categoryIdentifier

        return await withCheckedContinuation { continuation in
            handleInAppNotification(
                with: notification.userInfo,
                categoryIdentifier: categoryIdentifier,
                completionHandler: { options in
                    continuation.resume(returning: options)
                }
            )
        }
    }

    // Called by the SessionManager when the user engages a notification action.
    @MainActor
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        WireLogger.notifications.info("Did receive notification response: \(response)")
        let userText = (response as? UNTextInputNotificationResponse)?.userText
        let note = response.notification

        await withCheckedContinuation { continuation in
            handleNotificationResponse(
                actionIdentifier: response.actionIdentifier,
                categoryIdentifier: note.request.content.categoryIdentifier,
                userInfo: note.userInfo,
                userText: userText,
                completionHandler: {
                    continuation.resume()
                }
            )
        }
    }

    // MARK: Abstractions

    // The logic for handling notifications/actions is factored out of the
    // delegate methods because we cannot create `UNNotification` and
    // `UNNotificationResponse` objects in unit tests.

    func handleInAppNotification(
        with userInfo: NotificationUserInfo,
        categoryIdentifier: String,
        completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // foreground notification responder exists on the UI context, so we
        // need to switch to that context
        managedObjectContext.perform {
            let responder = self.sessionManager?.foregroundNotificationResponder
            let shouldPresent = responder?.shouldPresentNotification(with: userInfo) ?? true

            var options = UNNotificationPresentationOptions()
            if shouldPresent { options = [.list, .banner, .sound] }

            completionHandler(options)
        }
    }

    func handleNotificationResponse(
        actionIdentifier: String,
        categoryIdentifier: String,
        userInfo: NotificationUserInfo,
        userText: String? = nil,
        completionHandler: @escaping () -> Void
    ) {
        WireLogger.notifications.info("handling notification response with action id (\(actionIdentifier))")

        switch actionIdentifier {
        case CallNotificationAction.ignore.rawValue, NotificationActionIdentifier.ignoreCallIdentifier:
            ignoreCall(with: userInfo, completionHandler: completionHandler)
        case CallNotificationAction.accept.rawValue:
            acceptCall(with: userInfo, completionHandler: completionHandler)
        case ConversationNotificationAction.mute.rawValue,
             NotificationActionIdentifier.muteConversationIdentifier:
            muteConversation(with: userInfo, completionHandler: completionHandler)
        case ConversationNotificationAction.like.rawValue:
            likeMessage(with: userInfo, completionHandler: completionHandler)
        case ConversationNotificationAction.reply.rawValue:
            if let textInput = userText {
                reply(with: userInfo, message: textInput, completionHandler: completionHandler)
            }
        case ConversationNotificationAction.connect.rawValue,
             NotificationActionIdentifier.acceptConnectionRequestIdentifier:
            acceptConnectionRequest(with: userInfo, completionHandler: completionHandler)
        // TODO: [WPB-17220] new NSE - callback action is currently broken - disabling this action for now
//        case NotificationActionIdentifier.callbackIdentifier:
//            callback(with: userInfo, completionHandler: completionHandler)
        default:
            showContent(for: userInfo)
            completionHandler()
        }

    }

}

extension UNNotificationContent {
    open override var description: String {
        "<\(type(of: self)); threadIdentifier: \(threadIdentifier); content: redacted>"
    }
}

public extension PushToken {
    init(deviceToken: Data) {
        let metadata = PushTokenMetadata.current()
        self.init(
            deviceToken: deviceToken,
            appIdentifier: metadata.appIdentifier,
            transportType: metadata.transportType
        )
    }

    static func createAPNSToken(from deviceToken: Data) -> PushToken {
        PushToken(deviceToken: deviceToken)
    }
}
