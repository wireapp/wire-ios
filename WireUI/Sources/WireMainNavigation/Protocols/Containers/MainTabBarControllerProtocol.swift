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

/// Defines the contract for between the ``MainCoordinator`` and the ``MainTabBarController``.
///
/// The MainTabBarControllerProtocol is a protocol designed to define the essential properties and types that
/// the ``MainCoordinator`` requires to manage the application's tab-based navigation. This protocol
/// extends UITabBarController and outlines the key content areas (such as conversations, archive, and settings)
/// that a conforming tab bar controller must manage.

@MainActor
public protocol MainTabBarControllerProtocol: UITabBarController, MainContainerViewController {

    /// The selected content (tab).
    var selectedContent: MainTabBarControllerContent { get set }

    /// In the compact layout any conversation view controller will be pushed onto the navigation controller of the conversation list.
    var conversations: (conversationList: ConversationList, conversation: Conversation?)? { get set }
    var archive: Archive? { get set }
    var settings: Settings? { get set }
}
