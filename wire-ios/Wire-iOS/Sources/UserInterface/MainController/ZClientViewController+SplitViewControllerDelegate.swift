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

extension ZClientViewController: UISplitViewControllerDelegate, SplitViewControllerDelegate {

    func splitViewControllerShouldMoveLeftViewController(_ splitViewController: SplitViewController) -> Bool {

        print("#^$% splitViewControllerShouldMoveLeftViewController:", splitViewController.rightViewController != nil &&
              splitViewController.leftViewController == conversationListViewController.tabBarController &&
              conversationListViewController.state == .conversationList &&
              (conversationListViewController.presentedViewController == nil || splitViewController.isLeftViewControllerRevealed == false))

        print("#^$% splitViewController.rightViewController", splitViewController.rightViewController != nil)
        print("#^$% splitViewController.leftViewController == conversationListViewController.tabBarController", splitViewController.leftViewController == conversationListViewController.tabBarController)
        print("#^$% conversationListViewController.state == .conversationList", conversationListViewController.state == .conversationList)
        print("#^$% conversationListViewController.presentedViewController", conversationListViewController.presentedViewController)
        print("#^$% splitViewController.isLeftViewControllerRevealed", splitViewController.isLeftViewControllerRevealed)

        return splitViewController.rightViewController != nil &&
        splitViewController.leftViewController == conversationListViewController.tabBarController &&
        conversationListViewController.state == .conversationList &&
        (conversationListViewController.presentedViewController == nil || splitViewController.isLeftViewControllerRevealed == false)
    }
}
