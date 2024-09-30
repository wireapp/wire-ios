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

public final class MainSplitViewController<Sidebar, TabContainer>: UISplitViewController, MainSplitViewControllerProtocol where
Sidebar: MainSidebarProtocol, TabContainer: MainTabBarControllerProtocol {

    public typealias Settings = TabContainer.Settings
    public typealias NoConversationPlaceholderBuilder = () -> UIViewController

    /// If the width of the view is lower than this value, the `preferredDisplayMode` property
    /// will be set to `.oneBesideSecondary`, otherwise to `.twoBesideSecondary`.
    private let sidebarVisibilityThreshold: CGFloat = 768

    // MARK: - Primary Column

    public private(set) weak var sidebar: Sidebar!

    // MARK: - Supplementary Column

    public weak var conversationList: ConversationList? {
        didSet {
            supplementaryNavigationController?.viewControllers = [conversationList].compactMap { $0 }
            supplementaryNavigationController?.view.layoutIfNeeded()
        }
    }

    public weak var archive: Archive? {
        didSet {
            supplementaryNavigationController?.viewControllers = [archive].compactMap { $0 }
            supplementaryNavigationController?.view.layoutIfNeeded()
        }
    }

    public weak var connect: Connect? {
        didSet {
            supplementaryNavigationController?.viewControllers = [connect].compactMap { $0 }
            supplementaryNavigationController?.view.layoutIfNeeded()
        }
    }

    public weak var settings: Settings? {
        didSet {
            supplementaryNavigationController?.viewControllers = [settings].compactMap { $0 }
            supplementaryNavigationController?.view.layoutIfNeeded()
        }
    }

    public var settingsContent: SettingsContent? {
        didSet {
            fatalError()
        }
    }

    // MARK: - Secondary Column

    public weak var conversation: Conversation? {
        didSet {
            secondaryNavigationController?.viewControllers = [conversation ?? noConversationPlaceholder].compactMap { $0 }
            secondaryNavigationController?.view.layoutIfNeeded()
        }
    }

    // MARK: - Compact/Collapsed

    public private(set) weak var tabContainer: TabContainer!

    // MARK: - Private Properties

    /// This view controller is displayed when no conversation in the list is selected.
    private let noConversationPlaceholder: UIViewController

    private weak var supplementaryNavigationController: UINavigationController?
    private weak var secondaryNavigationController: UINavigationController?

    // MARK: - Initialization

    public init(
        sidebar: @autoclosure () -> Sidebar,
        noConversationPlaceholder: @autoclosure NoConversationPlaceholderBuilder,
        tabContainer: @autoclosure () -> TabContainer
    ) {
        let sidebar = sidebar()
        let noConversationPlaceholder = noConversationPlaceholder()
        let tabContainer = tabContainer()
        let supplementaryNavigationController = UINavigationController()
        let secondaryNavigationController = UINavigationController(rootViewController: noConversationPlaceholder)

        self.noConversationPlaceholder = noConversationPlaceholder
        self.supplementaryNavigationController = supplementaryNavigationController
        self.secondaryNavigationController = secondaryNavigationController

        self.sidebar = sidebar
        self.tabContainer = tabContainer

        super.init(style: .tripleColumn)

        preferredSplitBehavior = .tile
        preferredDisplayMode = .oneBesideSecondary
        preferredPrimaryColumnWidth = 260
        preferredSupplementaryColumnWidth = 320

        setViewController(sidebar, for: .primary)
        setViewController(supplementaryNavigationController, for: .supplementary)
        setViewController(secondaryNavigationController, for: .secondary)
        setViewController(tabContainer, for: .compact)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setPreferredDisplayMode(basedOn: view.frame.size.width)
    }

    override public func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        setPreferredDisplayMode(basedOn: size.width)
    }

    private func setPreferredDisplayMode(basedOn width: CGFloat) {
        preferredDisplayMode = if width >= sidebarVisibilityThreshold {
            .twoBesideSecondary
        } else {
            .oneBesideSecondary
        }
    }
}

// MARK: - Previews

@available(iOS 17, *)
#Preview {
    MainSplitViewControllerPreview()
}
