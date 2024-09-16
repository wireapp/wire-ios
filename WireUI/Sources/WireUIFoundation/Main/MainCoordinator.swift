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

// TODO: make `public final`
open /*public final*/ class MainCoordinator<MainSplitViewController, MainTabBarController>: MainCoordinatorProtocol, UISplitViewControllerDelegate
where MainSplitViewController: MainSplitViewControllerProtocol, MainTabBarController: MainTabBarControllerProtocol, MainSplitViewController.ConversationList == MainTabBarController.ConversationList {

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
        guard selfProfileViewController == nil else {
            return assertionFailure() // TODO: inject logger instead
        }

        let conversationList = if isLayoutCollapsed {
            mainTabBarController.conversations!.conversationList
        } else {
            mainSplitViewController.conversationList!
        }

        let selfProfileViewController = UINavigationController(rootViewController: selfProfileBuilder.build())
        selfProfileViewController.modalPresentationStyle = .formSheet
        self.selfProfileViewController = selfProfileViewController

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

// TODO: add a doc comment describing the approach having navigation controllers for presenting the navigation bar and for the possibility to move view controllers

    // MARK: - UISplitViewControllerDelegate

    // func splitViewController(
    //     _ svc: UISplitViewController,
    //     topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column
    // ) -> UISplitViewController.Column {
    //     //
    // }

    // func splitViewController(_ svc: UISplitViewController, willHide column: UISplitViewController.Column) {
    //     print("349ur09e willHide \(column)")
    // }

    /*public*/ open func splitViewControllerDidCollapse(_ splitViewController: UISplitViewController) {
        guard splitViewController === mainSplitViewController else {
            return assertionFailure() // TODO: inject logger instead
        }

        isLayoutCollapsed = true

        /*
        let containers = ContainerViewControllers(of: splitViewController)

        // validate assumptions
        guard
            // there should never be anything pushed onto the nc of the supplmentary and secondary columns
            containers.supplementaryColumn.viewControllers.count == 1,
            containers.secondaryColumn.viewControllers.count == 1
        else { return assertionFailure("view controller hierarchy invalid assumptions") }
         */

        // move view controllers from the split view controller's columns to the tab bar controller
        let conversationListViewController = mainSplitViewController.conversationList!
        mainSplitViewController.conversationList = nil
        mainTabBarController.conversations = (conversationListViewController, nil)

        // TODO: conversations

        // TODO: more to move?
    }

    // func splitViewController(
    //     _ svc: UISplitViewController,
    //     displayModeForExpandingToProposedDisplayMode proposedDisplayMode: UISplitViewController.DisplayMode
    // ) -> UISplitViewController.DisplayMode {
    //     //
    // }

    // func splitViewController(_ svc: UISplitViewController, willShow column: UISplitViewController.Column) {
    //     print("349ur09e willShow \(column)")
    // }

    /*public*/ open func splitViewControllerDidExpand(_ splitViewController: UISplitViewController) {
        guard splitViewController === mainSplitViewController else {
            return assertionFailure() // TODO: inject logger instead
        }

        isLayoutCollapsed = false

        // move view controllers from the tab bar controller to the supplementary column
        let (conversationViewController, _) = mainTabBarController.conversations!
        mainTabBarController.conversations = nil
        mainSplitViewController.conversationList = conversationViewController

        // TODO: conversations

        // TODO: more to move?
    }
}
