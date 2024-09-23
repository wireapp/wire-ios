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

    // MARK: - Public Properties

    public var sidebar: Sidebar! { _sidebar }

    public var supplementaryContent: MainSplitViewSupplementaryContent<ConversationList, UIViewController, UIViewController, UIViewController>? {
        didSet {
            let viewController = supplementaryContent?.viewController
            supplementaryNavigationController?.viewControllers = [viewController].compactMap { $0 }
            supplementaryNavigationController?.view.layoutIfNeeded()
        }
    }

    public var conversationList: ConversationList? {
        guard case let .conversationList(weakViewController) = supplementaryContent else { return nil }
        return weakViewController.reference
    }

    public var conversation: UIViewController? {
        get { _conversation }
        set {
            _conversation = newValue
            secondaryNavigationController?.viewControllers = [newValue ?? noConversationPlaceholder]
            secondaryNavigationController?.view.layoutIfNeeded()
        }
    }

    public var archive: UIViewController? {
        guard case let .archive(weakViewController) = supplementaryContent else { return nil }
        return weakViewController.reference
    }

    public var newConversation: UIViewController? {
        guard case let .newConversation(weakViewController) = supplementaryContent else { return nil }
        return weakViewController.reference
    }

    public var settings: UIViewController? {
        guard case let .settings(weakViewController) = supplementaryContent else { return nil }
        return weakViewController.reference
    }

    public var tabContainer: UIViewController! { _tabContainer }

    // MARK: - Private Properties

    /// This view controller is displayed when no conversation in the list is selected.
    private let noConversationPlaceholder: UIViewController

    private weak var supplementaryNavigationController: UINavigationController?
    private weak var secondaryNavigationController: UINavigationController?

    private weak var _sidebar: Sidebar?
    private weak var _conversation: Conversation?
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
