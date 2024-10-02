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

@MainActor
public protocol MainSplitViewControllerProtocol: UISplitViewController, MainContainerViewController {

    associatedtype Sidebar: MainSidebarProtocol
    associatedtype Connect: UIViewController // TODO: remove
    associatedtype TabContainer: MainTabBarControllerProtocol where
        TabContainer.ConversationList == ConversationList,
        TabContainer.Conversation == Conversation,
        TabContainer.Archive == Archive,
        TabContainer.Settings == Settings,
        TabContainer.SettingsContent == SettingsContent

    /// Contains the reference to the view controller shown in the primary column.
    var sidebar: Sidebar! { get }

    /// Assigning a view controller instance to this property will present the instance in the supplementary column.
    var connect: Connect? { get set } // TODO: remove

    /// Contains the reference to the view controller which will be visible in collapsed mode.
    var tabContainer: TabContainer! { get }
}
