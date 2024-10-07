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
    typealias Archive = UIViewController
    typealias Settings = UIViewController

    typealias Conversation = MockConversationViewController<MockConversation, MockMessage>
    typealias SettingsContent = UIViewController

    typealias Connect = UIViewController

    var selectedContent: MainTabBarControllerContent = .conversations

    var conversationList: MockConversationListViewController?
    var archive: Archive?
    var settings: Settings?

    var conversation: Conversation?
    var settingsContent: SettingsContent?

    func setConversationList(_ conversationList: ConversationList?, animated: Bool) {
        fatalError("mock method not implemented")
    }

    func setArchive(_ archive: UIViewController?, animated: Bool) {
        fatalError("mock method not implemented")
    }

    func setSettings(_ settings: Settings?, animated: Bool) {
        fatalError("mock method not implemented")
    }

    func setConversation(_ conversation: Conversation?, animated: Bool) {
        fatalError("mock method not implemented")
    }

    func setSettingsContent(_ settingsContent: SettingsContent?, animated: Bool) {
        fatalError("mock method not implemented")
    }
}
