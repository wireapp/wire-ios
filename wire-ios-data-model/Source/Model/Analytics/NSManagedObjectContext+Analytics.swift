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

private let analyticsUserInfoKey = "AnalyticsUserInfoKey"

public extension NSManagedObjectContext {
    /// Set when initializing the user session from the UI, used for easier tracking on SE
    @objc var analytics: AnalyticsType? {
        get {
            guard zm_isSyncContext else { preconditionFailure("Analytics can only be accessed on sync context") }
            return userInfo[analyticsUserInfoKey] as? AnalyticsType
        }

        set {
            guard zm_isSyncContext else { preconditionFailure("Analytics can only be accessed on sync context") }
            userInfo[analyticsUserInfoKey] = newValue
        }
    }
}
