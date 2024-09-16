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
import WireFoundation

// TODO: make public final
open /*public final*/ class MainCoordinator<MainSplitViewController, MainTabBarController>: MainCoordinatorProtocol, UISplitViewControllerDelegate
    where MainSplitViewController: MainSplitViewControllerProtocol, MainTabBarController: MainTabBarControllerProtocol {

    private weak var mainSplitViewController: MainSplitViewController!
    private weak var mainTabBarController: MainTabBarController!

    // TODO: setup inside or outside?
    // only navigation here?
    // protocols/accessors for each navigation controller? or viewControllers array

    private var selfProfileBuilder: any ViewControllerBuilder

    private weak var selfProfileViewController: UIViewController?

    private var isLayoutCollapsed = false

    public init(
        mainSplitViewController: MainSplitViewController,
        mainTabBarController: MainTabBarController,
        selfProfileBuilder: /*some*/ any ViewControllerBuilder
    ) {
        self.mainSplitViewController = mainSplitViewController
        self.mainTabBarController = mainTabBarController
        self.selfProfileBuilder = selfProfileBuilder
    }

    deinit {
        /*WireLogger.ui.debug*/print("MainCoordinator.deinit")
    }

    public func showConversations() {
        fatalError("not implemented yet")
    }

    public func showArchivedConversation() {
        fatalError("not implemented yet")
    }

    @MainActor
    public func showSelfProfile() async {
        let selfProfileViewController = selfProfileViewController ?? selfProfileBuilder.build()
        self.selfProfileViewController = selfProfileViewController
        // selfProfileViewController?.presentingViewController?.dismiss(animated: false)

        let conversationList: UIViewController
        if isLayoutCollapsed {
            conversationList = mainTabBarController.conversations!.conversationList
        } else {
            conversationList = mainSplitViewController.conversationList!
        }
        await withCheckedContinuation { continuation in
            conversationList.present(selfProfileViewController, animated: true, completion: continuation.resume)
        }
    }

    public func showSettings() {
        fatalError("not implemented yet")



        //        private func createSettingsViewController() -> UIViewController {
        //            let settingsViewControllerBuilder = SettingsMainViewControllerBuilder(
        //                userSession: userSession,
        //                selfUser: userSession.selfUserLegalHoldSubject
        //            )
        //            return settingsViewControllerBuilder.build()
        //        }



        // TODO: remove?
                // guard let selfUser = ZMUser.selfUser() else {
                //     assertionFailure("ZMUser.selfUser() is nil")
                //     return
                // }

        //        let settingsViewController = createSettingsViewController(selfUser: selfUser)
        //        let keyboardAvoidingViewController = KeyboardAvoidingViewController(viewController: settingsViewController)

                // TODO: fix
                fatalError("TODO")
                // if wr_splitViewController?.layoutSize == .compact {
                //     present(keyboardAvoidingViewController, animated: true)
                // } else {
                //     keyboardAvoidingViewController.modalPresentationStyle = .formSheet
                //     keyboardAvoidingViewController.view.backgroundColor = .black
                //     present(keyboardAvoidingViewController, animated: true)
                // }
    }

//    public func openConversation(
//        _ conversation: Conversation,
//        focusOnView focus: Bool,
//        animated: Bool
//    ) {
//        fatalError("not implemented yet")
//    }
//
//    public func openConversation(
//        _ conversation: Conversation,
//        andScrollTo message: ConversationMessage,
//        focusOnView focus: Bool,
//        animated: Bool
//    ) {
//        fatalError("not implemented yet")
//    }

    // MARK: - UISplitViewControllerDelegate

    public func splitViewControllerDidCollapse(_: UISplitViewController) {
        isLayoutCollapsed = true

        // TODO: make changes
    }

    public func splitViewControllerDidExpand(_: UISplitViewController) {
        isLayoutCollapsed = false

        // TODO: make changes
    }
}
