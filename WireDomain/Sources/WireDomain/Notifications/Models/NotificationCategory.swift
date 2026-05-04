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

/// Categories to which push notifications belong.
public enum NotificationCategory: String, CaseIterable {

    case nonActionable
    case unmutedConversation
    case incomingCall
    case missedCall
    case incomingConnectionRequest

    /// Available actions for each category
    private var actions: [NotificationAction] {
        switch self {
        case .nonActionable:
            []
        case .unmutedConversation:
            [.muteConversation]
        case .incomingCall:
            [.ignoreCall]
        case .missedCall:
            []
        // [.callback] TODO: [WPB-17220] Callback is currently broken - disabling this action for now
        case .incomingConnectionRequest:
            [.acceptConnectionRequest]
        }
    }

    private func make() -> UNNotificationCategory {
        let userActions = actions.map { $0.makeUNNotificationAction() }

        return UNNotificationCategory(
            identifier: rawValue,
            actions: userActions,
            intentIdentifiers: [],
            options: []
        )
    }
}

public extension NotificationCategory {
    static var allCategories: Set<UNNotificationCategory> {
        let categories = NotificationCategory.allCases.map { $0.make() }
        return Set(categories)
    }
}
