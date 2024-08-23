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

import SwiftUI

/// Info the sidebar displays.
public final class SidebarData: ObservableObject {

    @Published private(set) var accountInfo: AccountInfo?
    @Published private(set) var availability: Availability?
    @Published private(set) var conversationFilter: ConversationFilter?

    public init(
        accountInfo: AccountInfo?,
        availability: Availability?,
        conversationFilter: ConversationFilter?
    ) {
        self.accountInfo = accountInfo
        self.availability = availability
        self.conversationFilter = conversationFilter
    }
}

extension SidebarData {

    public struct AccountInfo {
        public var displayName = ""
        public var username = ""
        public var accountImage = UIImage()
        public var isTeamAccount = false
    }

    public enum ConversationFilter: CaseIterable {
        case favorites, groups, oneOnOne, archived
    }
}
