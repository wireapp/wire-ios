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

import SwiftUI

// swiftlint:disable opening_brace

public final class MainSplitViewController<Sidebar, TabContainer>: UISplitViewController, MainSplitViewControllerProtocol where
    Sidebar: MainSidebarProtocol,
    TabContainer: MainTabBarControllerProtocol
{
    // swiftlint:enable opening_brace

    public typealias ConversationList = TabContainer.ConversationList
    public typealias Archive = TabContainer.Archive
    public typealias Settings = TabContainer.Settings

    public typealias Conversation = TabContainer.Conversation
    public typealias SettingsContent = TabContainer.SettingsContent

    public typealias Connect = UIViewController

    public typealias NoConversationPlaceholderBuilder = () -> UIViewController

    // TODO: rename
    // also it now contains the remaining with next to sidebar and conversation list
    private let sidebarVisibilityThreshold: CGFloat = 360

    // MARK: - Primary Column

    public private(set) weak var sidebar: Sidebar!

    // MARK: - Supplementary Column

    public var conversationList: ConversationList? {
        get { _conversationList }
        set { setConversationList(newValue, animated: false) }
    }

    public var archive: Archive? {
        get { _archive }
        set { setArchive(newValue, animated: false) }
    }

    public var connect: Connect? {
        get { _connect }
        set { setConnect(newValue, animated: false) }
    }

    public var settings: Settings? {
        get { _settings }
        set { setSettings(newValue, animated: false) }
    }

    // MARK: - Secondary Column

    public var conversation: Conversation? {
        get { _conversation }
        set { setConversation(newValue, animated: false) }
    }

    public var settingsContent: SettingsContent? {
        get { _settingsContent }
        set { setSettingsContent(newValue, animated: false) }
    }

    // MARK: - Compact/Collapsed

    public private(set) weak var tabContainer: TabContainer!

    // MARK: - Private Properties

    /// This view controller is displayed when no conversation in the list is selected.
    private let noConversationPlaceholder: UIViewController

    /// The required behavior wasn't achievable with the native split view controller.
    /// Therefore this simple split view container view controller combines conversation list and conversation
    /// or settings menu and settings content.
    private weak var splitLayoutContainer: DoubleColumnContainerViewController!

    private weak var _conversationList: ConversationList?
    private weak var _archive: Archive?
    private weak var _settings: Settings?

    private weak var _conversation: Conversation?
    private weak var _settingsContent: SettingsContent?

    private weak var _connect: Connect?

    // MARK: - Initialization

    public init(
        sidebar: @autoclosure () -> Sidebar,
        noConversationPlaceholder: @autoclosure NoConversationPlaceholderBuilder,
        tabContainer: @autoclosure () -> TabContainer
    ) {
        let sidebar = sidebar()
        let noConversationPlaceholder = noConversationPlaceholder()
        let tabContainer = tabContainer()
        let splitLayoutContainer = DoubleColumnContainerViewController()

        self.noConversationPlaceholder = noConversationPlaceholder
        self.splitLayoutContainer = splitLayoutContainer
        splitLayoutContainer.secondaryNavigationController.viewControllers = [noConversationPlaceholder]

        self.sidebar = sidebar
        self.tabContainer = tabContainer

        super.init(style: .doubleColumn)

        preferredSplitBehavior = .overlay
        preferredDisplayMode = .oneOverSecondary
        preferredPrimaryColumnWidth = 260
        splitLayoutContainer.primaryColumnWidth = 320

        setViewController(sidebar, for: .primary)
        setViewController(splitLayoutContainer, for: .secondary)
        setViewController(tabContainer, for: .compact)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setPreferredSplitBehaviorAndDisplayMode(basedOn: view.frame.size.width)
    }

    override public func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        setPreferredSplitBehaviorAndDisplayMode(basedOn: size.width)
    }

    private func setPreferredSplitBehaviorAndDisplayMode(basedOn width: CGFloat) {
        let remainingWidth = width - preferredPrimaryColumnWidth - splitLayoutContainer.primaryColumnWidth

        // remember if the sidebar was visible or not
        let isSidebarVisible = displayMode != .secondaryOnly
        if remainingWidth >= sidebarVisibilityThreshold {
            preferredSplitBehavior = .tile
            preferredDisplayMode = isSidebarVisible ? .oneBesideSecondary : .secondaryOnly
        } else {
            preferredSplitBehavior = .overlay
            preferredDisplayMode = isSidebarVisible ? .oneOverSecondary : .secondaryOnly
        }
    }

    // MARK: - Accessors

    private func setConversationList(_ conversationList: ConversationList?, animated: Bool) {
        _conversationList = conversationList

        let viewControllers = [conversationList].compactMap { $0 }
        splitLayoutContainer.primaryNavigationController.setViewControllers(viewControllers, animated: animated)
        splitLayoutContainer.primaryNavigationController.view.layoutIfNeeded()
    }

    private func setArchive(_ archive: Archive?, animated: Bool) {
        _archive = archive

        let viewControllers = [archive].compactMap { $0 }
        splitLayoutContainer.primaryNavigationController.setViewControllers(viewControllers, animated: animated)
        splitLayoutContainer.primaryNavigationController.view.layoutIfNeeded()
    }

    private func setConnect(_ connect: Connect?, animated: Bool) {
        _connect = connect

        let viewControllers = [connect].compactMap { $0 }
        splitLayoutContainer.primaryNavigationController.setViewControllers(viewControllers, animated: animated)
        splitLayoutContainer.primaryNavigationController.view.layoutIfNeeded()
    }

    private func setSettings(_ settings: Settings?, animated: Bool) {
        _settings = settings

        let viewControllers = [settings].compactMap { $0 }
        splitLayoutContainer.primaryNavigationController.setViewControllers(viewControllers, animated: animated)
        splitLayoutContainer.primaryNavigationController.view.layoutIfNeeded()
    }

    private func setConversation(_ conversation: Conversation?, animated: Bool) {
        _conversation = conversation

        let viewControllers = [conversation ?? noConversationPlaceholder].compactMap { $0 }
        splitLayoutContainer.secondaryNavigationController.setViewControllers(viewControllers, animated: animated)
        splitLayoutContainer.secondaryNavigationController.view.layoutIfNeeded()
    }

    private func setSettingsContent(_ settingsContent: SettingsContent?, animated: Bool) {
        _settingsContent = settingsContent

        let viewControllers = [settingsContent].compactMap { $0 }
        splitLayoutContainer.secondaryNavigationController.setViewControllers(viewControllers, animated: animated)
        splitLayoutContainer.secondaryNavigationController.view.layoutIfNeeded()
    }
}

// MARK: - Previews

@available(iOS 17, *)
#Preview {
    MainSplitViewControllerPreview()
}
