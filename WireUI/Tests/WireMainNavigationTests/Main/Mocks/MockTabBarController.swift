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
import WireMainNavigation

final class MockTabBarController: UITabBarController, MainTabBarControllerProtocol {

    typealias ConversationList = MockConversationListViewController
    typealias Conversation = UIViewController
    typealias Archive = UIViewController
    typealias Connect = UIViewController
    typealias Settings = UIViewController

    var conversationList: MockConversationListViewController? {
        get { conversations?.conversationList }
        set { conversations = newValue.map { ($0, conversations?.conversation) } }
    }
    var conversations: (conversationList: MockConversationListViewController, conversation: UIViewController?)?
    var archive: UIViewController?
    var settings: UIViewController?
    var selectedContent: MainTabBarControllerContent = .conversations
}
