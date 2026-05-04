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

import UIKit

public struct SidebarAccountInfo {

    public var displayName = ""
    public var username = ""
    public var accountImageSource = AccountImageSource()
    public var availability: Availability?
    public var isE2EICertified = false
    public var isVerified = false
    public var isLegalHoldEnabled = false
    public var showNotificationsBadge = false

    public init() {}

    public init(
        displayName: String,
        username: String,
        accountImageSource: AccountImageSource,
        availability: Availability?,
        isE2EICertified: Bool,
        isVerified: Bool,
        isLegalHoldEnabled: Bool,
        showNotificationsBadge: Bool
    ) {
        self.displayName = displayName
        self.username = username
        self.accountImageSource = accountImageSource
        self.availability = availability
        self.isE2EICertified = isE2EICertified
        self.isVerified = isVerified
        self.isLegalHoldEnabled = isLegalHoldEnabled
        self.showNotificationsBadge = showNotificationsBadge
    }

    public enum Availability: CaseIterable {
        case available
        case busy
        case away
    }

    public enum AccountImageSource: Equatable, Sendable {
        case image(UIImage)
        case text(_ initials: String)

        public init() { self = .text("") }
    }
}
