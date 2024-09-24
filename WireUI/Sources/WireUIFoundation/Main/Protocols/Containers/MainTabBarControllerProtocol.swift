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
public protocol MainTabBarControllerProtocol: UITabBarController {

    associatedtype ConversationList: MainConversationListProtocol
    typealias Conversation = UIViewController
    typealias Archive = UIViewController
    typealias Settings = UIViewController

    /// The selected tab. Since a `selectedTab` property exists in `UITabBarController` this property is suffixed with "Content" instead.
    var selectedContent: MainTabBarControllerContent { get set }

    /// In the compact layout the conversation view controller will be pushed onto the navigation controller of the conversation list.
    var conversations: (conversationList: ConversationList, conversation: Conversation?)? { get set }
    var archive: Archive? { get set }
    var settings: Settings? { get set }
}
