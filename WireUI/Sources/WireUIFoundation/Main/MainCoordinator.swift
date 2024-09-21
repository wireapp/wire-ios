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

// TODO: unit tests

@MainActor
public final class MainCoordinator<

    SplitViewController: MainSplitViewControllerProtocol,
    TabBarController: MainTabBarControllerProtocol,
    NewConversationBuilder: MainCoordinatorInjectingViewControllerBuilder,
    SelfProfileBuilder: MainCoordinatorInjectingViewControllerBuilder

>: MainCoordinatorProtocol, UISplitViewControllerDelegate where

    SplitViewController.Sidebar: MainSidebarProtocol,
    SplitViewController.ConversationList == TabBarController.ConversationList,
SplitViewController.Archive == TabBarController.Archive,
SplitViewController.Settings == TabBarController.Settings

{

    // MARK: - Private Properties

    private weak var splitViewController: SplitViewController!
    private weak var tabBarController: TabBarController!

    private let newConversationBuilder: NewConversationBuilder
    private var selfProfileBuilder: SelfProfileBuilder
    private weak var selfProfile: SelfProfileBuilder.ViewController?

    private var isLayoutCollapsed = false // TODO: use `MainSplitViewState`

    // MARK: - Private Helpers

    private var sidebar: SplitViewController.Sidebar! {
        splitViewController.sidebar
    }

    private var conversationList: TabBarController.ConversationList! {
        isLayoutCollapsed ? tabBarController.conversations?.conversationList : splitViewController.conversationList
    }

    private var archive: TabBarController.Archive! {
        isLayoutCollapsed ? tabBarController.archive : splitViewController.archive
    }

    private var settings: TabBarController.Settings! {
        isLayoutCollapsed ? tabBarController.settings : splitViewController.settings
    }

//    private var newConversation: NewConversationBuilder.ViewController? {
//        if isLayoutCollapsed {
//            tabBarController.
//        } else {
//            splitViewController.
//        }
//    }

    // MARK: - Life Cycle

    public init(
        mainSplitViewController: SplitViewController,
        mainTabBarController: TabBarController,
        newConversationBuilder: NewConversationBuilder,
        selfProfileBuilder: SelfProfileBuilder
    ) {
        self.splitViewController = mainSplitViewController
        self.tabBarController = mainTabBarController
        self.newConversationBuilder = newConversationBuilder
        self.selfProfileBuilder = selfProfileBuilder
    }

    deinit {
        /* WireLogger.ui.debug */ print("MainCoordinator.deinit")
    }

    // MARK: - Public Methods

    public func showConversationList<ConversationFilter: MainConversationFilterConvertible>(conversationFilter: ConversationFilter?) {
        defer {
            tabBarController.selectedContent = .conversations
            fatalError("TODO")
            // sidebar.selectedMenuItem = conversationFilter.map()
            // conversationList.conversationFilter = conversationFilter.map()
        }

        // In collapsed state switching the tab was all we needed to do.
        guard !isLayoutCollapsed else { return }

        // In expanded state we have to make sure that the conversation
        // list view controller is presented in the supplementary column.

        // Move the archive back to the tab bar controller if needed.
        if let archive = splitViewController.archive {
            splitViewController.archive = nil
            tabBarController.archive = archive
        }

        // Dismiss the new conversation view controller if needed.
        if let newConversation = splitViewController.newConversation {
            splitViewController.newConversation = nil
            newConversation.presentingViewController?.dismiss(animated: true)
        }

        // Move the settings back to the tab bar controller if needed.
        if let settings = splitViewController.settings {
            splitViewController.settings = nil
            tabBarController.settings = settings
        }

        // Dismiss the settings view controller if needed.
        selfProfile?.dismiss(animated: true)

        // Move the conversation list from the tab bar controller to the split view controller if needed.
        if let conversationList = tabBarController.conversations?.conversationList {
            tabBarController.conversations = nil
            splitViewController.conversationList = conversationList
        }
    }

    public func showArchivedConversations() {
        tabBarController.selectedContent = .archive

        // if it's already visible (and not contained in the tabBarController anymore), do nothing
        guard !isLayoutCollapsed, let archive = tabBarController.archive else { return }

        // if the conversation list is currently visible, move it back to the tab bar controller
        if let conversationList = splitViewController.conversationList {
            splitViewController.conversationList = nil
            let conversation = tabBarController.conversations?.conversation
            tabBarController.conversations = (conversationList, conversation)
        }

        // move the archive from the tab bar controller to the split view controller
        tabBarController.archive = nil
        splitViewController.archive = archive

        // TODO: settings, connect
        // presentArchivedConversationsOverConversationList()
    }

    public func showSelfProfile() {
//        guard selfProfileViewController == nil else {
//            return assertionFailure() // TODO: inject logger instead
//        }
//
//        let selfProfileViewController = UINavigationController(rootViewController: selfProfileBuilder.build())
//        selfProfileViewController.modalPresentationStyle = .formSheet
//        self.selfProfileViewController = selfProfileViewController
//
//        let conversationList = if isLayoutCollapsed {
//            tabBarController.conversations!.conversationList
//        } else {
//            splitViewController.conversationList!
//        }
//        conversationList.present(selfProfileViewController, animated: true)
    }

    public func showSettings() {
        tabBarController.selectedContent = .settings

        if !isLayoutCollapsed {
            // if it's already visible (and not contained in the tabBarController anymore), abort
            // guard tabBarController.settings != nil else { return }
            // addSettingsAsChildOfConversationList()

            // TODO: remove this workaround
//            let settingsViewController = (tabBarController.settings ?? settings)!
//            tabBarController.settings = nil
//            let navigationController = UINavigationController(rootViewController: settingsViewController)
//            navigationController.modalPresentationStyle = .formSheet
//
//            // TODO: try to get rid of this line
//            navigationController.view.backgroundColor = .systemBackground
//
//            settings = settingsViewController
//
//            let conversationList = if isLayoutCollapsed {
//                tabBarController.conversations!.conversationList
//            } else {
//                splitViewController.conversationList!
//            }
//            conversationList.present(navigationController, animated: true)
        }

        return ()

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
        // newConversationViewController = navigationController

        if isLayoutCollapsed {
            tabBarController.conversations!.conversationList.present(navigationController, animated: true)
        } else {
            splitViewController.conversationList!.present(navigationController, animated: true)
        }
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
        guard splitViewController === self.splitViewController else {
            return assertionFailure() // TODO: inject logger instead
        }
        let splitViewController = self.splitViewController!

        isLayoutCollapsed = true

        // move view controllers from the split view controller's columns to the tab bar controller
        if let conversationListViewController = splitViewController.conversationList {
            splitViewController.conversationList = nil
            tabBarController.conversations = (conversationListViewController, nil) // TODO: conversations
            conversationListViewController.splitViewInterface = .collapsed
        }

        // move the archived conversations list back to the tab bar controller if needed
        if let archive = splitViewController.archive {
            splitViewController.archive = nil
            tabBarController.archive = archive
        }

        // move the settings back to the tab bar controller if needed
        moveSettingsIntoMainTabBarControllerIfNeeded()
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
        guard splitViewController === self.splitViewController else {
            return assertionFailure() // TODO: inject logger instead
        }
        let splitViewController = self.splitViewController!

        isLayoutCollapsed = false

        // move view controllers from the tab bar controller to the supplementary column
        let (conversationViewController, _) = tabBarController.conversations!
        tabBarController.conversations = nil
        splitViewController.conversationList = conversationViewController
        conversationViewController.splitViewInterface = .expanded

        // TODO: conversations

        // if the archived conversations view controller was visible, present it on top of the conversation list
        if tabBarController.selectedContent == .archive {
            presentArchivedConversationsOverConversationList()
            splitViewController.sidebar.selectedMenuItem = .init(.archive)
        }

        // if the settings view controller was visible, present it on top of the conversation list
        if tabBarController.selectedContent == .settings {
            addSettingsAsChildOfConversationList()
            splitViewController.sidebar.selectedMenuItem = .init(.settings)
        }
    }

    // MARK: - Helpers

    private func presentArchivedConversationsOverConversationList() {
//        let archivedConversations = archivedConversations!
//        tabBarController.archive = nil
//
//        let navigationController = UINavigationController(rootViewController: archivedConversations)
//        navigationController.modalPresentationStyle = .overCurrentContext
//        splitViewController.conversationList!.navigationController?.present(navigationController, animated: false)
    }

    // MARK: -

    private func addSettingsAsChildOfConversationList() {
//        let settings = settings!
//        tabBarController.archive = nil
//        addViewControllerAsChildOfConversationList(settings)
    }

    private func addViewControllerAsChildOfConversationList(_ viewController: UIViewController) {
        let conversationList = splitViewController.conversationList!
        conversationList.addChild(viewController)
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        conversationList.view.addSubview(viewController.view)
        NSLayoutConstraint.activate([
            viewController.view.leadingAnchor.constraint(equalTo: conversationList.view.leadingAnchor),
            viewController.view.topAnchor.constraint(equalTo: conversationList.view.topAnchor),
            conversationList.view.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
            conversationList.view.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor)
        ])
        viewController.didMove(toParent: conversationList)
    }

    private func moveSettingsIntoMainTabBarControllerIfNeeded() {
        // If the settings tab is empty, we're showing the settings in the expanded layout.
        // No need to move it back.
//        if tabBarController.settings == nil {
//            settings!.willMove(toParent: nil)
//            settings!.view.removeFromSuperview()
//            settings!.removeFromParent()
//            settings!.view.translatesAutoresizingMaskIntoConstraints = true
//            mainTabBarController.settings = settings
//            mainTabBarController.selectedContent = .settings
//        }
    }
}
