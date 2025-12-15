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
import WireDataModel
import WireDesign
import WireMainNavigationUI
import WireMessagingDomain
import WireSyncEngine

/// A view controller wrapping the message details.

final class MessageDetailsViewController: UIViewController {

    /// The collection of view controllers displaying the content.

    enum ViewControllers {
        /// We are displaying the combined view.
        case combinedView(
            readReceipts: MessageDetailsContentViewController,
            reactions: MessageDetailsContentViewController
        )

        /// We are displaying the single view.
        case singleView(MessageDetailsContentViewController)

        /// The read receipts view controller.
        var readReceipts: MessageDetailsContentViewController {
            switch self {
            case let .combinedView(readReceipts, _): readReceipts
            case let .singleView(viewController): viewController
            }
        }

        /// The reactions view controller.
        var reactions: MessageDetailsContentViewController {
            switch self {
            case let .combinedView(_, reactions): reactions
            case let .singleView(viewController): viewController
            }
        }

        /// All the view controllers.
        var all: [MessageDetailsContentViewController] {
            switch self {
            case let .combinedView(readReceipts, reactions):
                [readReceipts, reactions]
            case let .singleView(viewController):
                [viewController]
            }
        }
    }

    // MARK: - Properties

    /// The displayed message.
    let message: ZMConversationMessage

    /// The data source for the message details.
    let dataSource: MessageDetailsDataSource

    let userSession: UserSession

    // MARK: - UI Elements

    let container: TabBarController
    private let viewControllers: ViewControllers

    // MARK: - Initialization

    /// Convenience initializer that creates a details view controller for the specified message,
    /// displaying the first available tab by default.
    /// - Parameter message: The message to display the details of.
    /// - Parameter userSession: The current user session associated with the view controller.
    /// - Parameter mainCoordinator: The main coordinator responsible for navigation and coordination.
    /// - Parameter selfProfileUIBuilder: A builder object for constructing the user's profile view controller.
    convenience init(
        message: ZMConversationMessage,
        userSession: UserSession,
        mainCoordinator: AnyMainCoordinator,
        selfProfileUIBuilder: SelfProfileViewControllerBuilderProtocol,
        conversationCreationRepository: any ConversationCreationRepositoryProtocol
    ) {
        self.init(
            message: message,
            preferredDisplayMode: .receipts,
            userSession: userSession,
            mainCoordinator: mainCoordinator,
            selfProfileUIBuilder: selfProfileUIBuilder,
            conversationCreationRepository: conversationCreationRepository
        )
    }

