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

public final class MainCoordinator<MainSplitViewController, MainTabBarController, Conversation, ConversationMessage>: MainCoordinatorProtocol, UISplitViewControllerDelegate
    where MainSplitViewController: MainSplitViewControllerProtocol, MainTabBarController: MainTabBarControllerProtocol {

    private weak var mainSplitViewContent: MainSplitViewController?
    private weak var mainTabBarContent: MainTabBarController?

    // TODO: setup inside or outside?
    // only navigation here?
    // protocols/accessors for each navigation controller? or viewControllers array

    @discardableResult
    public init(
        mainSplitViewContent: MainSplitViewController,
        mainTabBarContent: MainTabBarController
    ) {
        // self.splitViewController = splitViewController
        // objc_setAssociatedObject(splitViewController, &associatedObjectKey, self, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    public func showConversations() {
        fatalError("not implemented yet")
    }

    public func showArchivedConversation() {
        fatalError("not implemented yet")
    }

    public func showSettings() {
        fatalError("not implemented yet")
    }

    public func openConversation(
        _ conversation: Conversation,
        focusOnView focus: Bool,
        animated: Bool
    ) {
        fatalError("not implemented yet")
    }

    public func openConversation(
        _ conversation: Conversation,
        andScrollTo message: ConversationMessage,
        focusOnView focus: Bool,
        animated: Bool
    ) {
        fatalError("not implemented yet")
    }

    // MARK: - UISplitViewControllerDelegate

    public func splitViewControllerDidCollapse(_: UISplitViewController) {
        fatalError("not implemented yet")
    }

    public func splitViewControllerDidExpand(_: UISplitViewController) {
        fatalError("not implemented yet")
    }
}

// private nonisolated(unsafe) var associatedObjectKey = 0
