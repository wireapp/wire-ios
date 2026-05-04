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

import UserNotifications

public enum NotificationActionIdentifier {
    public static let muteConversationIdentifier = "conversationMuteAction"
    public static let ignoreCallIdentifier = "ignoreCallAction"
    public static let callbackIdentifier = "callbackCallAction"
    public static let acceptConnectionRequestIdentifier = "acceptConnectAction"
}

struct NotificationAction {

    /// The identifier of the action.
    let identifier: String

    /// The format for the localized action string.
    let title: String

    /// Whether the action deletes content when executed.
    let isDestructive: Bool

    /// Whether the action opens the app when executed.
    let opensApplication: Bool

    /// Whether the action requires the device to be unlocked before being executed.
    let requiresAuthentication: Bool
}

extension NotificationAction {

    static let muteConversation = NotificationAction(
        identifier: NotificationActionIdentifier.muteConversationIdentifier,
        title: String.localized(key: "push.notification.action.mute", bundle: .module),
        isDestructive: false,
        opensApplication: false,
        requiresAuthentication: false
    )

    static let ignoreCall = NotificationAction(
        identifier: NotificationActionIdentifier.ignoreCallIdentifier,
        title: String.localized(key: "push.notification.action.ignoreCall", bundle: .module),
        isDestructive: true,
        opensApplication: false,
        requiresAuthentication: false
    )

    static let callback = NotificationAction(
        identifier: NotificationActionIdentifier.callbackIdentifier,
        title: String.localized(key: "push.notification.action.callback", bundle: .module),
        isDestructive: false,
        opensApplication: true,
        requiresAuthentication: false
    )

    static let acceptConnectionRequest = NotificationAction(
        identifier: NotificationActionIdentifier.acceptConnectionRequestIdentifier,
        title: String.localized(key: "push.notification.action.acceptConnection", bundle: .module),
        isDestructive: false,
        opensApplication: false,
        requiresAuthentication: false
    )

}

extension NotificationAction {
    func makeUNNotificationAction() -> UNNotificationAction {
        var options = UNNotificationActionOptions()

        if isDestructive {
            options.insert(.destructive)
        }

        if opensApplication {
            options.insert(.foreground)
        }

        if requiresAuthentication {
            options.insert(.authenticationRequired)
        }

        /// The representation of the action that can be used with `UserNotifications` API.
        return UNNotificationAction(
            identifier: identifier,
            title: title,
            options: options
        )
    }
}
