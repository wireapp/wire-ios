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

import WireMainNavigation
import WireSettings
import WireSidebar
import WireDataModel

enum MainCoordinatorDependencies: GenericMainCoordinatorDependencies {

    // MainCoordinatorProtocolDependencies

    typealias ConversationFilter = Wire.ConversationFilter
    typealias ConversationModel = ZMConversation
    typealias ConversationMessageModel = ZMConversationMessage
    typealias SettingsTopLevelMenuItem = WireSettings.SettingsTopLevelMenuItem
    typealias User = any UserType

    // GenericMainCoordinatorDependencies

    typealias SplitViewController = MainSplitViewController<SidebarViewController, TabBarController>
    typealias TabBarController = MainTabBarController<ConversationListViewController, ConversationRootViewController>
    typealias ConversationBuilder = ConversationViewControllerBuilder
    typealias SettingsContentBuilder = SettingsViewControllerBuilder
    typealias ConnectBuilder = StartUIViewControllerBuilder
    typealias CreateGroupConversationBuilder = CreateGroupConversationViewControllerBuilder
    typealias SelfProfileBuilder = SelfProfileViewControllerBuilder
    typealias UserProfileBuilder = UserProfileViewControllerBuilder
}
