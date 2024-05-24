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
import WireDataModel
import WireSyncEngine

final class ConversationListViewController: UIViewController {

    let viewModel: ViewModel

    /// private
    private var viewDidAppearCalled = false
    private static let contentControllerBottomInset: CGFloat = 16

    /// for NetworkStatusViewDelegate
    var shouldAnimateNetworkStatusView = false

    var startCallToken: Any?

    weak var pushPermissionDeniedViewController: PermissionDeniedViewController?

    private let noConversationLabel = {
        let label = UILabel()
        label.attributedText = NSAttributedString.attributedTextForNoConversationLabel
        label.numberOfLines = 0
        label.backgroundColor = .clear
        return label
    }()

    let contentContainer: UIView = {
        let view = UIView()
        view.backgroundColor = SemanticColors.View.backgroundConversationListTableViewCell
        return view
    }()

    let listContentController: ConversationListContentController

    weak var titleViewLabel: UILabel?
    let networkStatusViewController = NetworkStatusViewController()
    let onboardingHint = ConversationListOnboardingHint()
    let selfProfileViewControllerBuilder: ViewControllerBuilder

    convenience init(
        account: Account,
        selfUser: SelfUserType,
        userSession: UserSession,
        isSelfUserE2EICertifiedUseCase: IsSelfUserE2EICertifiedUseCaseProtocol,
        selfProfileViewControllerBuilder: ViewControllerBuilder
    ) {
        let viewModel = ConversationListViewController.ViewModel(
            account: account,
            selfUser: selfUser,
            userSession: userSession,
            isSelfUserE2EICertifiedUseCase: isSelfUserE2EICertifiedUseCase
        )
        self.init(
            viewModel: viewModel,
            selfProfileViewControllerBuilder: selfProfileViewControllerBuilder
        )
    }

