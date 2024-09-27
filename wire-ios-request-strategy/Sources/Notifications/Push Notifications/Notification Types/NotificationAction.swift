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

// MARK: - NotificationActionTextInputMode

/// An object that describes the configuration for text input actions.
struct NotificationActionTextInputMode {
    /// The format string for the localized title of the action/send button.
    let buttonTitleFormat: String

    /// The format string for the localized placeholder text of the input field.
    let placeholderFormat: String
}

// MARK: - NotificationAction

/// An object that describes a notification that can be performed by the user for a notification.

protocol NotificationAction {
    /// The identifier of the action.
    var identifier: String { get }

    /// The format for the localized action string.
    var titleFormat: String { get }

    /// Whether the action deletes content when executed.
    var isDestructive: Bool { get }

    /// Whether the action opens the app when executed.
    var opensApplication: Bool { get }

    /// Whether the action requires the device to be unlocked before being executed.
    var requiresAuthentication: Bool { get }

    /// The optional configuration for text input, if the action supports it.
    var textInputMode: NotificationActionTextInputMode? { get }
}

extension NotificationAction where Self: RawRepresentable, Self.RawValue == String {
    var identifier: String {
        rawValue
    }
}

extension NotificationAction {
    /// The representation of the action that can be used with `UserNotifications` API.
    var userAction: UNNotificationAction {
        if let textInputMode {
            UNTextInputNotificationAction(
                identifier: identifier,
                title: titleFormat.pushActionString,
                options: options,
                textInputButtonTitle: textInputMode.buttonTitleFormat.pushActionString,
                textInputPlaceholder: textInputMode.placeholderFormat.pushActionString
            )
        } else {
            UNNotificationAction(
                identifier: identifier,
                title: titleFormat.pushActionString,
                options: options
            )
        }
    }

    private var options: UNNotificationActionOptions {
        var rawOptions = UNNotificationActionOptions()

        if isDestructive {
            rawOptions.insert(.destructive)
        }

        if opensApplication {
            rawOptions.insert(.foreground)
        }

        if requiresAuthentication {
            rawOptions.insert(.authenticationRequired)
        }

        return rawOptions
    }
}

// MARK: - ConversationNotificationAction

public enum ConversationNotificationAction: String, NotificationAction {
    case open = "conversationOpenAction"
    case reply = "conversationDirectReplyAction"
    case mute = "conversationMuteAction"
    case like = "messageLikeAction"
    case connect = "acceptConnectAction"

    var titleFormat: String {
        switch self {
        case .open: "message.open"
        case .reply: "message.reply"
        case .mute: "conversation.mute"
        case .like: "message.like"
        case .connect: "connection.accept"
        }
    }

    var isDestructive: Bool {
        false
    }

    var opensApplication: Bool {
        switch self {
        case .open:
            true
        default:
            false
        }
    }

    var requiresAuthentication: Bool {
        false
    }

    var textInputMode: NotificationActionTextInputMode? {
        switch self {
        case .reply:
            NotificationActionTextInputMode(
                buttonTitleFormat: "message.reply.button.title",
                placeholderFormat: "message.reply.placeholder"
            )

        default:
            nil
        }
    }
}

// MARK: - CallNotificationAction

public enum CallNotificationAction: String, NotificationAction {
    case ignore = "ignoreCallAction"
    case accept = "acceptCallAction"
    case callBack = "callbackCallAction"
    case message = "conversationDirectReplyAction"

    var titleFormat: String {
        switch self {
        case .ignore: "call.ignore"
        case .accept: "call.accept"
        case .callBack: "call.callback"
        case .message: "call.message"
        }
    }

    var isDestructive: Bool {
        switch self {
        case .ignore:
            true
        default:
            false
        }
    }

    var opensApplication: Bool {
        switch self {
        case .accept, .callBack:
            true
        default:
            false
        }
    }

    var requiresAuthentication: Bool {
        false
    }

    var textInputMode: NotificationActionTextInputMode? {
        switch self {
        case .message:
            NotificationActionTextInputMode(
                buttonTitleFormat: "message.reply.button.title",
                placeholderFormat: "message.reply.placeholder"
            )

        default:
            nil
        }
    }
}
