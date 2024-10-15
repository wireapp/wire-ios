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

import WireMainNavigationUI

public extension MockMainCoordinatorProtocol {

    typealias ConversationFilter = MainConversationFilter
    typealias SettingsTopLevelMenuItem = MainSettingsTopLevelMenuItem
    struct ConversationModel {}
    struct ConversationMessageModel {}
    struct User {}

    enum Dependencies: MainCoordinatorDependencies {
        public typealias SplitViewController = <#type#>
        public typealias ConversationBuilder = <#type#>
        public typealias SettingsContentBuilder = <#type#>
        public typealias ConnectBuilder = <#type#>
        public typealias CreateGroupConversationBuilder = <#type#>
        public typealias SelfProfileBuilder = <#type#>
        public typealias UserProfileBuilder = <#type#>
        public typealias ConversationFilter = <#type#>
        public typealias ConversationModel = <#type#>
        public typealias ConversationMessageModel = <#type#>
        public typealias SettingsTopLevelMenuItem = <#type#>
        public typealias User = <#type#>
    }
}
