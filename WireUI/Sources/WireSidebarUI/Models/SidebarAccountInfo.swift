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

import UIKit

public struct SidebarAccountInfo {

    public var displayName = ""
    public var username = ""
    public var accountImage = AccountImageContent.text("")
    public var availability: Availability?

    public init() {}

    public init(
        displayName: String,
        username: String,
        accountImage: AccountImageContent,
        availability: Availability?
    ) {
        self.displayName = displayName
        self.username = username
        self.accountImage = accountImage
        self.availability = availability
    }

    public enum Availability: CaseIterable {
        case available, busy, away
    }

    public enum AccountImageContent {
        case image(UIImage), text(String)
    }
}
