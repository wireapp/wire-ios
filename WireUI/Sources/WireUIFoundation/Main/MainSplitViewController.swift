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

// TODO: unit tests

public final class MainSplitViewController<

    Sidebar: MainSidebarProtocol,
    ConversationList: MainConversationListProtocol

>: UISplitViewController, MainSplitViewControllerProtocol {

    public typealias NoConversationPlaceholderBuilder = () -> UIViewController

    /// If the width of the view is lower than this value, the `preferredDisplayMode` property
    /// will be set to `.oneBesideSecondary`, otherwise to `.twoBesideSecondary`.
    private let sidebarVisibilityThreshold: CGFloat = 768

    // MARK: - Primary Column

    public var sidebar: Sidebar! { _sidebar }

    // MARK: - Supplementary Column

    public var conversationList: ConversationList? {
        get { _conversationList }
        set {
            _conversationList = newValue
            supplementaryNavigationController?.viewControllers = [newValue].compactMap { $0 }
            supplementaryNavigationController?.view.layoutIfNeeded()
        }
    }

    public var archive: UIViewController? {
        get { _archive }
        set {
            _archive = newValue
            supplementaryNavigationController?.viewControllers = [newValue].compactMap { $0 }
            supplementaryNavigationController?.view.layoutIfNeeded()
        }
    }

    public var newConversation: UIViewController? {
        get { _newConversation }
        set {
            _newConversation = newValue
            supplementaryNavigationController?.viewControllers = [newValue].compactMap { $0 }
            supplementaryNavigationController?.view.layoutIfNeeded()
        }
    }

    public var settings: UIViewController? {
        get { _settings }
        set {
            _settings = newValue
            supplementaryNavigationController?.viewControllers = [newValue].compactMap { $0 }
            supplementaryNavigationController?.view.layoutIfNeeded()
        }
    }

    // MARK: - Secondary Column

    public var conversation: UIViewController? {
        get { _conversation }
        set {
            _conversation = newValue
            secondaryNavigationController?.viewControllers = [newValue ?? noConversationPlaceholder]
            secondaryNavigationController?.view.layoutIfNeeded()
        }
    }

    // MARK: - Compact/Collapsed

    public var tabContainer: UIViewController! { _tabContainer }

    // MARK: - Private Properties

    /// This view controller is displayed when no conversation in the list is selected.
    private let noConversationPlaceholder: UIViewController

    private weak var supplementaryNavigationController: UINavigationController?
    private weak var secondaryNavigationController: UINavigationController?

    private weak var _sidebar: Sidebar?
    private weak var _conversationList: ConversationList?
    private weak var _conversation: Conversation?
    private weak var _archive: Archive?
    private weak var _newConversation: NewConversation?
    private weak var _settings: MainSplitViewControllerProtocol.Settings?
    private weak var _tabContainer: TabContainer?

    // MARK: - Initialization

    public init(
        sidebar: @autoclosure () -> Sidebar,
        noConversationPlaceholder: @autoclosure NoConversationPlaceholderBuilder,
        tabContainer: @autoclosure () -> UIViewController
    ) {
        let sidebar = sidebar()
        let noConversationPlaceholder = noConversationPlaceholder()
        let tabContainer = tabContainer()
        let supplementaryNavigationController = UINavigationController()
        let secondaryNavigationController = UINavigationController(rootViewController: noConversationPlaceholder)

        self.noConversationPlaceholder = noConversationPlaceholder
        self.supplementaryNavigationController = supplementaryNavigationController
        self.secondaryNavigationController = secondaryNavigationController

        _sidebar = sidebar
        _tabContainer = tabContainer

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
