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

>: NSObject, MainCoordinatorProtocol, UISplitViewControllerDelegate, UITabBarControllerDelegate where

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
    private weak var selfProfile: UIViewController?

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

    // TODO: remove
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

    public func showConversationList<ConversationFilter: MainConversationFilterRepresentable>(conversationFilter: ConversationFilter?) {
        defer {
            // switch to the conversation list tab
            tabBarController.selectedContent = .conversations
            // TODO: maybe navigationcontroller pop is needed

            // apply the filter to the conversation list
            let mainConversationFilter = conversationFilter?.map()
            conversationList.conversationFilter = mainConversationFilter.map { .init($0) }

            // set the right menu item in the sidebar
            switch mainConversationFilter {
            case .none:
                sidebar.selectedMenuItem = .init(.all)
            case .favorites:
                sidebar.selectedMenuItem = .init(.favorites)
            case .groups:
                sidebar.selectedMenuItem = .init(.groups)
            case .oneOnOne:
                sidebar.selectedMenuItem = .init(.oneOnOne)
            }
        }

        // In collapsed state switching the tab was all we needed to do.
        guard !isLayoutCollapsed else { return }

        dismissArchiveIfNeeded()
        dismissNewConversationIfNeeded()
        dismissSettingsIfNeeded()
        dismissSelfProfileIfNeeded()

        // Move the conversation list from the tab bar controller to the split view controller if needed.
        if let conversationList = tabBarController.conversations?.conversationList {
            tabBarController.conversations = nil
            splitViewController.conversationList = conversationList
        }
    }

    public func showArchivedConversations() {
        // switch to the archive tab
        tabBarController.selectedContent = .archive

        // In collapsed state switching the tab was all we needed to do.
        guard !isLayoutCollapsed else { return }

        dismissConversationListIfNeeded()
        dismissNewConversationIfNeeded()
        dismissSettingsIfNeeded()
        dismissSelfProfileIfNeeded()

        // move the archive from the tab bar controller to the split view controller
        if let archive = tabBarController.archive {
            tabBarController.archive = nil
            splitViewController.archive = archive
        }
    }

    public func showSelfProfile() {
        guard selfProfile == nil else {
            return assertionFailure() // TODO: inject logger instead
        }

        let rootViewController = selfProfileBuilder.build(mainCoordinator: self)
        let selfProfile = UINavigationController(rootViewController: rootViewController)
        selfProfile.modalPresentationStyle = .formSheet
        self.selfProfile = selfProfile

        splitViewController.present(selfProfile, animated: true)
    }

    public func showSettings() {
        tabBarController.selectedContent = .settings

        // In collapsed state switching the tab was all we needed to do.
        guard !isLayoutCollapsed else { return }

        dismissConversationListIfNeeded()
        dismissArchiveIfNeeded()
        dismissNewConversationIfNeeded()
        dismissSelfProfileIfNeeded()

        // move the settings from the tab bar controller to the split view controller
        if let settings = tabBarController.settings {
            tabBarController.settings = nil
            splitViewController.settings = settings
        }
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

    private func dismissConversationListIfNeeded() {
        // if the conversation list is currently visible, move it back to the tab bar controller
        if let conversationList = splitViewController.conversationList {
            splitViewController.conversationList = nil
            let conversation = tabBarController.conversations?.conversation
            tabBarController.conversations = (conversationList, conversation)
        }
    }

    private func dismissArchiveIfNeeded() {
        // Move the archive back to the tab bar controller if needed.
        if let archive = splitViewController.archive {
            splitViewController.archive = nil
            tabBarController.archive = archive
        }
    }

    private func dismissNewConversationIfNeeded() {
        // Dismiss the new conversation view controller if it's visible in the split view controller.
        if let newConversation = splitViewController.newConversation {
            splitViewController.newConversation = nil
            newConversation.presentingViewController?.dismiss(animated: true)
        }
    }

    private func dismissSettingsIfNeeded() {
        // Move the settings back to the tab bar controller if it's visible in the split view controller.
        if let settings = splitViewController.settings {
            splitViewController.settings = nil
            tabBarController.settings = settings
        }
    }

    private func dismissSelfProfileIfNeeded() {
        // Dismiss the settings view controller if it's being presentd.
        selfProfile?.dismiss(animated: true)
    }

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
        guard let splitViewController = splitViewController as? SplitViewController,
              splitViewController === self.splitViewController
        else { return assertionFailure() } // TODO: inject logger instead

        // move view controllers from the split view controller's columns to the tab bar controller
        if let conversationListViewController = splitViewController.conversationList {
            splitViewController.conversationList = nil
            tabBarController.conversations = (conversationListViewController, nil)
            // TODO: conversations
        }

        // move the archived conversations list back to the tab bar controller if needed
        if let archive = splitViewController.archive {
            splitViewController.archive = nil
            tabBarController.archive = archive
        }

        // move the settings back to the tab bar controller if needed
        if let settings = splitViewController.settings {
            splitViewController.settings = nil
            tabBarController.settings = settings
        }

        // TODO: new conversation?

        isLayoutCollapsed = true
        conversationList.splitViewInterface = .collapsed
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
        guard let splitViewController = splitViewController as? SplitViewController,
              splitViewController === self.splitViewController
        else { return assertionFailure() } // TODO: inject logger instead

        // move view controllers from the tab bar controller to the supplementary column
        if let (conversationViewController, _) = tabBarController.conversations {
            tabBarController.conversations = nil
            splitViewController.conversationList = conversationViewController
        }

        // TODO: conversations

        // if the archived conversations view controller was visible, present it
        if let archive = tabBarController.archive {
            tabBarController.archive = nil
            splitViewController.archive = archive
        }

        // if the settings were visible, present it
        if let settings = splitViewController.settings {
            tabBarController.settings = nil
            splitViewController.settings = settings
        }

        // TODO: new conversation?

        isLayoutCollapsed = false
        conversationList.splitViewInterface = .expanded
    }

    // MARK: - UITabBarControllerDelegate

    public func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        guard let tabBarController = tabBarController as? TabBarController,
              tabBarController === self.tabBarController
        else { return assertionFailure() } // TODO: inject logger instead

        switch viewController {
        case conversationList:
            switch conversationList.conversationFilter?.map() {
            case .none:
                sidebar.selectedMenuItem = .init(.all)
            case .favorites:
                sidebar.selectedMenuItem = .init(.favorites)
            case .groups:
                sidebar.selectedMenuItem = .init(.groups)
            case .oneOnOne:
                sidebar.selectedMenuItem = .init(.oneOnOne)
            }
        case tabBarController.archive:
            sidebar.selectedMenuItem = .init(.archive)
        case tabBarController.settings:
            sidebar.selectedMenuItem = .init(.settings)
        default:
            assertionFailure()
        }
    }
}
