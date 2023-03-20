//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
import WireSyncEngine

private let zmLog = ZMSLog(tag: "ProfileViewController")

enum ProfileViewControllerTabBarIndex: Int {
    case details = 0
    case devices
}

protocol ProfileViewControllerDelegate: AnyObject {
    func profileViewController(_ controller: ProfileViewController?, wantsToNavigateTo conversation: ZMConversation)
    func profileViewController(_ controller: ProfileViewController?, wantsToCreateConversationWithName name: String?, users: UserSet)
}

protocol BackButtonTitleDelegate: AnyObject {
    func suggestedBackButtonTitle(for controller: ProfileViewController?) -> String?
}

extension ZMConversationType {
    var profileViewControllerContext: ProfileViewControllerContext {
        switch self {
        case .group:
            return .groupConversation
        default:
            return .oneToOneConversation
        }
    }
}

final class ProfileViewController: UIViewController {
    let viewModel: ProfileViewControllerViewModel
    weak var viewControllerDismisser: ViewControllerDismisser?

    private let profileFooterView: ProfileFooterView = ProfileFooterView()
    private let incomingRequestFooter: IncomingRequestFooterView = IncomingRequestFooterView()
    private let usernameDetailsView: UserNameDetailView = UserNameDetailView()
    private let securityLevelView = SecurityLevelView()

    private let profileTitleView: ProfileTitleView = ProfileTitleView()

    private var tabsController: TabBarController?

    var delegate: ProfileViewControllerDelegate? {
        get {
            return viewModel.delegate
        }
        set {
            viewModel.delegate = newValue
        }
    }

    // MARK: - init

    convenience init(user: UserType,
                     viewer: UserType,
                     conversation: ZMConversation? = nil,
                     context: ProfileViewControllerContext? = nil,
                     classificationProvider: ClassificationProviding? = ZMUserSession.shared(),
                     viewControllerDismisser: ViewControllerDismisser? = nil) {
        let profileViewControllerContext: ProfileViewControllerContext

        if let context = context {
            profileViewControllerContext = context
        } else {
            profileViewControllerContext = conversation?.conversationType.profileViewControllerContext ?? .oneToOneConversation
        }

        let viewModel = ProfileViewControllerViewModel(user: user,
                                                       conversation: conversation,
                                                       viewer: viewer,
                                                       context: profileViewControllerContext,
                                                       classificationProvider: classificationProvider)

        self.init(viewModel: viewModel)

        setupKeyboardFrameNotification()

        self.viewControllerDismisser = viewControllerDismisser
    }

    required init(viewModel: ProfileViewControllerViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)

        let user = viewModel.user

        if user.isTeamMember {
            user.refreshData()
            user.refreshMembership()
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Header
    private func setupHeader() {
        let userNameDetailViewModel = viewModel.makeUserNameDetailViewModel()
        usernameDetailsView.configure(with: userNameDetailViewModel)
        view.addSubview(usernameDetailsView)

        updateTitleView()

        profileTitleView.translatesAutoresizingMaskIntoConstraints = false
        navigationItem.titleView = profileTitleView

        navigationItem.titleView = profileTitleView

        securityLevelView.configure(with: viewModel.classification)
        view.addSubview(securityLevelView)
    }

    // MARK: - Actions
    private func bringUpConversationCreationFlow() {

        let controller = ConversationCreationController(preSelectedParticipants: viewModel.userSet, selfUser: ZMUser.selfUser())
        controller.delegate = self

        let wrappedController = controller.wrapInNavigationController(setBackgroundColor: true)
        wrappedController.modalPresentationStyle = .formSheet
        present(wrappedController, animated: true)
    }

    private func bringUpCancelConnectionRequestSheet(from targetView: UIView) {
        let user = viewModel.user

        let controller = UIAlertController.cancelConnectionRequest(for: user) { canceled in
            if !canceled {
                self.viewModel.cancelConnectionRequest {
                    self.returnToPreviousScreen()
                }
            }
        }

        presentAlert(controller, targetView: targetView)
    }

    override func loadView() {
        super.loadView()

        viewModel.viewModelDelegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(profileFooterView)
        view.addSubview(incomingRequestFooter)

        view.backgroundColor = SemanticColors.View.backgroundDefault

        setupHeader()
        setupTabsController()
        setupConstraints()
        updateFooterViews()
        updateShowVerifiedShield()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupNavigationItems()
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: navigationItem.titleView)
    }

