//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

extension UNNotificationContent {

    // With the "filtering" entitlement, we can tell iOS to not display a user notification by
    // passing empty content to the content handler.
    // See https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_developer_usernotifications_filtering

    static var empty: Self {
        return Self()
    }
}
