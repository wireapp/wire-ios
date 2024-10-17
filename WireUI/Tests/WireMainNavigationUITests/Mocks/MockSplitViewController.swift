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

@testable import WireMainNavigationUI

final class MockSplitViewController: UISplitViewController, MainSplitViewControllerProtocol {

    typealias ConversationListUI = PreviewConversationListViewController
    typealias ArchiveUI = UIViewController
    typealias SettingsUI = UIViewController

    typealias ConversationUI = MockConversationViewController<PreviewConversationModel>
    typealias SettingsContentUI = UIViewController

    typealias ConnectUI = UIViewController

    var sidebar: MockSidebarViewController!
    var conversationListUI: ConversationListUI?
    var archiveUI: ArchiveUI?
    var connectUI: ConnectUI?
    var settingsUI: SettingsUI?
    var conversationUI: ConversationUI?
    var settingsContentUI: SettingsContentUI?
    var tabController: MockTabBarController!

    func setConversationListUI(_ conversationListUI: ConversationListUI?, animated: Bool) {
        fatalError("mock method not implemented")
    }

    func setArchiveUI(_ archiveUI: UIViewController?, animated: Bool) {
        fatalError("mock method not implemented")
    }

    func setSettingsUI(_ settingsUI: SettingsUI?, animated: Bool) {
        fatalError("mock method not implemented")
    }

    func setConversationUI(_ conversationUI: ConversationUI?, animated: Bool) {
        fatalError("mock method not implemented")
    }

    func setSettingsContentUI(_ settingsContentUI: SettingsContentUI?, animated: Bool) {
        fatalError("mock method not implemented")
    }

    func setConnectUI(_ connectUI: ConnectUI?, animated: Bool) {
        fatalError("mock method not implemented")
    }

    func hideSidebar() {}
}
