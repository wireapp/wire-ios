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

public final class MainSplitViewController<Sidebar, TabController>: UISplitViewController, MainSplitViewControllerProtocol where
    Sidebar: MainSidebarProtocol,
    TabController: MainTabBarControllerProtocol
{
    // swiftlint:enable opening_brace

    private let secondaryColumnMinWidth: CGFloat = 360

    /// This property corresponds only to the border of the nested custom container view controller.
    public var borderColor: UIColor = .gray {
        didSet { splitLayoutContainer.borderColor = borderColor }
    }

    // MARK: - Primary Column

    public private(set) weak var sidebar: Sidebar!

    // MARK: - Supplementary Column

    public var conversationListUI: ConversationListUI? {
        get { _conversationListUI }
        set { setConversationListUI(newValue, animated: false) }
    }

    public var archiveUI: ArchiveUI? {
        get { _archiveUI }
        set { setArchiveUI(newValue, animated: false) }
    }

    public var settingsUI: SettingsUI? {
        get { _settingsUI }
        set { setSettingsUI(newValue, animated: false) }
    }

    // MARK: - Secondary Column

    public var conversationUI: ConversationUI? {
        get { _conversationUI }
        set { setConversationUI(newValue, animated: false) }
    }

    public var settingsContentUI: SettingsContentUI? {
        get { _settingsContentUI }
        set { setSettingsContentUI(newValue, animated: false) }
    }

    // MARK: - Compact/Collapsed

    public private(set) weak var tabController: TabController!

    // MARK: - Private Properties

    /// This view controller is displayed when no conversation in the list is selected.
    private let noConversationPlaceholder: UIViewController

    /// The required behavior wasn't achievable with the native split view controller.
    /// Therefore this simple split view container view controller combines conversation list and conversation
    /// or settings menu and settings content.
    private weak var splitLayoutContainer: DoubleColumnContainerViewController!

    private weak var _conversationListUI: ConversationListUI?
    private weak var _archiveUI: ArchiveUI?
    private weak var _settingsUI: SettingsUI?

    private weak var _conversationUI: ConversationUI?
    private weak var _settingsContentUI: SettingsContentUI?

    // MARK: - Initialization

    public init(
        sidebar: @autoclosure () -> Sidebar,
        noConversationPlaceholder: @autoclosure NoConversationPlaceholderBuilder,
        tabController: @autoclosure () -> TabBarController
    ) {
        let sidebar = sidebar()
        let noConversationPlaceholder = noConversationPlaceholder()
        let tabController = tabController()
        let splitLayoutContainer = DoubleColumnContainerViewController()

        self.noConversationPlaceholder = noConversationPlaceholder
        self.splitLayoutContainer = splitLayoutContainer
        splitLayoutContainer.secondaryNavigationController.viewControllers = [noConversationPlaceholder]
        splitLayoutContainer.borderColor = borderColor

        self.sidebar = sidebar
        self.tabController = tabController

        super.init(style: .doubleColumn)

        preferredSplitBehavior = .overlay
        preferredDisplayMode = .oneOverSecondary
        preferredPrimaryColumnWidth = 260
        splitLayoutContainer.primaryColumnWidth = 320

        setViewController(sidebar, for: .primary)
        setViewController(splitLayoutContainer, for: .secondary)
        setViewController(tabController, for: .compact)
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
        if remainingWidth >= secondaryColumnMinWidth {
            preferredSplitBehavior = .tile
            preferredDisplayMode = isSidebarVisible ? .oneBesideSecondary : .secondaryOnly
        } else {
            preferredSplitBehavior = .overlay
            preferredDisplayMode = isSidebarVisible ? .oneOverSecondary : .secondaryOnly
        }
    }

    public func hideSidebar() {
        hide(.primary)
    }

    // MARK: - Accessors

    private func setConversationListUI(_ conversationListUI: ConversationListUI?, animated: Bool) {
        _conversationListUI = conversationListUI

        let viewControllers = [conversationListUI].compactMap { $0 }
        splitLayoutContainer.primaryNavigationController.setViewControllers(viewControllers, animated: animated)
        splitLayoutContainer.primaryNavigationController.view.layoutIfNeeded()
    }

    private func setArchiveUI(_ archiveUI: ArchiveUI?, animated: Bool) {
        _archiveUI = archiveUI

        let viewControllers = [archiveUI].compactMap { $0 }
        splitLayoutContainer.primaryNavigationController.setViewControllers(viewControllers, animated: animated)
        splitLayoutContainer.primaryNavigationController.view.layoutIfNeeded()
    }

    private func setSettingsUI(_ settingsUI: SettingsUI?, animated: Bool) {
        _settingsUI = settingsUI

        let viewControllers = [settingsUI].compactMap { $0 }
        splitLayoutContainer.primaryNavigationController.setViewControllers(viewControllers, animated: animated)
        splitLayoutContainer.primaryNavigationController.view.layoutIfNeeded()
    }

    private func setConversationUI(_ conversationUI: ConversationUI?, animated: Bool) {
        _conversationUI = conversationUI

        let viewControllers = [conversationUI ?? noConversationPlaceholder].compactMap { $0 }
        splitLayoutContainer.secondaryNavigationController.setViewControllers(viewControllers, animated: animated)
        splitLayoutContainer.secondaryNavigationController.view.layoutIfNeeded()
    }

    private func setSettingsContentUI(_ settingsContentUI: UIViewController?, animated: Bool) {
        _settingsContentUI = settingsContentUI

        let viewControllers = [settingsContentUI].compactMap { $0 }
        splitLayoutContainer.secondaryNavigationController.setViewControllers(viewControllers, animated: animated)
        splitLayoutContainer.secondaryNavigationController.view.layoutIfNeeded()
    }
}

// MARK: - Previews

@available(iOS 17, *)
#Preview {
    MainSplitViewControllerPreview()
}
