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

// TODO: could typaliases take some of the generic conditions?

@MainActor
public final class MainCoordinator<SplitViewController, TabBarController, NewConversationBuilder>: MainCoordinatorProtocol, UISplitViewControllerDelegate where
SplitViewController: MainSplitViewControllerProtocol,
TabBarController: MainTabBarControllerProtocol,
SplitViewController.Sidebar: MainSidebarProtocol,
SplitViewController.ConversationList == TabBarController.ConversationList,
TabBarController.Archive == UIViewController,
NewConversationBuilder: MainContentViewControllerBuilder {

    private weak var mainSplitViewController: SplitViewController!
    private weak var mainTabBarController: TabBarController!

    /// A reference to the archived conversations view controller. This property is needed for the expanded layout mode
    /// when the archived conversations list is taken out of the tab bar controller and presented on top of the conversation list.
    private weak var archivedConversations: TabBarController.Archive?

    private let newConversationBuilder: NewConversationBuilder

    private weak var selfProfileViewController: UIViewController?

    private var selfProfileBuilder: any ViewControllerBuilder

    private var isLayoutCollapsed = false

    public init(
        mainSplitViewController: SplitViewController,
        mainTabBarController: TabBarController,
        newConversationBuilder: NewConversationBuilder,
        selfProfileBuilder: /*some*/ any ViewControllerBuilder
    ) {
        self.mainSplitViewController = mainSplitViewController
        self.mainTabBarController = mainTabBarController
        self.newConversationBuilder = newConversationBuilder
        self.selfProfileBuilder = selfProfileBuilder

        archivedConversations = mainTabBarController.archive
    }

    deinit {
        /*WireLogger.ui.debug*/print("MainCoordinator.deinit")
    }

    // MARK: - Methods

    public func showConversationList(conversationFilter: TabBarController.ConversationList.ConversationFilter?) {
        showConversationList()

        switch conversationFilter {
        case .none:
            mainSplitViewController.conversationList?.conversationFilter = .none
        case .favorites:
            mainSplitViewController.conversationList?.conversationFilter = .favorites
        case .groups:
            mainSplitViewController.conversationList?.conversationFilter = .groups
        case .oneOnOne:
            mainSplitViewController.conversationList?.conversationFilter = .oneOnOne
        default:
            break
        }
    }

    public func showConversationList() {
        mainTabBarController.selectedContent = .conversations

        if !isLayoutCollapsed {
            moveArchivedConversationsIntoMainTabBarControllerIfNeeded()

            // TODO: complete
            // settings visible?
            // archive visible?
            // selfProfile visible?
        }
    }

    public func showArchivedConversations() {
        mainTabBarController.selectedContent = .archive

        if !isLayoutCollapsed {
            // if it's already visible (and not contained in the tabBarController anymore), do nothing
            guard mainTabBarController.archive != nil else { return }
            addArchivedConversationsAsChildOfConversationList()
        }
    }

    public func showSelfProfile() {
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

        conversationList.present(selfProfileViewController, animated: true)
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

    public func showNewConversation() {
        let viewController = newConversationBuilder.build(mainCoordinator: self)

        let navigationController = UINavigationController(rootViewController: viewController)
        // navigationController.view.backgroundColor = SemanticColors.View.backgroundDefault
        navigationController.modalPresentationStyle = .formSheet

        fatalError("TODO: present")
        // present(navigationController, animated: true)
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

    public func splitViewControllerDidCollapse(_ splitViewController: UISplitViewController) {
        guard splitViewController === mainSplitViewController else {
            return assertionFailure() // TODO: inject logger instead
        }

        isLayoutCollapsed = true

        // move view controllers from the split view controller's columns to the tab bar controller
        let conversationListViewController = mainSplitViewController.conversationList!
        mainSplitViewController.conversationList = nil
        mainTabBarController.conversations = (conversationListViewController, nil)
        conversationListViewController.splitViewInterface = .collapsed

        // TODO: conversations

        // move the archived conversations list back to the tab bar controller if needed
        moveArchivedConversationsIntoMainTabBarControllerIfNeeded()

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

    public func splitViewControllerDidExpand(_ splitViewController: UISplitViewController) {
        guard splitViewController === mainSplitViewController else {
            return assertionFailure() // TODO: inject logger instead
        }

        isLayoutCollapsed = false

        // move view controllers from the tab bar controller to the supplementary column
        let (conversationViewController, _) = mainTabBarController.conversations!
        mainTabBarController.conversations = nil
        mainSplitViewController.conversationList = conversationViewController
        conversationViewController.splitViewInterface = .expanded

        // TODO: conversations

        // if the archived conversations view controller was visible, present it on top of the conversation list
        if mainTabBarController.selectedContent == .archive {
            addArchivedConversationsAsChildOfConversationList()
            mainSplitViewController.sidebar.conversationFilter = .archived
        }

        // TODO: more to move?
    }

    // MARK: - Helpers

    private func addArchivedConversationsAsChildOfConversationList() {
        let conversationList = mainSplitViewController.conversationList!
        let archivedConversations = archivedConversations!
        mainTabBarController.archive = nil

        conversationList.addChild(archivedConversations)
        archivedConversations.view.translatesAutoresizingMaskIntoConstraints = false
        conversationList.view.addSubview(archivedConversations.view)
        NSLayoutConstraint.activate([
            archivedConversations.view.leadingAnchor.constraint(equalTo: conversationList.view.leadingAnchor),
            archivedConversations.view.topAnchor.constraint(equalTo: conversationList.view.topAnchor),
            conversationList.view.trailingAnchor.constraint(equalTo: archivedConversations.view.trailingAnchor),
            conversationList.view.bottomAnchor.constraint(equalTo: archivedConversations.view.bottomAnchor)
        ])
        archivedConversations.didMove(toParent: conversationList)
    }

    private func moveArchivedConversationsIntoMainTabBarControllerIfNeeded() {
        // If the archive tab is empty, we're showing the conversation archive in the expanded layout.
        // That's how we know that we need to move it back.
        if mainTabBarController.archive == nil {
            archivedConversations!.willMove(toParent: nil)
            archivedConversations!.view.removeFromSuperview()
            archivedConversations!.removeFromParent()
            archivedConversations!.view.translatesAutoresizingMaskIntoConstraints = true
            mainTabBarController.archive = archivedConversations
            mainTabBarController.selectedContent = .archive
        }
    }
}
