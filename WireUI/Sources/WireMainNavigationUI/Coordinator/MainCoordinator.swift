//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

/// Manages the main navigation and the layout changes of the application after a successful login.
///
/// The MainCoordinator class is the central controller for the app's navigation and layout management.
/// It receives references to ``MainTabBarControllerProtocol`` and ``MainSplitViewControllerProtocol``
/// conforming instances and is responsible for managing transitions between different split layout states (collapsed
/// and expanded)
/// as well as handling navigation logic.
///
/// Both, the split view controller as well as the tab view controller actually install `UINavigationController`
/// instances and then put or remove the content view controllers into/from `viewControllers` array.

@MainActor
public final class MainCoordinator<Dependencies>: NSObject, MainCoordinatorProtocol, UISplitViewControllerDelegate,
    UITabBarControllerDelegate
    where Dependencies: MainCoordinatorDependenciesProtocol {

    // MARK: - Private Properties

    private weak var splitViewController: SplitViewController!
    private weak var tabBarController: TabBarController!

    private let conversationUIBuilder: Dependencies.ConversationUIBuilder
    private let settingsContentUIBuilder: Dependencies.SettingsContentUIBuilder

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

    private var meetingsUI: TabBarController.MeetingsUI! {
        switch mainSplitViewState {
        case .collapsed: tabBarController.meetingsUI
        case .expanded: splitViewController.meetingsUI
        }
    }

    private var settingsUI: TabBarController.SettingsUI! {
        switch mainSplitViewState {
        case .collapsed: tabBarController.settingsUI
        case .expanded: splitViewController.settingsUI
        }
    }

    private var filesUI: TabBarController.FilesUI! {
        switch mainSplitViewState {
        case .collapsed: tabBarController.filesUI
        case .expanded: splitViewController.filesUI
        }
    }

    // MARK: - Life Cycle

    public init(
        mainSplitViewController: SplitViewController,
        mainTabBarController: TabBarController,
        conversationUIBuilder: Dependencies.ConversationUIBuilder,
        settingsContentUIBuilder: Dependencies.SettingsContentUIBuilder
    ) {
        self.splitViewController = mainSplitViewController
        self.tabBarController = mainTabBarController
        self.conversationUIBuilder = conversationUIBuilder
        self.settingsContentUIBuilder = settingsContentUIBuilder

        super.init()

        mainSplitViewController.delegate = self
        mainTabBarController.delegate = self
    }

    // MARK: - Public Methods

    public func showConversationList(conversationFilter: ConversationFilter?) async {
        if mainSplitViewState == .expanded, splitViewController.splitBehavior == .overlay {
            splitViewController.hideSidebar()
        }

        await dismissPresentedViewController()

        // switch to the conversation list tab
        tabBarController.selectedContent = .conversations

        switch mainSplitViewState {
        case .collapsed:
            // if `showConversationList` is called while in collapsed mode, pop the conversation view controller
            tabBarController.setConversationUI(nil, animated: true)

        case .expanded:
            dismissArchiveIfNeeded()
            dismissSettingsIfNeeded()
            dismissMeetingsIfNeeded()
            dismissFilesIfNeeded()

            // Move the conversation list from the tab bar controller to the split view controller if needed.
            if let conversationListUI = tabBarController.conversationListUI {
                tabBarController.conversationListUI = nil
                splitViewController.conversationListUI = conversationListUI
            }

            if splitViewController.conversationUI == nil {
                // this line ensures that the no conversation placeholder is shown in case we switch from settings
                splitViewController.conversationUI = tabBarController.conversationUI
            }
        }

        applyConversationFilter(conversationFilter)
    }

    public func applyConversationFilter(_ conversationFilter: ConversationFilter?) {
        // apply the filter to the conversation list
        let conversationFilter = conversationFilter.map { ConversationFilter(mappingFrom: $0) }
        conversationListUI.conversationFilter = conversationFilter

        // set the right menu item in the sidebar
        let mainMenuItem = MainSidebarMenuItem(conversationFilter)
        sidebar.selectedMenuItem = .init(mainMenuItem)
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

        await dismissPresentedViewController()

        // In collapsed state switching the tab was all we needed to do.
        guard mainSplitViewState == .expanded else { return }

        dismissConversationListIfNeeded()
        dismissSettingsIfNeeded()
        dismissMeetingsIfNeeded()
        dismissFilesIfNeeded()

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

        await dismissPresentedViewController()
        tabBarController.selectedContent = .settings

        // In collapsed state switching the tab was all we needed to do.
        guard mainSplitViewState == .expanded else { return }

        dismissConversationListIfNeeded()
        dismissArchiveIfNeeded()
        dismissMeetingsIfNeeded()
        dismissFilesIfNeeded()

        // move the settings from the tab bar controller to the split view controller
        if let settingsUI = tabBarController.settingsUI {
            tabBarController.settingsUI = nil
            splitViewController.settingsUI = settingsUI
        }

        showSettingsContent(.init(.account)) // TODO: [WPB-11347] make the selection visible
    }

    public func showMeetings() async {
        if mainSplitViewState == .expanded, splitViewController.splitBehavior == .overlay {
            splitViewController.hideSidebar()
        }

        await dismissPresentedViewController()
        tabBarController.selectedContent = .meetings

        // In collapsed state switching the tab was all we needed to do.
        guard mainSplitViewState == .expanded else { return }

        dismissConversationListIfNeeded()
        dismissArchiveIfNeeded()
        dismissSettingsIfNeeded()
        dismissFilesIfNeeded()

        if let meetingsUI = tabBarController.meetingsUI {
            tabBarController.meetingsUI = nil
            splitViewController.meetingsUI = meetingsUI
        }
    }

    public func showFiles() async {
        if mainSplitViewState == .expanded, splitViewController.splitBehavior == .overlay {
            splitViewController.hideSidebar()
        }

        await dismissPresentedViewController()
        // switch to the files tab
        tabBarController.selectedContent = .files

        // In collapsed state switching the tab was all we needed to do.
        guard mainSplitViewState == .expanded else { return }

        dismissConversationListIfNeeded()
        dismissArchiveIfNeeded()
        dismissSettingsIfNeeded()

        // move the files from the tab bar controller to the split view controller
        if let filesUI = tabBarController.filesUI {
            tabBarController.filesUI = nil
            splitViewController.filesUI = filesUI
        }
    }

    public func showConversation(
        conversation: ConversationModel,
        message: ConversationMessageModel?
    ) {
        Task { [weak self] in
            guard let self else { return }
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
                let animated = tabBarController.conversationUI == nil
                tabBarController.setConversationUI(conversationUI, animated: animated)
            } else {
                splitViewController.conversationUI = conversationUI
            }
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

        let contentViewController = settingsContentUIBuilder.build(
            topLevelMenuItem: topLevelMenuItem,
            mainCoordinator: self
        )
        switch mainSplitViewState {
        case .collapsed:
            let animated = tabBarController.settingsContentUI == nil
            // TODO: [WPB-11347] make the selection visible in the settings ui overview list
            tabBarController.setSettingsContentUI(contentViewController, animated: animated)

        case .expanded:
            splitViewController.settingsContentUI = contentViewController
        }
    }

    public func hideSettingsContent() {
        tabBarController.setSettingsContentUI(nil, animated: true)
        splitViewController.settingsContentUI = nil
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

    private func dismissFilesIfNeeded() {
        // Move the files back to the tab bar controller if it's visible in the split view controller.
        if let filesUI = splitViewController.filesUI {
            splitViewController.filesUI = nil
            tabBarController.filesUI = filesUI
        }
    }

    public func dismissPresentedViewController() async {
        await withCheckedContinuation { continuation in
            if splitViewController != nil {
                splitViewController.dismiss(animated: true, completion: continuation.resume)
            }
        }
    }

    private func dismissMeetingsIfNeeded() {
        // Move the files back to the tab bar controller if it's visible in the split view controller.
        if let meetingsUI = splitViewController.meetingsUI {
            splitViewController.meetingsUI = nil
            tabBarController.meetingsUI = meetingsUI
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

        case .files:
            sidebar.selectedMenuItem = .init(.files)

        case .archive:
            sidebar.selectedMenuItem = .init(.archive)

        case .meetings:
            sidebar.selectedMenuItem = .init(.meetings)

        case .settings:
            sidebar.selectedMenuItem = .init(.settings)
        }
    }

    // MARK: - Legacy Helpers

    /// A notification should be shown if the conversation list is the topmost view controller.
    public var isConversationListVisible: Bool {
        guard splitViewController.presentedViewController == nil else { return false }

        return switch mainSplitViewState {
        case .collapsed:
            tabBarController.selectedContent == .conversations &&
                tabBarController.conversationUI == nil

        case .expanded:
            splitViewController.conversationListUI != nil
        }
    }

    /// A notification should not be shown if the conversation screen is the topmost view
    /// controller and the visible conversation matches the one of the notification.
    public var isConversationVisible: Bool {
        guard splitViewController.presentedViewController == nil else { return false }

        return switch mainSplitViewState {
        case .collapsed:
            tabBarController.selectedContent == .conversations &&
                tabBarController.conversationUI != nil

        case .expanded:
            splitViewController.conversationUI != nil
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
        case .channels:
            self = .channels
        case .oneOnOne:
            self = .oneOnOne
        case .unread:
            self = .unread
        case .mentions:
            self = .mentions
        case .replies:
            self = .replies
        case .drafts:
            self = .drafts
        case .folder:
            self = .folders
        }
    }
}