    // MARK: - Keyboard frame observer

    private func setupKeyboardFrameNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardFrameDidChange(notification:)),
                                               name: UIResponder.keyboardDidChangeFrameNotification,
                                               object: nil)

    }

    @objc
    private func keyboardFrameDidChange(notification: Notification) {
        updatePopoverFrame()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return wr_supportedInterfaceOrientations
    }

    private func setupProfileDetailsViewController() -> ProfileDetailsViewController {
        // TODO: Pass the whole view Model/stuct/context
        let profileDetailsViewController = ProfileDetailsViewController(user: viewModel.user,
                                                                        viewer: viewModel.viewer,
                                                                        conversation: viewModel.conversation,
                                                                        context: viewModel.context)
        profileDetailsViewController.title = "profile.details.title".localized

        return profileDetailsViewController
    }

    private func setupTabsController() {
        var viewControllers = [UIViewController]()

        let profileDetailsViewController = setupProfileDetailsViewController()
        viewControllers.append(profileDetailsViewController)

        if viewModel.hasUserClientListTab {
            let userClientListViewController = UserClientListViewController(user: viewModel.user)
            viewControllers.append(userClientListViewController)
        }

        tabsController = TabBarController(viewControllers: viewControllers)
        tabsController?.delegate = self

        if viewModel.context == .deviceList, tabsController?.viewControllers.count > 1 {
            tabsController?.selectIndex(ProfileViewControllerTabBarIndex.devices.rawValue, animated: false)
        }

        addToSelf(tabsController!)

        tabsController?.isTabBarHidden = viewControllers.count < 2
        tabsController?.view.backgroundColor = SemanticColors.View.backgroundDefault
    }

    // MARK: - Constraints

    private func setupConstraints() {
        guard let tabsView = tabsController?.view else { fatal("Tabs view is not created") }

        let securityBannerHeight: CGFloat = securityLevelView.isHidden ? 0 : 24

        [usernameDetailsView, securityLevelView, tabsView, profileFooterView, incomingRequestFooter].prepareForLayout()

        NSLayoutConstraint.activate([
            usernameDetailsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            usernameDetailsView.topAnchor.constraint(equalTo: view.topAnchor),
            usernameDetailsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            securityLevelView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            securityLevelView.topAnchor.constraint(equalTo: usernameDetailsView.bottomAnchor),
            securityLevelView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            securityLevelView.heightAnchor.constraint(equalToConstant: securityBannerHeight),

            tabsView.topAnchor.constraint(equalTo: securityLevelView.bottomAnchor),

            tabsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabsView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            profileFooterView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            profileFooterView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            profileFooterView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            incomingRequestFooter.bottomAnchor.constraint(equalTo: profileFooterView.topAnchor),
            incomingRequestFooter.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            incomingRequestFooter.trailingAnchor.constraint(equalTo: view.trailingAnchor) ])
    }
}

