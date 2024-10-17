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

// swiftlint:disable opening_brace

/// Manages the main navigation and the layout changes of the application after a successful login.
///
/// The MainCoordinator class is the central controller for the app's navigation and layout management.
/// It receives references to ``MainTabBarControllerProtocol`` and ``MainSplitViewControllerProtocol``
/// conforming instances and is responsible for managing transitions between different split layout states (collapsed and expanded)
/// as well as handling navigation logic.
///
/// Both, the split view controller as well as the tab view controller actually install `UINavigationController`
/// instances and then put or remove the content view controllers into/from `viewControllers` array.

@MainActor
public final class MainCoordinator<Dependencies>: NSObject, MainCoordinatorProtocol, UISplitViewControllerDelegate, UITabBarControllerDelegate
    where Dependencies: MainCoordinatorDependencies
{
    // swiftlint:enable opening_brace

    // MARK: - Private Properties

    private weak var splitViewController: SplitViewController!
    private weak var tabBarController: TabBarController!

    private let conversationUIBuilder: Dependencies.ConversationUIBuilder
    private let settingsContentUIBuilder: Dependencies.SettingsContentUIBuilder
    private let connectUIBuilder: Dependencies.ConnectUIBuilder
    private let createGroupConversationUIBuilder: Dependencies.CreateGroupConversationUIBuilder
    private var selfProfileUIBuilder: Dependencies.SelfProfileUIBuilder
    private var userProfileUIBuilder: Dependencies.UserProfileUIBuilder

    public private(set) var mainSplitViewState: MainSplitViewState = .expanded

    // MARK: - Private Helpers

    private var sidebar: SplitViewController.Sidebar! {
        splitViewController.sidebar
    }

    private var conversationListUI: TabBarController.ConversationListUI! {
        switch mainSplitViewState {
        case .collapsed: tabBarController.conversationListUI
        case .expanded: splitViewController.conversationListUI
        }
    }

    private var archiveUI: TabBarController.ArchiveUI! {
        switch mainSplitViewState {
        case .collapsed: tabBarController.archiveUI
        case .expanded: splitViewController.archiveUI
        }
    }

    private var settingsUI: TabBarController.SettingsUI! {
        switch mainSplitViewState {
        case .collapsed: tabBarController.settingsUI
        case .expanded: splitViewController.settingsUI
        }
    }

    // MARK: - Life Cycle

    public init(
        mainSplitViewController: SplitViewController,
        mainTabBarController: TabBarController,
        conversationUIBuilder: Dependencies.ConversationUIBuilder,
        settingsContentUIBuilder: Dependencies.SettingsContentUIBuilder,
        connectUIBuilder: Dependencies.ConnectUIBuilder,
        createGroupConversationUIBuilder: Dependencies.CreateGroupConversationUIBuilder,
        selfProfileUIBuilder: Dependencies.SelfProfileUIBuilder,
        userProfileUIBuilder: Dependencies.UserProfileUIBuilder
    ) {
        splitViewController = mainSplitViewController
        tabBarController = mainTabBarController
        self.conversationUIBuilder = conversationUIBuilder
        self.settingsContentUIBuilder = settingsContentUIBuilder
        self.connectUIBuilder = connectUIBuilder
        self.createGroupConversationUIBuilder = createGroupConversationUIBuilder
        self.selfProfileUIBuilder = selfProfileUIBuilder
        self.userProfileUIBuilder = userProfileUIBuilder

        super.init()

        mainSplitViewController.delegate = self
        mainTabBarController.delegate = self
    }

    // MARK: - Public Methods

    public func showConversationList(conversationFilter: ConversationFilter?) async {
        defer {
            // switch to the conversation list tab
            tabBarController.selectedContent = .conversations

            switch mainSplitViewState {
            case .collapsed:
                // if `showConversationList` is called while in collapsed mode, pop the conversation view controller
                tabBarController.setConversationUI(nil, animated: true)
            case .expanded:
                if splitViewController.conversationUI == nil {
                    // this line ensures that the no conversation placeholder is shown in case we switch from settings
                    splitViewController.conversationUI = tabBarController.conversationUI
                }
            }

            // apply the filter to the conversation list
            let conversationFilter = conversationFilter.map { ConversationFilter(mappingFrom: $0) }
            conversationListUI.conversationFilter = conversationFilter

            // set the right menu item in the sidebar
            let mainMenuItem = MainSidebarMenuItem(conversationFilter)
            sidebar.selectedMenuItem = .init(mainMenuItem)
        }

        if mainSplitViewState == .expanded, splitViewController.splitBehavior == .overlay {
            splitViewController.hideSidebar()
        }

        // In collapsed state switching the tab was all we needed to do.
        guard mainSplitViewState == .expanded else { return }

        dismissArchiveIfNeeded()
        dismissSettingsIfNeeded()
        await dismissPresentedViewController()

        // Move the conversation list from the tab bar controller to the split view controller if needed.
        if let conversationListUI = tabBarController.conversationListUI {
            tabBarController.conversationListUI = nil
            splitViewController.conversationListUI = conversationListUI
        }
    }

    public func showArchive() async {
        if mainSplitViewState == .expanded, splitViewController.splitBehavior == .overlay {
            splitViewController.hideSidebar()
        }

        // switch to the archive tab
        tabBarController.selectedContent = .archive

        if mainSplitViewState == .collapsed, tabBarController.conversationUI != nil {
            // if the method is called while in collapsed mode, pop the conversation view controller
            tabBarController.setConversationUI(nil, animated: false)
        } else if splitViewController.conversationUI == nil {
            // display either the conversation or the placeholder in the secondary column
            splitViewController.conversationUI = tabBarController.conversationUI
        }

        // In collapsed state switching the tab was all we needed to do.
        guard mainSplitViewState == .expanded else { return }

        dismissConversationListIfNeeded()
        dismissSettingsIfNeeded()
        await dismissPresentedViewController()

        // move the archive from the tab bar controller to the split view controller
        if let archiveUI = tabBarController.archiveUI {
            tabBarController.archiveUI = nil
            splitViewController.archiveUI = archiveUI
        }
    }

    public func showSettings() async {
        if mainSplitViewState == .expanded, splitViewController.splitBehavior == .overlay {
            splitViewController.hideSidebar()
        }

        tabBarController.selectedContent = .settings

        // In collapsed state switching the tab was all we needed to do.
        guard mainSplitViewState == .expanded else { return }

        dismissConversationListIfNeeded()
        dismissArchiveIfNeeded()
        await dismissPresentedViewController()

        // move the settings from the tab bar controller to the split view controller
        if let settingsUI = tabBarController.settingsUI {
            tabBarController.settingsUI = nil
            splitViewController.settingsUI = settingsUI
        }

        showSettingsContent(.init(.account)) // TODO: [WPB-11347] make the selection visible
    }

    public func showConversation(
        conversation: ConversationModel,
        message: ConversationMessageModel?
    ) async {
        if mainSplitViewState == .expanded, splitViewController.splitBehavior == .overlay {
            splitViewController.hideSidebar()
        }

        await dismissPresentedViewController()

        let conversationUI = conversationUIBuilder.build(
            conversation: conversation,
            message: nil,
            mainCoordinator: self
        )
        if mainSplitViewState == .collapsed {
            tabBarController.selectedContent = .conversations
            tabBarController.setConversationUI(conversationUI, animated: true)
        } else {
            splitViewController.conversationUI = conversationUI
        }
    }

    public func hideConversation() {
        tabBarController.setConversationUI(nil, animated: true)
        splitViewController.conversationUI = nil
    }

    public func showSettingsContent(_ topLevelMenuItem: SettingsTopLevelMenuItem) {
        if mainSplitViewState == .expanded, splitViewController.splitBehavior == .overlay {
            splitViewController.hideSidebar()
        }

        if let conversationUI = splitViewController.conversationUI {
            splitViewController.conversationUI = nil
            tabBarController.conversationUI = conversationUI
        }

        let contentViewController = settingsContentUIBuilder.build(topLevelMenuItem: topLevelMenuItem, mainCoordinator: self)
        switch mainSplitViewState {
        case .collapsed:
            tabBarController.setSettingsContentUI(contentViewController, animated: true) // TODO: [WPB-11347] make the selection visible
        case .expanded:
            splitViewController.settingsContentUI = contentViewController
        }
    }

    public func hideSettingsContent() {
        tabBarController.setSettingsContentUI(nil, animated: true)
        splitViewController.settingsContentUI = nil
    }

    public func showSelfProfile() async {
        if mainSplitViewState == .expanded, splitViewController.splitBehavior == .overlay {
            splitViewController.hideSidebar()
        }

        let selfProfileUI = selfProfileUIBuilder.build(mainCoordinator: self)
        selfProfileUI.modalPresentationStyle = .formSheet

        await dismissPresentedViewController()
        await withCheckedContinuation { continuation in
            splitViewController.present(selfProfileUI, animated: true, completion: continuation.resume)
        }
    }

    public func showUserProfile(user: User) async {
        if mainSplitViewState == .expanded, splitViewController.splitBehavior == .overlay {
            splitViewController.hideSidebar()
        }

        let userProfileUI = userProfileUIBuilder.build(
            user: user,
            mainCoordinator: self
        )
        await presentViewController(userProfileUI)
    }

    public func showConnect() async {
        if mainSplitViewState == .expanded, splitViewController.splitBehavior == .overlay {
            splitViewController.hideSidebar()
        }

        let connectUI = connectUIBuilder.build(mainCoordinator: self)
        connectUI.modalPresentationStyle = .formSheet
        await presentViewController(connectUI)
    }

    public func showCreateGroupConversation() async {
        if mainSplitViewState == .expanded, splitViewController.splitBehavior == .overlay {
            splitViewController.hideSidebar()
        }

        let createGroupConversationUI = createGroupConversationUIBuilder.build(mainCoordinator: self)
        createGroupConversationUI.modalPresentationStyle = .formSheet
        await presentViewController(createGroupConversationUI)
    }

    public func presentViewController(_ viewController: UIViewController) async {
        if mainSplitViewState == .expanded, splitViewController.splitBehavior == .overlay {
            splitViewController.hideSidebar()
        }

        await dismissPresentedViewController()
        await withCheckedContinuation { continuation in
            splitViewController.present(viewController, animated: true, completion: continuation.resume)
        }
    }

    private func dismissConversationListIfNeeded() {
        // if the conversation list is currently visible, move it back to the tab bar controller
        if let conversationListUI = splitViewController.conversationListUI {
            splitViewController.conversationListUI = nil
            tabBarController.conversationListUI = conversationListUI
        }
    }

    private func dismissArchiveIfNeeded() {
        // Move the archive back to the tab bar controller if needed.
        if let archive = splitViewController.archiveUI {
            splitViewController.archiveUI = nil
            tabBarController.archiveUI = archive
        }
    }

    private func dismissSettingsIfNeeded() {
        // Move the settings back to the tab bar controller if it's visible in the split view controller.
        if let settingsUI = splitViewController.settingsUI {
            splitViewController.settingsUI = nil
            tabBarController.settingsUI = settingsUI
        }
    }

    public func dismissPresentedViewController() async {
        await withCheckedContinuation { continuation in
            splitViewController.dismiss(animated: true, completion: continuation.resume)
        }
    }

    // MARK: - UISplitViewControllerDelegate

    public func splitViewControllerDidCollapse(_ splitViewController: UISplitViewController) {
        guard let splitViewController = splitViewController as? SplitViewController,
              splitViewController === self.splitViewController
        else {
            // Once WireLogger is available to Swift packages use it here instead.
            return assertionFailure()
        }

        // move view controllers from the split view controller's columns to the tab bar controller
        if let conversationListViewController = splitViewController.conversationListUI {
            splitViewController.conversationListUI = nil
            tabBarController.conversationListUI = conversationListViewController

            if let conversationUI = splitViewController.conversationUI {
                splitViewController.conversationUI = nil
                tabBarController.conversationUI = conversationUI
            }
        } else {
            // dismiss the conversation if archive or connect has been visible
            // and there is still a conversation presented in the secondary column
            splitViewController.conversationUI = nil
        }

        // move the archived conversations list back to the tab bar controller if needed
        if let archiveUI = splitViewController.archiveUI {
            splitViewController.archiveUI = nil
            tabBarController.archiveUI = archiveUI
        }

        // move the settings back to the tab bar controller if needed
        if let settingsUI = splitViewController.settingsUI {
            splitViewController.settingsUI = nil
            tabBarController.settingsUI = settingsUI

            if let settingsContentUI = splitViewController.settingsContentUI {
                splitViewController.settingsContentUI = nil
                tabBarController.settingsContentUI = settingsContentUI
            }
        }

        mainSplitViewState = .collapsed
        conversationListUI.mainSplitViewState = .collapsed
    }

    public func splitViewControllerDidExpand(_ splitViewController: UISplitViewController) {
        guard let splitViewController = splitViewController as? SplitViewController,
              splitViewController === self.splitViewController
        else {
            // Once WireLogger is available to Swift packages use it here instead.
            return assertionFailure()
        }

        // move view controllers from the tab bar controller to the supplementary column
        if tabBarController.selectedContent == .conversations {
            let conversationViewController = tabBarController.conversationListUI
            tabBarController.conversationListUI = nil
            splitViewController.conversationListUI = conversationViewController

            if let conversationUI = tabBarController.conversationUI {
                tabBarController.conversationUI = nil
                splitViewController.conversationUI = conversationUI
            }
        }

        // if the archived conversations view controller was visible, present it
        if tabBarController.selectedContent == .archive {
            let archiveUI = tabBarController.archiveUI
            tabBarController.archiveUI = nil
            splitViewController.archiveUI = archiveUI
        }

        // if the settings were visible, present it
        var settingsContentUIToSelect: Dependencies.SettingsContentUIBuilder.TopLevelMenuItem?
        if tabBarController.selectedContent == .settings {
            let settingsUI = tabBarController.settingsUI
            tabBarController.settingsUI = nil
            splitViewController.settingsUI = settingsUI

            if let settingsContentUI = tabBarController.settingsContentUI {
                tabBarController.settingsContentUI = nil
                splitViewController.settingsContentUI = settingsContentUI
            } else {
                settingsContentUIToSelect = .init(.account)
            }
        }

        mainSplitViewState = .expanded
        let conversationListUI = tabBarController.conversationListUI ?? splitViewController.conversationListUI
        conversationListUI!.mainSplitViewState = .expanded
        if let settingsContentUIToSelect {
            showSettingsContent(settingsContentUIToSelect) // TODO: [WPB-11347] make the selection visible
        }
    }

    // MARK: - UITabBarControllerDelegate

    public func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        guard let tabBarController = tabBarController as? TabBarController,
              tabBarController === self.tabBarController
        else {
            // Once WireLogger is available to Swift packages use it here instead.
            return assertionFailure()
        }

        switch tabBarController.selectedContent {
        case .conversations:
            let mainMenuItem = MainSidebarMenuItem(conversationListUI.conversationFilter)
            sidebar.selectedMenuItem = .init(mainMenuItem)

        case .archive:
            sidebar.selectedMenuItem = .init(.archive)

        case .settings:
            sidebar.selectedMenuItem = .init(.settings)
        }
    }

    // MARK: - Legacy Helpers

    public var isConversationListVisible: Bool {
        if mainSplitViewState == .expanded {
            splitViewController.conversationListUI == nil
        } else {
            tabBarController.conversationListUI == nil
        }
    }

    public var isConversationVisible: Bool {
        if mainSplitViewState == .expanded {
            splitViewController.conversationUI == nil
        } else {
            tabBarController.conversationUI == nil
        }
    }
}

// MARK: - MainSidebarMenuItem + MainConversationFilter

private extension MainSidebarMenuItem {

    init(_ filter: (some MainConversationFilterRepresentable)?) {
        switch filter?.mapToMainConversationFilter() {
        case .none:
            self = .all
        case .favorites:
            self = .favorites
        case .groups:
            self = .groups
        case .oneOnOne:
            self = .oneOnOne
        }
    }
}
