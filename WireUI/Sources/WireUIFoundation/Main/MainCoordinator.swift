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

/// Manages the main flows of the application after a successful login.
///
/// The MainCoordinator class is the central controller for the app's navigation and layout management.
/// It receives references to ``MainTabBarControllerProtocol`` and ``MainSplitViewControllerProtocol``
/// conforming instances and is responsible for managing transitions between different split layout states (collapsed and expanded)
/// as well as handling navigation logic.
///
/// TODO: all contain navigation controllers
/// tab bar controller keeps the instances retained

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
    SplitViewController.Settings == TabBarController.Settings {

    // MARK: - Private Properties

    private weak var splitViewController: SplitViewController!
    private weak var tabBarController: TabBarController!

    private let newConversationBuilder: NewConversationBuilder
    private weak var newConversation: UIViewController?

    private var selfProfileBuilder: SelfProfileBuilder
    private weak var selfProfile: UIViewController?

    private var mainSplitViewState: MainSplitViewState = .expanded

    // MARK: - Private Helpers

    private var sidebar: SplitViewController.Sidebar! {
        splitViewController.sidebar
    }

    private var conversationList: TabBarController.ConversationList! {
        switch mainSplitViewState {
        case .collapsed: tabBarController.conversations?.conversationList
        case .expanded: splitViewController.conversationList
        }
    }

    private var archive: TabBarController.Archive! {
        switch mainSplitViewState {
        case .collapsed: tabBarController.archive
        case .expanded: splitViewController.archive
        }
    }

    private var settings: TabBarController.Settings! {
        switch mainSplitViewState {
        case .collapsed: tabBarController.settings
        case .expanded: splitViewController.settings
        }
    }

    // MARK: - Life Cycle

    public init(
        mainSplitViewController: SplitViewController,
        mainTabBarController: TabBarController,
        newConversationBuilder: NewConversationBuilder,
        selfProfileBuilder: SelfProfileBuilder
    ) {
        splitViewController = mainSplitViewController
        tabBarController = mainTabBarController
        self.newConversationBuilder = newConversationBuilder
        self.selfProfileBuilder = selfProfileBuilder
    }

    // MARK: - Public Methods

    public func showConversationList(conversationFilter: (some MainConversationFilterRepresentable)?) async {
        defer {
            // switch to the conversation list tab
            tabBarController.selectedContent = .conversations

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
        guard mainSplitViewState == .expanded else { return }

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
        guard mainSplitViewState == .expanded else { return }

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

    public func showSettings() {
        tabBarController.selectedContent = .settings

        // In collapsed state switching the tab was all we needed to do.
        guard mainSplitViewState == .expanded else { return }

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

    public func showSelfProfile() {
        guard selfProfile == nil else { return }

        let rootViewController = selfProfileBuilder.build(mainCoordinator: self)
        let selfProfile = UINavigationController(rootViewController: rootViewController)
        selfProfile.modalPresentationStyle = .formSheet
        self.selfProfile = selfProfile

        splitViewController.present(selfProfile, animated: true)
    }

    public func showNewConversation() {
        guard newConversation == nil else { return }

        sidebar.selectedMenuItem = .init(.connect)

        let newConversation = newConversationBuilder.build(mainCoordinator: self)
        self.newConversation = newConversation

        if mainSplitViewState == .expanded {
            dismissConversationListIfNeeded()
            dismissArchiveIfNeeded()
            dismissSettingsIfNeeded()
            dismissSelfProfileIfNeeded()
            splitViewController.newConversation = newConversation
        } else {
            let navigationController = UINavigationController(rootViewController: newConversation)
            splitViewController.present(navigationController, animated: true)
        }
    }

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
            newConversation.navigationController?.presentingViewController?.dismiss(animated: true)
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

    // MARK: - UISplitViewControllerDelegate

    public func splitViewControllerDidCollapse(_ splitViewController: UISplitViewController) {
        guard let splitViewController = splitViewController as? SplitViewController,
              splitViewController === self.splitViewController
        else { return }

        // move view controllers from the split view controller's columns to the tab bar controller
        if let conversationListViewController = splitViewController.conversationList {
            splitViewController.conversationList = nil
            tabBarController.conversations = (conversationListViewController, nil)
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

        // take out the new conversation controller from the supplementary column's navigation
        // controller and put it into a separate one for modal presentation
        if let newConversation = splitViewController.newConversation {
            splitViewController.newConversation = nil
            let navigationController = UINavigationController(rootViewController: newConversation)
            splitViewController.present(navigationController, animated: false)
        }

        mainSplitViewState = .collapsed
        conversationList.splitViewInterface = .collapsed
    }

    public func splitViewControllerDidExpand(_ splitViewController: UISplitViewController) {
        guard let splitViewController = splitViewController as? SplitViewController,
              splitViewController === self.splitViewController
        else { return }

        // move view controllers from the tab bar controller to the supplementary column
        if tabBarController.selectedContent == .conversations {
            let conversationViewController = tabBarController.conversations!.conversationList
            tabBarController.conversations = nil
            splitViewController.conversationList = conversationViewController
        }

        // if the archived conversations view controller was visible, present it
        if tabBarController.selectedContent == .archive {
            let archive = tabBarController.archive
            tabBarController.archive = nil
            splitViewController.archive = archive
        }

        // if the settings were visible, present it
        if tabBarController.selectedContent == .settings {
            let settings = tabBarController.settings
            tabBarController.settings = nil
            splitViewController.settings = settings
        }

        // the new conversation view controller in collapsed mode is
        // presented in a separate navigation controller
        if let newConversation {
            let navigationController = newConversation.navigationController!
            navigationController.presentingViewController!.dismiss(animated: false)
            navigationController.viewControllers = []
            navigationController.view.layoutIfNeeded()
            splitViewController.newConversation = newConversation
        }

        mainSplitViewState = .expanded
        let conversationList = (tabBarController.conversations?.conversationList ?? splitViewController.conversationList)
        conversationList!.splitViewInterface = .expanded
    }

    // MARK: - UITabBarControllerDelegate

    public func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        guard let tabBarController = tabBarController as? TabBarController,
              tabBarController === self.tabBarController
        else { return }

        switch tabBarController.selectedContent {
        case .contacts, .folders:
            break // `.contacts` and `.folders` are removed for navigation overhaul

        case .conversations:
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

        case .archive:
            sidebar.selectedMenuItem = .init(.archive)

        case .settings:
            sidebar.selectedMenuItem = .init(.settings)
        }
    }
}
