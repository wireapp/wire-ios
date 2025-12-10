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
import WireCommonComponents
import WireDesign
import WireMessagingDomain
import WireMainNavigationUI
import WireMessagingAssembly
import WireSyncEngine

final class ConversationRootViewController: UIViewController {

    // MARK: - Properties

    fileprivate var contentView = UIView()
    private var navBarHeightForFederatedUsers: CGFloat = 50
    private var defaultNavBarHeight: CGFloat = 44
    var networkStatusBarHeight: NSLayoutConstraint?

    private var conversation: ZMConversation

    /// for NetworkStatusViewDelegate
    var shouldAnimateNetworkStatusView = false
    fileprivate let networkStatusViewController: NetworkStatusViewController = .init()
    fileprivate(set) weak var conversationViewController: ConversationViewController?

    // MARK: - Init

    init(
        conversation: ZMConversation,
        message: ZMConversationMessage?,
        userSession: UserSession,
        mainCoordinator: AnyMainCoordinator,
        selfProfileUIBuilder: SelfProfileViewControllerBuilderProtocol,
        conversationCreationRepository: any ConversationCreationRepositoryProtocol,
        mediaPlaybackManager: MediaPlaybackManager?,
        wireMessagingFactory: any WireMessagingFactoryProtocol
    ) {
        self.conversation = conversation

        let conversationController = ConversationViewController(
            conversation: conversation,
            visibleMessage: message as? ZMMessage,
            userSession: userSession,
            mainCoordinator: mainCoordinator,
            selfProfileUIBuilder: selfProfileUIBuilder,
            conversationCreationRepository: conversationCreationRepository,
            mediaPlaybackManager: mediaPlaybackManager,
            classificationProvider: ZMUserSession.shared(),
            networkStatusObservable: NetworkStatus.shared,
            getParticipantImageSourceUseCase: GetParticipantImageSourceUseCase(
                repository: GetParticipantImageSourceRepository(
                    userSession: userSession
                )
            ),
            wireMessagingFactory: wireMessagingFactory
        )

        self.conversationViewController = conversationController

        super.init(nibName: .none, bundle: .none)

        // Configure navigation bar appearance
        if let navBar = navigationController?.navigationBar {
            navBar.isTranslucent = false
            navBar.isOpaque = true
            navBar.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
            navBar.shadowImage = UIImage()
            navBar.barTintColor = ColorTheme.Backgrounds.surface
            navBar.tintColor = SemanticColors.Label.textDefault
            navBar.barStyle = .default

            // Handle federated users case
            if conversation.conversationType == .oneOnOne,
               let user = conversation.connectedUserType,
               user.isFederated {
                navBar.frame.size.height = navBarHeightForFederatedUsers
            }
        }

        networkStatusViewController.delegate = self

        addChild(conversationController)
        contentView.addSubview(conversationController.view)
        conversationController.didMove(toParent: self)

        conversation.refreshDataIfNeeded(userSession: userSession)
        configure()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Override methods

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.topItem?.backButtonDisplayMode = .minimal
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        shouldAnimateNetworkStatusView = true
        navigationController?.navigationBar.accessibilityElementsHidden = false
        conversationViewController?.view.accessibilityElementsHidden = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        navigationController?.navigationBar.accessibilityElementsHidden = true
        conversationViewController?.view.accessibilityElementsHidden = true
    }

    private var child: UIViewController? {
        conversationViewController?.contentViewController
    }

    override var childForStatusBarStyle: UIViewController? {
        child
    }

    override var childForStatusBarHidden: UIViewController? {
        child
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            // Refresh navigation items to get new buttons with updated colors
            guard let conversationViewController else { return }

            navigationItem.rightBarButtonItems = conversationViewController
                .rightNavigationItems(forConversation: conversation)
            navigationItem.leftBarButtonItems = conversationViewController
                .leftNavigationItems(hasUnread: conversation.hasUnreadMessagesInOtherConversations)
        }
    }

    func configure() {
        guard let conversationViewController else { return }

        // Set left navigation items (back button, search, unread status, etc.)
        navigationItem.leftBarButtonItems = conversationViewController
            .leftNavigationItems(hasUnread: conversation.hasUnreadMessagesInOtherConversations)

        // Set right navigation items (call buttons etc.) from the conversation controller
        navigationItem.rightBarButtonItems = conversationViewController.navigationItem.rightBarButtonItems

        // Set the custom title view which includes conversation name and search functionality
        navigationItem.titleView = conversationViewController.navigationItem.titleView

        view.backgroundColor = SemanticColors.View.backgroundDefault
        view.addSubview(contentView)

        // This container view will have the same background color as the inputBar
        // and extend to the bottom of the screen.
        let inputBarContainer = UIView()
        inputBarContainer.backgroundColor = conversationViewController.inputBarController.inputBar.backgroundColor
        inputBarContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(inputBarContainer)
        contentView.sendSubviewToBack(inputBarContainer)

        addToSelf(networkStatusViewController)

        [
            contentView,
            conversationViewController.view,
            networkStatusViewController.view
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            networkStatusViewController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            networkStatusViewController.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            networkStatusViewController.view.rightAnchor.constraint(equalTo: view.rightAnchor),

            contentView.leftAnchor.constraint(equalTo: view.leftAnchor),
            contentView.rightAnchor.constraint(equalTo: view.rightAnchor),
            contentView.topAnchor.constraint(equalTo: networkStatusViewController.view.bottomAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            conversationViewController.view.topAnchor.constraint(equalTo: contentView.topAnchor),
            conversationViewController.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            conversationViewController.view.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            conversationViewController.view.rightAnchor.constraint(equalTo: contentView.rightAnchor),

            inputBarContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            inputBarContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            inputBarContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            inputBarContainer.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    // MARK: - Methods

    func scroll(to message: ZMConversationMessage) {
        conversationViewController?.scroll(to: message)
    }
}

// MARK: - NetworkStatusBarDelegate

extension ConversationRootViewController: NetworkStatusBarDelegate {
    var bottomMargin: CGFloat {
        0
    }

    func showInIPad(
        networkStatusViewController: NetworkStatusViewController,
        with orientation: UIInterfaceOrientation
    ) -> Bool {
        // always show on iPad for any orientation in regular mode
        true
    }
}

// MARK: - ZMConversation extension

private extension ZMConversation {

    /// Check if the conversation data is out of date, and in case update it.
    /// This in an opportunistic update of the data, with an on-demand strategy.
    /// Whenever the conversation is opened by the user, we check if anything is missing.
    func refreshDataIfNeeded(userSession: UserSession) {
        userSession.enqueue {
            self.markToDownloadRolesIfNeeded()
        }
    }
}

extension ConversationRootViewController: WireCallCenterCallStateObserver {

    func callCenterDidChange(
        callState: CallState,
        conversation: ZMConversation,
        caller: UserType,
        timestamp: Date?,
        previousCallState: CallState?
    ) {
        conversationViewController?.updateRightNavigationItemsButtons()
    }

}
