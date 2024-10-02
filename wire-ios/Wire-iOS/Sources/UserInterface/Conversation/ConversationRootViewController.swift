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
import WireCommonComponents
import WireDesign
import WireMainNavigation
import WireSyncEngine

// MARK: - ConversationRootViewController

// This class wraps the conversation content view controller in order to display the navigation bar on the top
final class ConversationRootViewController: UIViewController {

    // MARK: - Properties

    let navBarContainer: NavigationBarContainer
    fileprivate var contentView = UIView()
    private var navBarHeightForFederatedUsers: CGFloat = 50
    // This value is coming from NavigationBarContainer. swift file
    // where the value for the navigation bar height is set to 44.
    private var defaultNavBarHeight: CGFloat = 44
    var navHeight: NSLayoutConstraint?
    var networkStatusBarHeight: NSLayoutConstraint?

    /// for NetworkStatusViewDelegate
    var shouldAnimateNetworkStatusView = false

    fileprivate let networkStatusViewController: NetworkStatusViewController = NetworkStatusViewController()

    fileprivate(set) weak var conversationViewController: ConversationViewController?

    // MARK: - Init

    init(
        conversation: ZMConversation,
        message: ZMConversationMessage?,
        userSession: UserSession,
        mainCoordinator: any MainCoordinatorProtocol,
        mediaPlaybackManager: MediaPlaybackManager?
    ) {
        let conversationController = ConversationViewController(
            conversation: conversation,
            visibleMessage: message as? ZMMessage,
            userSession: userSession,
            mainCoordinator: mainCoordinator,
            mediaPlaybackManager: mediaPlaybackManager,
            classificationProvider: ZMUserSession.shared(),
            networkStatusObservable: NetworkStatus.shared
        )

        conversationViewController = conversationController

        let navbar = UINavigationBar()
        navbar.isTranslucent = false
        navbar.isOpaque = true
        navbar.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
        navbar.shadowImage = UIImage()
        navbar.barTintColor = SemanticColors.View.backgroundDefault
        navbar.tintColor = SemanticColors.Label.textDefault
        navbar.barStyle = .default

        navBarContainer = NavigationBarContainer(navbar)

        super.init(nibName: .none, bundle: .none)

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
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        shouldAnimateNetworkStatusView = true
        navBarContainer.navigationBar.accessibilityElementsHidden = false
        conversationViewController?.view.accessibilityElementsHidden = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        navBarContainer.navigationBar.accessibilityElementsHidden = true
        conversationViewController?.view.accessibilityElementsHidden = true
    }

    private var child: UIViewController? {
        return conversationViewController?.contentViewController
    }

    override var childForStatusBarStyle: UIViewController? {
        return child
    }

    override var childForStatusBarHidden: UIViewController? {
        return child
    }

    func configure() {
        guard let conversationViewController = self.conversationViewController else {
            return
        }
        navHeight = navBarContainer.view.heightAnchor.constraint(equalToConstant: defaultNavBarHeight)
        setupNavigationBarHeight()

        guard let navigationBarHeight = navHeight else {
            return
        }

        self.view.backgroundColor = SemanticColors.View.backgroundDefault

        self.addToSelf(navBarContainer)
        self.view.addSubview(self.contentView)

        // This container view will have the same background color as the inputBar
        // and extend to the bottom of the screen.
        let inputBarContainer = UIView()
        inputBarContainer.backgroundColor = conversationViewController.inputBarController.inputBar.backgroundColor
        inputBarContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(inputBarContainer)
        contentView.sendSubviewToBack(inputBarContainer)

        NSLayoutConstraint.activate([
            inputBarContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            inputBarContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            inputBarContainer.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            inputBarContainer.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor)
        ])

        self.addToSelf(networkStatusViewController)

        [
            contentView,
            conversationViewController.view,
            networkStatusViewController.view
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            networkStatusViewController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            networkStatusViewController.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            networkStatusViewController.view.rightAnchor.constraint(equalTo: view.rightAnchor),

            navBarContainer.view.topAnchor.constraint(equalTo: networkStatusViewController.view.bottomAnchor),
            navBarContainer.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            navBarContainer.view.rightAnchor.constraint(equalTo: view.rightAnchor),
            navigationBarHeight,

            contentView.leftAnchor.constraint(equalTo: view.leftAnchor),
            contentView.rightAnchor.constraint(equalTo: view.rightAnchor),
            contentView.topAnchor.constraint(equalTo: navBarContainer.view.bottomAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            conversationViewController.view.topAnchor.constraint(equalTo: contentView.topAnchor),
            conversationViewController.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            conversationViewController.view.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            conversationViewController.view.rightAnchor.constraint(equalTo: contentView.rightAnchor)
        ])

        navBarContainer.navigationBar.pushItem(conversationViewController.navigationItem, animated: false)
    }

    // MARK: - Methods

    func scroll(to message: ZMConversationMessage) {
        conversationViewController?.scroll(to: message)
    }

    func setupNavigationBarHeight() {
        if let conversationVC = conversationViewController?.conversation,
           conversationVC.conversationType == .oneOnOne,
           let user = conversationVC.connectedUserType,
           user.isFederated {
            navHeight?.constant = navBarHeightForFederatedUsers
        } else {
            navHeight?.constant = defaultNavBarHeight
        }

    }
}

// MARK: - NetworkStatusBarDelegate

extension ConversationRootViewController: NetworkStatusBarDelegate {
    var bottomMargin: CGFloat {
        return 0
    }

    func showInIPad(
        networkStatusViewController: NetworkStatusViewController,
        with orientation: UIInterfaceOrientation
    ) -> Bool {
        // always show on iPad for any orientation in regular mode
        return true
    }
}

// MARK: - ZMConversation extension

extension ZMConversation {

    /// Check if the conversation data is out of date, and in case update it.
    /// This in an opportunistic update of the data, with an on-demand strategy.
    /// Whenever the conversation is opened by the user, we check if anything is missing.
    fileprivate func refreshDataIfNeeded(userSession: UserSession) {
        userSession.enqueue {
            self.markToDownloadRolesIfNeeded()
        }
    }
}
