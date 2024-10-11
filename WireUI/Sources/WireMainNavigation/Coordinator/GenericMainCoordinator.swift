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
public final class GenericMainCoordinator<

    SplitViewController: MainSplitViewControllerProtocol,
    ConversationBuilder: MainConversationBuilderProtocol,
    SettingsContentBuilder: MainSettingsContentBuilderProtocol,
    ConnectBuilder: MainCoordinatorInjectingViewControllerBuilder,
    CreateGroupConversationBuilder: MainCoordinatorInjectingViewControllerBuilder,
    SelfProfileBuilder: MainCoordinatorInjectingViewControllerBuilder,
    UserProfileBuilder: MainUserProfileBuilderProtocol

>: NSObject, MainCoordinatorProtocol, UISplitViewControllerDelegate, UITabBarControllerDelegate where

    ConversationBuilder.Conversation == SplitViewController.Conversation,

    ConnectBuilder.ConversationModel == SplitViewController.Conversation.ConversationModel,
    ConnectBuilder.ConversationMessageModel == ConversationBuilder.ConversationMessageModel,
    ConnectBuilder.SettingsBuilder == SettingsContentBuilder,
    ConnectBuilder.User == UserProfileBuilder.User,

    CreateGroupConversationBuilder.ConversationModel == SplitViewController.Conversation.ConversationModel,
    CreateGroupConversationBuilder.ConversationMessageModel == ConversationBuilder.ConversationMessageModel,
    CreateGroupConversationBuilder.SettingsBuilder == SettingsContentBuilder,
    CreateGroupConversationBuilder.User == UserProfileBuilder.User,

    SelfProfileBuilder.ConversationModel == SplitViewController.Conversation.ConversationModel,
    SelfProfileBuilder.ConversationMessageModel == ConversationBuilder.ConversationMessageModel,
    SelfProfileBuilder.SettingsBuilder == SettingsContentBuilder,
    SelfProfileBuilder.User == UserProfileBuilder.User
{
    // swiftlint:enable opening_brace

    public typealias ConversationList = SplitViewController.ConversationList
    public typealias Settings = SplitViewController.Settings
    public typealias TabBarController = SplitViewController.TabContainer

    public typealias ConversationModel = ConversationBuilder.ConversationModel
    public typealias ConversationMessageModel = ConversationBuilder.ConversationMessageModel

    public typealias Connect = ConnectBuilder.ViewController
    public typealias SelfProfile = SelfProfileBuilder.ViewController
    public typealias User = UserProfileBuilder.User

    // MARK: - Private Properties

    private weak var splitViewController: SplitViewController!
    private weak var tabBarController: TabBarController!

    private let conversationBuilder: ConversationBuilder
    private let settingsContentBuilder: SettingsContentBuilder

    private let connectBuilder: ConnectBuilder
    private weak var connect: Connect?

    private let createGroupConversationBuilder: CreateGroupConversationBuilder

    private var selfProfileBuilder: SelfProfileBuilder
    private weak var selfProfile: SelfProfile?

    private var userProfileBuilder: UserProfileBuilder

    private var mainSplitViewState: MainSplitViewState = .expanded

    // MARK: - Private Helpers

    private var sidebar: SplitViewController.Sidebar! {
        splitViewController.sidebar
    }

    private var conversationList: TabBarController.ConversationList! {
        switch mainSplitViewState {
        case .collapsed: tabBarController.conversationList
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
        conversationBuilder: ConversationBuilder,
        settingsContentBuilder: SettingsContentBuilder,
        connectBuilder: ConnectBuilder,
        createGroupConversationBuilder: CreateGroupConversationBuilder,
        selfProfileBuilder: SelfProfileBuilder,
        userProfileBuilder: UserProfileBuilder
    ) {
        splitViewController = mainSplitViewController
        tabBarController = mainTabBarController
        self.conversationBuilder = conversationBuilder
        self.settingsContentBuilder = settingsContentBuilder
        self.connectBuilder = connectBuilder
        self.createGroupConversationBuilder = createGroupConversationBuilder
        self.selfProfileBuilder = selfProfileBuilder
        self.userProfileBuilder = userProfileBuilder

        super.init()

        mainSplitViewController.delegate = self
        mainTabBarController.delegate = self
    }

    // MARK: - Public Methods

    public func showConversationList(conversationFilter: ConversationList.ConversationFilter?) async {
        defer {
            // switch to the conversation list tab
            tabBarController.selectedContent = .conversations

            switch mainSplitViewState {
            case .collapsed:
                // if `showConversationList` is called while in collapsed mode, pop the conversation view controller
                tabBarController.setConversation(nil, animated: true)
            case .expanded:
                if splitViewController.conversation == nil {
                    // this line ensures that the no conversation placeholder is shown in case we switch from settings
                    splitViewController.conversation = tabBarController.conversation
                }
            }

            // apply the filter to the conversation list
            let conversationFilter = conversationFilter.map { ConversationFilter(mappingFrom: $0) }
            conversationList.conversationFilter = conversationFilter

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
        if let conversationList = tabBarController.conversationList {
            tabBarController.conversationList = nil
            splitViewController.conversationList = conversationList
        }
    }

    public func showArchive() async {
        if mainSplitViewState == .expanded, splitViewController.splitBehavior == .overlay {
            splitViewController.hideSidebar()
        }

        // switch to the archive tab
        tabBarController.selectedContent = .archive

        if mainSplitViewState == .collapsed, tabBarController.conversation != nil {
            // if the method is called while in collapsed mode, pop the conversation view controller
            tabBarController.setConversation(nil, animated: false)
        } else if splitViewController.conversation == nil {
            // display either the conversation or the placeholder in the secondary column
            splitViewController.conversation = tabBarController.conversation
        }

        // In collapsed state switching the tab was all we needed to do.
        guard mainSplitViewState == .expanded else { return }

        dismissConversationListIfNeeded()
        dismissSettingsIfNeeded()
        await dismissPresentedViewController()

        // move the archive from the tab bar controller to the split view controller
        if let archive = tabBarController.archive {
            tabBarController.archive = nil
            splitViewController.archive = archive
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
        if let settings = tabBarController.settings {
            tabBarController.settings = nil
            splitViewController.settings = settings
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

        let conversation = conversationBuilder.build(
            conversation: conversation,
            message: nil,
            mainCoordinator: self
        )
        if mainSplitViewState == .collapsed {
            tabBarController.selectedContent = .conversations
            tabBarController.setConversation(conversation, animated: true)
        } else {
            splitViewController.conversation = conversation
        }
    }

    public func hideConversation() {
        tabBarController.setConversation(nil, animated: true)
        splitViewController.conversation = nil
    }

    public func showSettingsContent(_ topLevelMenuItem: SettingsContentBuilder.TopLevelMenuItem) {
        if mainSplitViewState == .expanded, splitViewController.splitBehavior == .overlay {
            splitViewController.hideSidebar()
        }

        if let conversation = splitViewController.conversation {
            splitViewController.conversation = nil
            tabBarController.conversation = conversation
        }

        let contentViewController = settingsContentBuilder.build(topLevelMenuItem: topLevelMenuItem, mainCoordinator: self)
        switch mainSplitViewState {
        case .collapsed:
            tabBarController.setSettingsContent(contentViewController, animated: true) // TODO: [WPB-11347] make the selection visible
        case .expanded:
            splitViewController.settingsContent = contentViewController
        }
    }

    public func hideSettingsContent() {
        tabBarController.setSettingsContent(nil, animated: true)
        splitViewController.settingsContent = nil
    }

    public func showSelfProfile() async {
        guard selfProfile == nil else {
            // Once WireLogger is available to Swift packages use it here instead.
            return assertionFailure()
        }

        if mainSplitViewState == .expanded, splitViewController.splitBehavior == .overlay {
            splitViewController.hideSidebar()
        }

        let selfProfile = selfProfileBuilder.build(mainCoordinator: self)
        selfProfile.modalPresentationStyle = .formSheet
        self.selfProfile = selfProfile

        await dismissPresentedViewController()
        await withCheckedContinuation { continuation in
            splitViewController.present(selfProfile, animated: true, completion: continuation.resume)
        }
    }

    public func showUserProfile(user: User) async {
        if mainSplitViewState == .expanded, splitViewController.splitBehavior == .overlay {
            splitViewController.hideSidebar()
        }

        let userProfile = userProfileBuilder.build(
            user: user,
            mainCoordinator: self
        )
        await presentViewController(userProfile)
    }

    public func showConnect() async {
        guard connect == nil else {
            // Once WireLogger is available to Swift packages use it here instead.
            return assertionFailure()
        }

        if mainSplitViewState == .expanded, splitViewController.splitBehavior == .overlay {
            splitViewController.hideSidebar()
        }

        let connect = connectBuilder.build(mainCoordinator: self)
        connect.modalPresentationStyle = .formSheet
        self.connect = connect
        await presentViewController(connect)
    }

    public func showCreateGroupConversation() async {
        if mainSplitViewState == .expanded, splitViewController.splitBehavior == .overlay {
            splitViewController.hideSidebar()
        }

        let createGroupConversation = createGroupConversationBuilder.build(mainCoordinator: self)
        createGroupConversation.modalPresentationStyle = .formSheet
        await presentViewController(createGroupConversation)
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
        if let conversationList = splitViewController.conversationList {
            splitViewController.conversationList = nil
            tabBarController.conversationList = conversationList
        }
    }

    private func dismissArchiveIfNeeded() {
        // Move the archive back to the tab bar controller if needed.
        if let archive = splitViewController.archive {
            splitViewController.archive = nil
            tabBarController.archive = archive
        }
    }

    private func dismissSettingsIfNeeded() {
        // Move the settings back to the tab bar controller if it's visible in the split view controller.
        if let settings = splitViewController.settings {
            splitViewController.settings = nil
            tabBarController.settings = settings
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
        if let conversationListViewController = splitViewController.conversationList {
            splitViewController.conversationList = nil
            tabBarController.conversationList = conversationListViewController

            if let conversation = splitViewController.conversation {
                splitViewController.conversation = nil
                tabBarController.conversation = conversation
            }
        } else {
            // dismiss the conversation if archive or connect has been visible
            // and there is still a conversation presented in the secondary column
            splitViewController.conversation = nil
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

            if let settingsContent = splitViewController.settingsContent {
                splitViewController.settingsContent = nil
                tabBarController.settingsContent = settingsContent
            }
        }

        mainSplitViewState = .collapsed
        conversationList.mainSplitViewState = .collapsed
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
            let conversationViewController = tabBarController.conversationList
            tabBarController.conversationList = nil
            splitViewController.conversationList = conversationViewController

            if let conversation = tabBarController.conversation {
                tabBarController.conversation = nil
                splitViewController.conversation = conversation
            }
        }

        // if the archived conversations view controller was visible, present it
        if tabBarController.selectedContent == .archive {
            let archive = tabBarController.archive
            tabBarController.archive = nil
            splitViewController.archive = archive
        }

        // if the settings were visible, present it
        var settingsContentToSelect: SettingsContentBuilder.TopLevelMenuItem?
        if tabBarController.selectedContent == .settings {
            let settings = tabBarController.settings
            tabBarController.settings = nil
            splitViewController.settings = settings

            if let settingsContent = tabBarController.settingsContent {
                tabBarController.settingsContent = nil
                splitViewController.settingsContent = settingsContent
            } else {
                settingsContentToSelect = .init(.account)
            }
        }

        mainSplitViewState = .expanded
        let conversationList = tabBarController.conversationList ?? splitViewController.conversationList
        conversationList!.mainSplitViewState = .expanded
        if let settingsContentToSelect {
            showSettingsContent(settingsContentToSelect) // TODO: [WPB-11347] make the selection visible
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
            let mainMenuItem = MainSidebarMenuItem(conversationList.conversationFilter)
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
            splitViewController.conversationList == nil
        } else {
            tabBarController.conversationList == nil
        }
    }

    public var isConversationVisible: Bool {
        if mainSplitViewState == .expanded {
            splitViewController.conversation == nil
        } else {
            tabBarController.conversation == nil
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
