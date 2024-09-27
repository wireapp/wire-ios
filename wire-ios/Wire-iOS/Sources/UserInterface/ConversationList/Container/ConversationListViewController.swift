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
import WireDesign
import WireReusableUIComponents
import WireSyncEngine

// MARK: - ConversationListState

enum ConversationListState {
    case conversationList
    case peoplePicker
    case archived
}

// MARK: - ConversationListViewController

final class ConversationListViewController: UIViewController {
    let viewModel: ViewModel
    let mainCoordinator: MainCoordinating
    weak var zClientViewController: ZClientViewController?

    /// internal View Model
    var state: ConversationListState = .conversationList

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

    var userStatusViewController: UserStatusViewController?
    weak var titleViewLabel: UILabel?
    let networkStatusViewController = NetworkStatusViewController()
    let onboardingHint = ConversationListOnboardingHint()
    let selfProfileViewControllerBuilder: any ViewControllerBuilder

    convenience init(
        account: Account,
        selfUserLegalHoldSubject: any SelfUserLegalHoldable,
        userSession: UserSession,
        zClientViewController: ZClientViewController,
        mainCoordinator: MainCoordinating,
        isSelfUserE2EICertifiedUseCase: IsSelfUserE2EICertifiedUseCaseProtocol,
        isFolderStatePersistenceEnabled: Bool,
        selfProfileViewControllerBuilder: some ViewControllerBuilder
    ) {
        let viewModel = ConversationListViewController.ViewModel(
            account: account,
            selfUserLegalHoldSubject: selfUserLegalHoldSubject,
            userSession: userSession,
            isSelfUserE2EICertifiedUseCase: isSelfUserE2EICertifiedUseCase,
            mainCoordinator: mainCoordinator
        )
        self.init(
            viewModel: viewModel,
            isFolderStatePersistenceEnabled: isFolderStatePersistenceEnabled,
            zClientViewController: zClientViewController,
            mainCoordinator: mainCoordinator,
            selfProfileViewControllerBuilder: selfProfileViewControllerBuilder
        )
    }

    required init(
        viewModel: ViewModel,
        isFolderStatePersistenceEnabled: Bool,
        zClientViewController: ZClientViewController,
        mainCoordinator: MainCoordinating,
        selfProfileViewControllerBuilder: some ViewControllerBuilder
    ) {
        self.viewModel = viewModel
        self.mainCoordinator = mainCoordinator
        self.zClientViewController = zClientViewController
        self.selfProfileViewControllerBuilder = selfProfileViewControllerBuilder

        let bottomInset = ConversationListViewController.contentControllerBottomInset
        self.listContentController = ConversationListContentController(
            userSession: viewModel.userSession,
            mainCoordinator: mainCoordinator,
            isFolderStatePersistenceEnabled: isFolderStatePersistenceEnabled,
            zClientViewController: zClientViewController
        )
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

        updateTitleView()
        updateAccountView()
        updateLegalHoldIndictor()

        viewModel.viewController = self
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Update
        hideNoContactLabel(animated: false)

        setupObservers()

        listContentController.collectionView.scrollRectToVisible(
            CGRect(x: 0, y: 0, width: view.bounds.size.width, height: 1),
            animated: false
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.savePendingLastRead()
        viewModel.requestMarketingConsentIfNeeded()

        // there are currently always four tab items
        let offset = (view.bounds.width / 4 * -1.5)
        onboardingHint.arrowView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: offset).isActive = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !isIPadRegular() {
            Settings.shared[.lastViewedScreen] = SettingsLastScreen.list
        }

        state = .conversationList

        shouldAnimateNetworkStatusView = true

        zClientViewController?.notifyUserOfDisabledAppLockIfNeeded()

        viewModel.updateE2EICertifiedStatus()

        if !viewDidAppearCalled {
            viewDidAppearCalled = true

            zClientViewController?.showAvailabilityBehaviourChangeAlertIfNeeded()
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { _ in
            // we reload on rotation to make sure that the list cells lay themselves out correctly for the new
            // orientation
            self.listContentController.reload()
        })

        super.viewWillTransition(to: size, with: coordinator)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }

    // MARK: - setup UI

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
            noConversationLabel.widthAnchor.constraint(equalToConstant: 240),
        ])
    }

    func createArchivedListViewController() -> ArchivedListViewController {
        let archivedViewController = ArchivedListViewController(userSession: viewModel.userSession)
        archivedViewController.delegate = viewModel
        return archivedViewController
    }

    func showNoContactLabel(animated: Bool = true) {
        if state != .conversationList { return }

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

    func createPeoplePickerController() -> StartUIViewController {
        let startUIViewController = StartUIViewController(
            userSession: viewModel.userSession,
            mainCoordinator: mainCoordinator
        )
        startUIViewController.delegate = viewModel
        return startUIViewController
    }

    func presentPeoplePicker(
        completion: Completion? = nil
    ) {
        setState(.peoplePicker, animated: true, completion: completion)
    }

    func selectOnListContentController(
        _ conversation: ZMConversation!,
        scrollTo message: ZMConversationMessage?,
        focusOnView focus: Bool,
        animated: Bool
    ) -> Bool {
        listContentController.select(
            conversation,
            scrollTo: message,
            focusOnView: focus,
            animated: animated
        )
    }

    func showNewsletterSubscriptionDialogIfNeeded(completionHandler: @escaping ResultHandler) {
        UIAlertController.showNewsletterSubscriptionDialogIfNeeded(
            presentViewController: self,
            completionHandler: completionHandler
        )
    }
}

// MARK: ConversationListContainerViewModelDelegate

extension ConversationListViewController: ConversationListContainerViewModelDelegate {
    func conversationListViewControllerViewModel(_ viewModel: ViewModel, didUpdate selfUserStatus: UserStatus) {
        updateTitleView()
    }
}

extension NSAttributedString {
    fileprivate static var attributedTextForNoConversationLabel: NSAttributedString? {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.setParagraphStyle(NSParagraphStyle.default)

        paragraphStyle.paragraphSpacing = 10
        paragraphStyle.alignment = .center

        let titleAttributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.foregroundColor: SemanticColors.Label.textDefault,
            NSAttributedString.Key.font: UIFont.font(for: .h3),
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
        ]

        paragraphStyle.paragraphSpacing = 4

        let titleString = L10n.Localizable.ConversationList.Empty.AllArchived.message
        return NSAttributedString(string: titleString.uppercased(), attributes: titleAttributes)
    }
}