    /// Initializes a details view controller for the specified message.
    /// - Parameters:
    ///   - message: The message to display the details of.
    ///   - preferredDisplayMode: The display mode to display by default when there are multiple
    ///     tabs. This parameter is only an indication and will not override the displayed content
    ///     if the data source determines it is unavailable for the message.
    ///   - userSession: The current user session associated with the view controller.
    ///   - mainCoordinator: The main coordinator responsible for navigation and coordination.
    ///   - selfProfileUIBuilder: A builder object for constructing the user's profile view controller.
    init(
        message: ZMConversationMessage,
        preferredDisplayMode: MessageDetailsDisplayMode,
        userSession: UserSession,
        mainCoordinator: AnyMainCoordinator,
        selfProfileUIBuilder: SelfProfileViewControllerBuilderProtocol,
        conversationCreationRepository: any ConversationCreationRepositoryProtocol
    ) {
        self.message = message
        self.dataSource = MessageDetailsDataSource(message: message)
        self.userSession = userSession

        // Setup view controllers based on display mode
        switch dataSource.displayMode {
        case .combined:
            let readReceiptsViewController = MessageDetailsContentViewController(
                contentType: .receipts(enabled: dataSource.supportsReadReceipts),
                conversation: dataSource.conversation,
                userSession: userSession,
                mainCoordinator: mainCoordinator,
                selfProfileUIBuilder: selfProfileUIBuilder,
                conversationCreationRepository: conversationCreationRepository
            )
            let reactionsViewController = MessageDetailsContentViewController(
                contentType: .reactions,
                conversation: dataSource.conversation,
                userSession: userSession,
                mainCoordinator: mainCoordinator,
                selfProfileUIBuilder: selfProfileUIBuilder,
                conversationCreationRepository: conversationCreationRepository
            )
            self.viewControllers = .combinedView(
                readReceipts: readReceiptsViewController,
                reactions: reactionsViewController
            )

        case .reactions:
            let reactionsViewController = MessageDetailsContentViewController(
                contentType: .reactions,
                conversation: dataSource.conversation,
                userSession: userSession,
                mainCoordinator: mainCoordinator,
                selfProfileUIBuilder: selfProfileUIBuilder,
                conversationCreationRepository: conversationCreationRepository
            )
            self.viewControllers = .singleView(reactionsViewController)

        case .receipts:
            let readReceiptsViewController = MessageDetailsContentViewController(
                contentType: .receipts(enabled: dataSource.supportsReadReceipts),
                conversation: dataSource.conversation,
                userSession: userSession,
                mainCoordinator: mainCoordinator,
                selfProfileUIBuilder: selfProfileUIBuilder,
                conversationCreationRepository: conversationCreationRepository
            )
            self.viewControllers = .singleView(readReceiptsViewController)
        }

        self.container = TabBarController(viewControllers: viewControllers.all)

        if case .combined = dataSource.displayMode {
            let tabIndex = preferredDisplayMode == .reactions ? 1 : 0
            container.selectIndex(tabIndex, animated: false)
        }

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        configureConstraints()
        reloadData()

        dataSource.observer = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBar()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIAccessibility.post(notification: .layoutChanged, argument: navigationItem.titleView)
    }

    override func accessibilityPerformEscape() -> Bool {
        presentingViewController?.dismiss(animated: true)
        return true
    }

    // MARK: - Setup

    private func setupNavigationBar() {

        // use nav bar appearance before commiting those changes
        // make sure you hide the thin line between the nav bar and the rest of the view
        setupNavigationBarTitle(dataSource.title)
        navigationItem.rightBarButtonItem = UIBarButtonItem.closeButton(action: UIAction { [weak self] _ in
            guard let self else { return }
            presentingViewController?.dismiss(animated: true)
        }, accessibilityLabel: L10n.Localizable.General.close)

        navigationController?.navigationBar.backgroundColor = SemanticColors.View.backgroundDefault
    }

    private func setupViews() {
        view.backgroundColor = SemanticColors.View.backgroundDefault

        addChild(container)
        view.addSubview(container.view)
        container.didMove(toParent: self)

        container.isTabBarHidden = dataSource.displayMode != .combined
        container.isEnabled = dataSource.displayMode == .combined
    }

    private func configureConstraints() {
        container.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            container.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            container.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Data Management

    func reloadData() {
        switch dataSource.displayMode {
        case .combined:
            viewControllers.reactions.updateData(dataSource.reactions)
            viewControllers.readReceipts.updateData(dataSource.readReceipts)
        case .reactions:
            viewControllers.reactions.updateData(dataSource.reactions)
        case .receipts:
            viewControllers.readReceipts.updateData(dataSource.readReceipts)
        }
        reloadFooters()
    }

    private func reloadFooters() {
        viewControllers.all.forEach {
            $0.subtitle = dataSource.subtitle
            $0.accessibleSubtitle = dataSource.accessibilitySubtitle
        }
    }

    // MARK: - Orientation

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        wr_supportedInterfaceOrientations
    }
}

// MARK: - MessageDetailsDataSourceObserver

extension MessageDetailsViewController: MessageDetailsDataSourceObserver {
    func dataSourceDidChange(_ dataSource: MessageDetailsDataSource) {
        reloadData()
    }

    func detailsFooterDidChange(_ dataSource: MessageDetailsDataSource) {
        reloadFooters()
    }
}