    required init(
        viewModel: ViewModel,
        selfProfileViewControllerBuilder: ViewControllerBuilder
    ) {
        self.viewModel = viewModel
        self.selfProfileViewControllerBuilder = selfProfileViewControllerBuilder

        let bottomInset = ConversationListViewController.contentControllerBottomInset
        listContentController = .init(userSession: viewModel.userSession)
        listContentController.collectionView.contentInset = .init(top: 0, left: 0, bottom: bottomInset, right: 0)

        super.init(nibName: nil, bundle: nil)

        definesPresentationContext = true

        /// setup UI
        view.addSubview(contentContainer)
        view.backgroundColor = SemanticColors.View.backgroundConversationList

        setupListContentController()
        setupNoConversationLabel()
        setupOnboardingHint()
        setupNetworkStatusBar()

        createViewConstraints()

        setupTitleView()
        setupLeftNavigationBarButtons()
        setupRightNavigationBarButtons()

        viewModel.viewController = self
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Update
        hideNoContactLabel(animated: false)

        setupObservers()

        listContentController.collectionView.scrollRectToVisible(CGRect(x: 0, y: 0, width: view.bounds.size.width, height: 1), animated: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.savePendingLastRead()
        viewModel.requestMarketingConsentIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !isIPadRegular() {
            Settings.shared[.lastViewedScreen] = SettingsLastScreen.list
        }

        shouldAnimateNetworkStatusView = true

        ZClientViewController.shared?.notifyUserOfDisabledAppLockIfNeeded()

        viewModel.updateE2EICertifiedStatus()

        onboardingHint.arrowPointToView = tabBarController?.tabBar

        if !viewDidAppearCalled {
            viewDidAppearCalled = true

            ZClientViewController.shared?.showDataUsagePermissionDialogIfNeeded()
            ZClientViewController.shared?.showAvailabilityBehaviourChangeAlertIfNeeded()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        adjustRightBarButtonItemsSpace()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { _ in
            // we reload on rotation to make sure that the list cells lay themselves out correctly for the new
            // orientation
            self.listContentController.reload()
        })

        super.viewWillTransition(to: size, with: coordinator)
    }

    override var shouldAutorotate: Bool {
        true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }

    // MARK: - Setup UI

    private func setupObservers() {
        viewModel.setupObservers()
    }

    private func setupListContentController() {
        listContentController.contentDelegate = viewModel
        add(listContentController, to: contentContainer)
    }

    private func setupNoConversationLabel() {
        contentContainer.addSubview(noConversationLabel)
    }

    private func setupOnboardingHint() {
        contentContainer.addSubview(onboardingHint)
    }

    private func setupNetworkStatusBar() {
        networkStatusViewController.delegate = self
        add(networkStatusViewController, to: contentContainer)
    }

    private func createViewConstraints() {
        guard let conversationList = listContentController.view else { return }

        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        conversationList.translatesAutoresizingMaskIntoConstraints = false
        noConversationLabel.translatesAutoresizingMaskIntoConstraints = false
        onboardingHint.translatesAutoresizingMaskIntoConstraints = false
        networkStatusViewController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            contentContainer.topAnchor.constraint(equalTo: safeTopAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: safeBottomAnchor),

            networkStatusViewController.view.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            networkStatusViewController.view.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            networkStatusViewController.view.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),

            conversationList.topAnchor.constraint(equalTo: networkStatusViewController.view.bottomAnchor),
            conversationList.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            conversationList.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            conversationList.bottomAnchor.constraint(equalTo: contentContainer.safeBottomAnchor),

            onboardingHint.bottomAnchor.constraint(equalTo: conversationList.bottomAnchor),
            onboardingHint.leftAnchor.constraint(equalTo: contentContainer.leftAnchor),
            onboardingHint.rightAnchor.constraint(equalTo: contentContainer.rightAnchor),

            noConversationLabel.centerXAnchor.constraint(equalTo: contentContainer.centerXAnchor),
            noConversationLabel.centerYAnchor.constraint(equalTo: contentContainer.centerYAnchor),
            noConversationLabel.widthAnchor.constraint(equalToConstant: 240)
        ])
    }

    func showNoContactLabel(animated: Bool = true) {

        let closure = {
            let hasArchivedConversations = self.viewModel.hasArchivedConversations
            self.noConversationLabel.alpha = hasArchivedConversations ? 1.0 : 0.0
            self.onboardingHint.alpha = hasArchivedConversations ? 0.0 : 1.0
        }

        if animated {
            UIView.animate(withDuration: 0.2, animations: closure)
        } else {
            closure()
        }
    }

    func hideNoContactLabel(animated: Bool) {
        UIView.animate(withDuration: animated ? 0.2 : 0) {
            self.noConversationLabel.alpha = 0
            self.onboardingHint.alpha = 0
        }
    }

    /// Scroll to the current selection
    ///
    /// - Parameter animated: perform animation or not
    func scrollToCurrentSelection(animated: Bool) {
        listContentController.scrollToCurrentSelection(animated: animated)
    }

    func presentNewConversationViewController() {

        let viewController = StartUIViewController(userSession: viewModel.userSession)
        viewController.delegate = viewModel
        viewController.view.backgroundColor = SemanticColors.View.backgroundDefault

        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.transitioningDelegate = self
        navigationController.modalPresentationStyle = .currentContext

        tabBarController?.present(navigationController, animated: true) {
            viewController.showKeyboardIfNeeded()
        }
    }

    func selectOnListContentController(
        _ conversation: ZMConversation!,
        scrollTo message: ZMConversationMessage?,
        focusOnView focus: Bool,
        animated: Bool,
        completion: (() -> Void)?
    ) -> Bool {
        listContentController.select(
            conversation,
            scrollTo: message,
            focusOnView: focus,
            animated: animated,
            completion: completion
        )
    }

    func showNewsletterSubscriptionDialogIfNeeded(completionHandler: @escaping ResultHandler) {
        UIAlertController.showNewsletterSubscriptionDialogIfNeeded(
            presentViewController: self,
            completionHandler: completionHandler
        )
    }

    func selectInboxAndFocusOnView(focus: Bool) {
        listContentController.selectInboxAndFocus(onView: focus)
    }
}

// MARK: - ViewModel Delegate

extension ConversationListViewController: ConversationListContainerViewModelDelegate {

    func conversationListViewControllerViewModel(_ viewModel: ViewModel, didUpdate selfUserStatus: UserStatus) {
        setupTitleView()
        setupLeftNavigationBarButtons()
    }
}

// MARK: - ConversationListViewController + ArchivedListViewControllerDelegate

extension ConversationListViewController: ArchivedListViewControllerDelegate {

    func archivedListViewController(
        _ viewController: ArchivedListViewController,
        didSelectConversation conversation: ZMConversation
    ) {

        _ = selectOnListContentController(
            conversation,
            scrollTo: nil,
            focusOnView: true,
            animated: true
        ) { [weak self] in
            self?.tabBarController?.selectedIndex = MainTabBarControllerTab.conversations.rawValue
        }
    }
}

// MARK: - Helpers

private extension NSAttributedString {

    static var attributedTextForNoConversationLabel: NSAttributedString? {

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.setParagraphStyle(NSParagraphStyle.default)

        paragraphStyle.paragraphSpacing = 10
        paragraphStyle.alignment = .center

        let titleAttributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.foregroundColor: SemanticColors.Label.textDefault,
            NSAttributedString.Key.font: UIFont.font(for: .h3),
            NSAttributedString.Key.paragraphStyle: paragraphStyle
        ]

        paragraphStyle.paragraphSpacing = 4

        let titleString = L10n.Localizable.ConversationList.Empty.AllArchived.message
        return NSAttributedString(string: titleString.uppercased(), attributes: titleAttributes)
    }
}
