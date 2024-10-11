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

@testable import WireMainNavigation

final class MockSplitViewController: UISplitViewController, MainSplitViewControllerProtocol {

    typealias ConversationList = PreviewConversationListViewController
    typealias Archive = UIViewController
    typealias Settings = UIViewController

    typealias Conversation = MockConversationViewController<PreviewConversationModel, MockConversationMessageModel>
    typealias SettingsContent = UIViewController

    typealias Connect = UIViewController

    var sidebar: MockSidebarViewController!
    var conversationList: ConversationList?
    var archive: Archive?
    var connect: Connect?
    var settings: Settings?
    var conversation: Conversation?
    var settingsContent: SettingsContent?
    var tabContainer: MockTabBarController!

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

    func setConnect(_ connect: Connect?, animated: Bool) {
        fatalError("mock method not implemented")
    }

    func hideSidebar() {}
}