extension ProfileViewController: ViewControllerDismisser {
    func dismiss(viewController: UIViewController, completion: (() -> Void)?) {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - Footer View

extension ProfileViewController: ProfileFooterViewDelegate, IncomingRequestFooterViewDelegate {

    func footerView(_ footerView: IncomingRequestFooterView, didRespondToRequestWithAction action: IncomingConnectionAction) {
        switch action {
        case .accept:
            viewModel.acceptConnectionRequest()
        case .ignore:
            viewModel.ignoreConnectionRequest()
        }

    }

    func footerView(_ footerView: ProfileFooterView, shouldPerformAction action: ProfileAction) {
        performAction(action, targetView: footerView.leftButton)
    }

    func footerView(_ footerView: ProfileFooterView,
                    shouldPresentMenuWithActions actions: [ProfileAction]) {
        let actionSheet = UIAlertController(title: nil,
                                            message: nil,
                                            preferredStyle: .actionSheet)

        actions.map { buildProfileAction($0, footerView: footerView) }
            .forEach(actionSheet.addAction)
        actionSheet.addAction(.cancel())
        presentAlert(actionSheet, targetView: footerView)
    }

    private func buildProfileAction(_ action: ProfileAction,
                                    footerView: ProfileFooterView) -> UIAlertAction {
        return UIAlertAction(title: action.buttonText,
                             style: .default) { _ in
            self.performAction(action, targetView: footerView)
        }
    }

    private func performAction(_ action: ProfileAction, targetView: UIView) {
        switch action {
        case .createGroup:
            bringUpConversationCreationFlow()
        case .mute(let isMuted):
            viewModel.updateMute(enableNotifications: isMuted)
        case .manageNotifications:
            presentNotificationsOptions(from: targetView)
        case .archive:
            viewModel.archiveConversation()
        case .deleteContents:
            presentDeleteConfirmationPrompt(from: targetView)
        case let .block(isBlocked):
            if isBlocked {
                handleBlockAndUnblock()
            } else {
                presentBlockActionSheet(from: targetView)
            }
        case .openOneToOne:
            viewModel.openOneToOneConversation()
        case .removeFromGroup:
            presentRemoveUserMenuSheetController(from: targetView)
        case .connect:
            viewModel.sendConnectionRequest()
        case .cancelConnectionRequest:
            bringUpCancelConnectionRequestSheet(from: targetView)
        case .openSelfProfile:
            openSelfProfile()
        }
    }

    private func openSelfProfile() {
        // Do not reveal list view for iPad regular mode
        let leftViewControllerRevealed: Bool
        if let presentingViewController = presentingViewController {
            leftViewControllerRevealed = !presentingViewController.isIPadRegular(device: UIDevice.current)
        } else {
            leftViewControllerRevealed = true
        }

        dismiss(animated: true) { [weak self] in
            self?.viewModel.transitionToListAndEnqueue(leftViewControllerRevealed: leftViewControllerRevealed) {
                ZClientViewController.shared?.conversationListViewController.topBarViewController.presentSettings()
            }
        }
    }

    /// Presents an alert as a popover if needed.
    private func presentAlert(_ alert: UIAlertController, targetView: UIView) {
        alert.popoverPresentationController?.sourceView = targetView
        alert.popoverPresentationController?.sourceRect = targetView.bounds.insetBy(dx: 8, dy: 8)
        alert.popoverPresentationController?.permittedArrowDirections = .down
        present(alert, animated: true)
    }

    // MARK: Legal Hold

    private var legalholdItem: UIBarButtonItem {
        let item = UIBarButtonItem(icon: .legalholdactive, target: self, action: #selector(presentLegalHoldDetails))
        item.setLegalHoldAccessibility()
        item.tintColor = SemanticColors.Icon.foregroundDefaultRed
        return item
    }

    @objc
    private func presentLegalHoldDetails() {
        let user = viewModel.user
        LegalHoldDetailsViewController.present(in: self, user: user)
    }

    // MARK: Block

    private func presentBlockActionSheet(from targetView: UIView) {
        let controller = UIAlertController(title: viewModel.blockTitle, message: nil, preferredStyle: .actionSheet)
        viewModel.allBlockResult.map { $0.action(handleBlockActions) }.forEach(controller.addAction)
        presentAlert(controller, targetView: targetView)
    }

    private func handleBlockActions(_ result: BlockResult) {
        guard case .block = result else { return }
        handleBlockAndUnblock()
    }

    private func handleBlockAndUnblock() {
        viewModel.handleBlockAndUnblock()
        updateFooterViews()
    }

    // MARK: Notifications

    private func presentNotificationsOptions(from targetView: UIView) {
        guard let conversation = viewModel.conversation else { return }

        let title = "\(conversation.displayName) • \(NotificationResult.title)"
        let controller = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        NotificationResult.allCases.map { $0.action(for: conversation, handler: viewModel.handleNotificationResult) }.forEach(controller.addAction)
        presentAlert(controller, targetView: targetView)
    }

    // MARK: Delete Contents

    private func presentDeleteConfirmationPrompt(from targetView: UIView) {
        guard let conversation = viewModel.conversation else { return }

        let controller = UIAlertController(title: ClearContentResult.title, message: nil, preferredStyle: .actionSheet)
        ClearContentResult.options(for: conversation).map { $0.action(viewModel.handleDeleteResult) }.forEach(controller.addAction)
        presentAlert(controller, targetView: targetView)
    }

    // MARK: Remove User

    private func presentRemoveUserMenuSheetController(from view: UIView) {
        let otherUser = viewModel.user

        let controller = UIAlertController(
            title: "profile.remove_dialog_message".localized(args: otherUser.name ?? ""),
            message: nil,
            preferredStyle: .actionSheet
        )

        let removeAction = UIAlertAction(title: "profile.remove_dialog_button_remove_confirm".localized, style: .destructive) { _ in
            self.viewModel.conversation?.removeOrShowError(participant: otherUser) { result in
                switch result {
                case .success:
                    self.returnToPreviousScreen()
                case .failure:
                    break
                }
            }
        }

        controller.addAction(removeAction)
        controller.addAction(.cancel())

        presentAlert(controller, targetView: view)
    }
}

extension ProfileViewController: ProfileViewControllerDelegate {

    func profileViewController(_ controller: ProfileViewController?, wantsToNavigateTo conversation: ZMConversation) {
        delegate?.profileViewController(controller, wantsToNavigateTo: conversation)
    }

    func profileViewController(_ controller: ProfileViewController?, wantsToCreateConversationWithName name: String?, users: UserSet) {
        // no-op
    }

}

extension ProfileViewController: ConversationCreationControllerDelegate {
    func conversationCreationController(_ controller: ConversationCreationController,
                                        didSelectName name: String,
                                        participants: UserSet,
                                        allowGuests: Bool,
                                        allowServices: Bool,
                                        enableReceipts: Bool) {
        controller.dismiss(animated: true) { [weak self] in
            self?.delegate?.profileViewController(self,
                                                  wantsToCreateConversationWithName: name,
                                                  users: participants)
        }
    }
}

extension ProfileViewController: TabBarControllerDelegate {
    func tabBarController(_ controller: TabBarController, tabBarDidSelectIndex: Int) {
        updateShowVerifiedShield()
    }
}

extension ProfileViewController: ProfileViewControllerViewModelDelegate {
    func updateTitleView() {
        profileTitleView.configure(with: viewModel.user)
    }

    func updateShowVerifiedShield() {
        profileTitleView.showVerifiedShield = viewModel.shouldShowVerifiedShield && tabsController?.selectedIndex != ProfileViewControllerTabBarIndex.devices.rawValue
    }

    func setupNavigationItems() {
        let legalHoldItem: UIBarButtonItem? = viewModel.hasLegalHoldItem ? legalholdItem : nil

        if navigationController?.viewControllers.count == 1 {
            navigationItem.rightBarButtonItem = navigationController?.closeItem()
            navigationItem.leftBarButtonItem = legalHoldItem
        } else {
            navigationItem.rightBarButtonItem = legalHoldItem
        }
        navigationItem.rightBarButtonItem?.accessibilityLabel = L10n.Accessibility.Profile.CloseButton.description
        navigationItem.backBarButtonItem?.accessibilityLabel = L10n.Accessibility.DeviceDetails.BackButton.description
    }

    func updateFooterViews() {
        // Actions
        let factory = viewModel.profileActionsFactory
        let actions = factory.makeActionsList()

        profileFooterView.delegate = self
        profileFooterView.isHidden = actions.isEmpty
        profileFooterView.configure(with: actions)
        view.bringSubviewToFront(profileFooterView)

        // Incoming Request Footer
        incomingRequestFooter.isHidden = viewModel.incomingRequestFooterHidden
        incomingRequestFooter.delegate = self
        view.bringSubviewToFront(incomingRequestFooter)
    }

    func returnToPreviousScreen() {
        if let navigationController = self.navigationController, navigationController.viewControllers.first != self {
            navigationController.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }

    func presentError(_ error: LocalizedError) {
        presentLocalizedErrorAlert(error)
    }
}
