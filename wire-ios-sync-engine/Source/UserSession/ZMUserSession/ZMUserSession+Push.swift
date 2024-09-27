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

import Foundation
import UserNotifications
import WireRequestStrategy
import WireTransport

// MARK: - PushTokenMetadata

struct PushTokenMetadata {
    let isSandbox: Bool

    /// !
    // @brief There are 4 different application identifiers which map to each of the bundle id's used
    // @discussion
    // com.wearezeta.zclient.ios-development (dev) - <b>com.wire.dev.ent</b>
    //
    // com.wearezeta.zclient.ios-internal (internal) - <b>com.wire.int.ent</b>
    //
    // com.wearezeta.zclient-alpha - <b>com.wire.ent</b>
    //
    // com.wearezeta.zclient.ios (app store) - <b>com.wire</b>
    //
    // @sa https://github.com/zinfra/backend-wiki/wiki/Native-Push-Notifications
    let appIdentifier: String

    /// !
    // @brief There are 4 transport types which depend on the token type and the environment
    // @discussion <b>APNS</b> -> ZMAPNSTypeNormal (deprecated)
    //
    // <b>APNS_VOIP</b> -> ZMAPNSTypeVoIP
    //
    // <b>APNS_SANDBOX</b> -> ZMAPNSTypeNormal + Sandbox environment (deprecated)
    //
    // <b>APNS_VOIP_SANDBOX</b> -> ZMAPNSTypeVoIP + Sandbox environment
    //
    // The non-VoIP types are deprecated at the moment.
    //
    // @sa https://github.com/zinfra/backend-wiki/wiki/Native-Push-Notifications

    var tokenType: PushToken.TokenType

    var transportType: String {
        isSandbox ? (tokenType.transportType + "_SANDBOX") : tokenType.transportType
    }

    static func current(for tokenType: PushToken.TokenType) -> PushTokenMetadata {
        let appId = Bundle.main.bundleIdentifier ?? ""
        let buildType = BuildType(bundleID: appId)

        let isSandbox = ZMMobileProvisionParser().apsEnvironment == .sandbox
        let appIdentifier = buildType.certificateName

        return PushTokenMetadata(isSandbox: isSandbox, appIdentifier: appIdentifier, tokenType: tokenType)
    }
}

// MARK: - Register current push token

extension ZMUserSession {
    @objc public static let registerCurrentPushTokenNotificationName = Notification
        .Name(rawValue: "ZMUserSessionResetPushTokensNotification")

    public func registerForRegisteringPushTokenNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ZMUserSession.registerCurrentPushToken),
            name: ZMUserSession.registerCurrentPushTokenNotificationName,
            object: nil
        )
    }

    func registerCurrentPushToken() {
        managedObjectContext.performGroupedBlock {
            self.sessionManager?.configurePushToken(session: self)
        }
    }
}

// MARK: - Register, delete and update push token

extension ZMUserSession {
    /// Generates the local push token if needed, then syncs it with the backend.

    public func validatePushToken() {
        sessionManager?.configurePushToken(session: self)
    }
}

extension ZMUserSession {
    public func receivedPushNotification(with payload: [AnyHashable: Any], completion: @escaping () -> Void) {
        WireLogger.notifications.debug("Received push notification with payload: \(payload)")

        syncManagedObjectContext.performGroupedBlock {
            let notAuthenticated = !self.isAuthenticated

            if notAuthenticated {
                WireLogger.notifications.info(
                    "Not displaying notification because app is not authenticated",
                    attributes: .safePublic
                )
                completion()
                return
            }

            self.operationLoop?.fetchEvents(fromPushChannelPayload: payload, completionHandler: completion)
        }
    }
}

// MARK: - ZMUserSession + UNUserNotificationCenterDelegate

// Note: Although ZMUserSession conforms to UNUserNotificationCenterDelegate,
// it should not actually be assigned as the delegate of UNUserNotificationCenter.
// Instead, the delegate should be the SessionManager, whose repsonsibility it is
// to forward the method calls to the appropriate user session.
extension ZMUserSession: UNUserNotificationCenterDelegate {
    // Called by the SessionManager when a notification is received while the app
    // is in the foreground.
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions)
            -> Void
    ) {
        Logging.push.safePublic("Notification center wants to present in-app notification: \(notification)")
        let categoryIdentifier = notification.request.content.categoryIdentifier

        handleInAppNotification(
            with: notification.userInfo,
            categoryIdentifier: categoryIdentifier,
            completionHandler: completionHandler
        )
    }

    // Called by the SessionManager when the user engages a notification action.
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Logging.push.safePublic("Did receive notification response: \(response)")
        let userText = (response as? UNTextInputNotificationResponse)?.userText
        let note = response.notification

        handleNotificationResponse(
            actionIdentifier: response.actionIdentifier,
            categoryIdentifier: note.request.content.categoryIdentifier,
            userInfo: note.userInfo,
            userText: userText,
            completionHandler: completionHandler
        )
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
        if categoryIdentifier == PushNotificationCategory.incomingCall.rawValue {
            handleTrackingOnCallNotification(with: userInfo)
        }

        // foreground notification responder exists on the UI context, so we
        // need to switch to that context
        managedObjectContext.perform {
            let responder = self.sessionManager?.foregroundNotificationResponder
            let shouldPresent = responder?.shouldPresentNotification(with: userInfo)

            var options = UNNotificationPresentationOptions()
            if shouldPresent ?? true { options = [.list, .banner, .sound] }

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
        case CallNotificationAction.ignore.rawValue:
            ignoreCall(with: userInfo, completionHandler: completionHandler)

        case CallNotificationAction.accept.rawValue:
            acceptCall(with: userInfo, completionHandler: completionHandler)

        case ConversationNotificationAction.mute.rawValue:
            muteConversation(with: userInfo, completionHandler: completionHandler)

        case ConversationNotificationAction.like.rawValue:
            likeMessage(with: userInfo, completionHandler: completionHandler)

        case ConversationNotificationAction.reply.rawValue:
            if let textInput = userText {
                reply(with: userInfo, message: textInput, completionHandler: completionHandler)
            }

        case ConversationNotificationAction.connect.rawValue:
            acceptConnectionRequest(with: userInfo, completionHandler: completionHandler)

        default:
            showContent(for: userInfo)
            completionHandler()
        }
    }
}

extension UNNotificationContent {
    override open var description: String {
        "<\(type(of: self)); threadIdentifier: \(threadIdentifier); content: redacted>"
    }
}

extension PushToken {
    public init(deviceToken: Data, pushTokenType: TokenType) {
        let metadata = PushTokenMetadata.current(for: pushTokenType)
        self.init(
            deviceToken: deviceToken,
            appIdentifier: metadata.appIdentifier,
            transportType: metadata.transportType,
            tokenType: pushTokenType
        )
    }

    public static func createVOIPToken(from deviceToken: Data) -> PushToken {
        PushToken(deviceToken: deviceToken, pushTokenType: .voip)
    }

    public static func createAPNSToken(from deviceToken: Data) -> PushToken {
        PushToken(deviceToken: deviceToken, pushTokenType: .standard)
    }
}
