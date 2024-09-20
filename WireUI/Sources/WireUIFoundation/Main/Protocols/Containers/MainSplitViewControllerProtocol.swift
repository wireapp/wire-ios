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
public protocol MainSplitViewControllerProtocol: UISplitViewController {

    associatedtype Sidebar: MainSidebarProtocol
    associatedtype ConversationList: MainConversationListProtocol
    associatedtype Conversation: UIViewController
    associatedtype Archive: UIViewController
    associatedtype Settings: UIViewController
    associatedtype TabContainer: UIViewController

    /// Contains the reference to the view controller shown in the primary column.
    var sidebar: Sidebar! { get }

    /// Setting a view controller instance to this property will present the instance in the supplementary column.
    var conversationList: ConversationList? { get set }

    /// Setting a view controller instance to this property will present the instance in the secondary column. Any other view controller set into `archive` or `settings` will be removed.
    var conversation: Conversation? { get set }

    /// Setting a view controller instance to this property will present the instance in the supplementary column. Any other view controller set into `conversationList` or `settings` will be removed.
    var archive: Archive? { get set }

    /// Setting a view controller instance to this property will present the instance in the supplementary column. Any other view controller set into `conversationList` or `archive` will be removed.
    var settings: Settings? { get set }

    /// Contains the reference to the view controller which will be visible in collapsed mode.
    var tabContainer: TabContainer! { get }
}
