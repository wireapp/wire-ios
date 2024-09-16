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

import WireCommonComponents
import WireDataModel
import WireSystem
import WireUIFoundation
import WireSidebar

final class MainCoordinator<MainSplitViewController: MainSplitViewControllerProtocol, MainTabBarController: MainTabBarControllerProtocol>: WireUIFoundation.MainCoordinator<MainSplitViewController, MainTabBarController> where MainSplitViewController.ConversationList == MainTabBarController.ConversationList {

    private weak var zClientViewController: ZClientViewController!

    // private(set) var settingsBuilder: ViewControllerBuilder

    init(
        zClientViewController: ZClientViewController,
        mainSplitViewController: MainSplitViewController,
        mainTabBarController: MainTabBarController,
        selfProfileBuilder: ViewControllerBuilder,
        settingsBuilder: ViewControllerBuilder
    ) {
        self.zClientViewController = zClientViewController
        // self.selfProfileBuilder = selfProfileBuilder
        // self.settingsBuilder = settingsBuilder
        super.init(
            mainSplitViewController: mainSplitViewController,
            mainTabBarController: mainTabBarController,
            selfProfileBuilder: selfProfileBuilder
        )
    }

    deinit {
        WireLogger.ui.debug("MainCoordinator.deinit")
    }

    // MARK: - Methods

    /*
    func openConversation(_ conversation: ZMConversation, focusOnView focus: Bool, animated: Bool) {
        guard let zClientViewController else {
            return WireLogger.mainCoordinator.warn("zClientViewController is nil")
        }
        zClientViewController.load(conversation, scrollTo: nil, focusOnView: focus, animated: animated)
    }

    func openConversation<Message>(
        _ conversation: ZMConversation,
        scrollTo message: Message,
        focusOnView focus: Bool,
        animated: Bool
    ) where Message: ZMConversationMessage {
        guard let zClientViewController else {
            return WireLogger.mainCoordinator.warn("zClientViewController is nil")
        }
        zClientViewController.load(conversation, scrollTo: message, focusOnView: focus, animated: animated)
    }

    func showConversationList() {
        guard let zClientViewController else {
            return WireLogger.mainCoordinator.warn("zClientViewController is nil")
        }
        zClientViewController.showConversationList()
    }

    func showSelfProfile() {
        guard let zClientViewController else {
            return WireLogger.mainCoordinator.warn("zClientViewController is nil")
        }

        settingsViewController = settingsViewController ?? settingsBuilder.build()

        let settingsViewController = selfProfileBuilder
                .build()
                .wrapInNavigationController(navigationControllerClass: NavigationController.self)
    }

    func showSettings() {
        guard let zClientViewController else {
            return WireLogger.mainCoordinator.warn("zClientViewController is nil")
        }

        settingsViewController = settingsViewController ?? settingsBuilder.build()
        fatalError("TODO: present if needed")
    }
     */

// MARK: - UISplitViewControllerDelegate

    override func splitViewControllerDidCollapse(_ splitViewController: UISplitViewController) {
        super.splitViewControllerDidCollapse(splitViewController)

        // TODO: remove
        let mainTabBarController = splitViewController.viewController(for: .compact) as! MainTabBarController
        let navigationController = mainTabBarController.viewControllers![0] as! UINavigationController
        let conversationListViewController = navigationController.viewControllers[0] as! ConversationListViewController
        // TODO: how can this be done then?
        conversationListViewController.splitViewControllerMode = .collapsed
    }

    override func splitViewControllerDidExpand(_ splitViewController: UISplitViewController) {
        super.splitViewControllerDidExpand(splitViewController)

        // TODO: remove
        let navigationController = splitViewController.viewController(for: .supplementary) as! UINavigationController
        let conversationListViewController = navigationController.viewControllers[0] as! ConversationListViewController
        // TODO: how can this be done then?
        conversationListViewController.splitViewControllerMode = .expanded
    }
}

// TODO: adapter needed
extension MainCoordinator: SidebarViewControllerDelegate {

    func sidebarViewControllerDidSelectAccountImage(_ viewController: SidebarViewController) {
        Task {
            await showSelfProfile()
        }
    }

    func sidebarViewController(_ viewController: SidebarViewController, didSelect conversationFilter: SidebarConversationFilter?) {
        fatalError("TODO")
    }

    func sidebarViewControllerDidSelectConnect(_ viewController: SidebarViewController) {
        fatalError("TODO")
    }

    func sidebarViewControllerDidSelectSettings(_ viewController: SidebarViewController) {
        fatalError("TODO")
    }

    func sidebarViewControllerDidSelectSupport(_ viewController: SidebarViewController) {
        fatalError("TODO")
    }
}
