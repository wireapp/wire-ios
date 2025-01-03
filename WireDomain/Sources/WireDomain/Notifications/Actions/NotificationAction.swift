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

import UserNotifications

protocol NotificationAction {

    /// The identifier of the action.
    var identifier: String { get }

    /// The format for the localized action string.
    var title: String { get }

    /// Whether the action deletes content when executed.
    var isDestructive: Bool { get }

    /// Whether the action opens the app when executed.
    var opensApplication: Bool { get }

    /// Whether the action requires the device to be unlocked before being executed.
    var requiresAuthentication: Bool { get }
}

extension NotificationAction {
    func make() -> UNNotificationAction {
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
