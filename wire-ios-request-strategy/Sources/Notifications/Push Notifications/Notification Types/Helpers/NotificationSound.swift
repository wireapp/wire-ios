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
import WireUtilities

/// Represents the sound for types of notifications.
public enum NotificationSound {

    // These values are persisted by ExtensionSettings in the shared app-group defaults.
    private static let messageNotificationSoundPreferenceKey = "messageNotificationSound"
    private static let systemDefaultPreferenceValue = "systemDefault"

    /// Storage of the user's preferred notification sounds.

    public static var storage: UserDefaults = .shared()

    case call
    case ping
    case `default`
    case newMessage

    /// The name of the song.
    public var name: String {
        defaultFileName
    }

    /// The sound to use when displaying the notification.
    public var userNotificationSound: UNNotificationSound {
        switch self {
        case .default:
            .default
        case .newMessage where usesSystemDefaultForNewMessages:
            .default
        default:
            UNNotificationSound(named: .init(defaultFileName))
        }
    }

    // MARK: - Utilities

    private var defaultFileName: String {
        switch self {
        case .call: "ringing_from_them_long.caf"
        case .ping: "ping_from_them.caf"
        case .default: "default"
        case .newMessage: "new_message.caf"
        }
    }

    private var usesSystemDefaultForNewMessages: Bool {
        Self.storage.string(forKey: Self.messageNotificationSoundPreferenceKey) == Self.systemDefaultPreferenceValue
    }
}
