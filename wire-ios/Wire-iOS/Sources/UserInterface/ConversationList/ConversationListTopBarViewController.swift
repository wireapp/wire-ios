//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import WireCommonComponents

typealias SelfUserType = UserType & SelfLegalHoldSubject

final class ConversationListTopBarViewController: UIViewController {

    private var availabilityViewController: UserStatusViewController? {
        didSet { availabilityViewController?.delegate = self }
    }

    private var account: Account
    private let selfUser: SelfUserType
    private var userSession: UserSession
    private var observerToken: NSObjectProtocol?

    var topBar: TopBar? {
        view as? TopBar
    }

    /// init a ConversationListTopBarViewController
    ///
    /// - Parameters:
    ///   - account: the Account of the user
    ///   - selfUser: the self user object. Allow to inject a mock self user for testing
    init(account: Account,
         selfUser: SelfUserType,
         userSession: UserSession) {
        self.account = account
        self.selfUser = selfUser
        self.userSession = userSession
        super.init(nibName: nil, bundle: nil)

        observerToken = userSession.addUserObserver(self, for: userSession.selfUser)

        viewRespectsSystemMinimumLayoutMargins = false
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = TopBar()
    }

    override func viewDidLoad() {
        topBar?.splitSeparator = false
        view.backgroundColor = SemanticColors.View.backgroundConversationList
        view.addBorder(for: .bottom)

        availabilityViewController?.didMove(toParent: self)

        updateTitleView()
        updateAccountView()
        updateLegalHoldIndictor()
    }

    // MARK: - Title View

    func updateTitleView() {
        topBar?.middleView = createTitleView()
    }

    private func createTitleView() -> UIView {
        if selfUser.isTeamMember {
            let availabilityViewController = UserStatusViewController(user: selfUser, options: .header, settings: .shared)
            addChild(availabilityViewController)
            self.availabilityViewController = availabilityViewController

            return availabilityViewController.view
        } else {
            let titleLabel = UILabel()

            titleLabel.text = selfUser.name
            titleLabel.font = FontSpec(.normal, .semibold).font
            titleLabel.textColor = SemanticColors.Label.textDefault
            titleLabel.accessibilityTraits = .header
            titleLabel.accessibilityValue = selfUser.name
            titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
            titleLabel.setContentHuggingPriority(.required, for: .horizontal)
            titleLabel.setContentHuggingPriority(.required, for: .vertical)

            return titleLabel
        }
    }

    private func createLegalHoldView() -> UIView {
        let imageView = UIImageView()

        imageView.setTemplateIcon(.legalholdactive, size: .tiny)
        imageView.tintColor = SemanticColors.Icon.foregroundDefaultRed
        imageView.isUserInteractionEnabled = true

        let imageViewContainer = UIView()
        imageViewContainer.setLegalHoldAccessibility()

        imageViewContainer.addSubview(imageView)

        imageViewContainer.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageViewContainer.widthAnchor.constraint(equalToConstant: CGFloat.ConversationListHeader.iconWidth),
            imageViewContainer.widthAnchor.constraint(equalTo: imageViewContainer.heightAnchor),

            imageView.centerXAnchor.constraint(equalTo: imageViewContainer.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: imageViewContainer.centerYAnchor)])

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(presentLegalHoldInfo))
        imageViewContainer.addGestureRecognizer(tapGestureRecognizer)

        return imageViewContainer
    }

    func createPendingLegalHoldRequestView() -> UIView {
        let button = IconButton(style: .circular)
        button.setBackgroundImageColor(SemanticColors.Icon.backgroundLegalHold.withAlphaComponent(0.8), for: .normal)

        button.setIcon(.clock, size: 12, for: .normal)
        button.setIconColor(.white, for: .normal)
        button.setIconColor(UIColor.white.withAlphaComponent(0.5), for: .highlighted)

        button.setLegalHoldAccessibility()
        button.accessibilityValue = L10n.Localizable.LegalholdRequest.Button.accessibility

        button.addTarget(self, action: #selector(presentLegalHoldRequest), for: .touchUpInside)

        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 24),
            button.heightAnchor.constraint(equalToConstant: 24)
        ])

        return button
    }

    func updateAccountView() {
        topBar?.leftView = createAccountView()
    }

    private func createAccountView() -> UIView {
        guard let session = ZMUserSession.shared() else {
            return UIView()
        }

        let user = ZMUser.selfUser(inUserSession: session)

        let accountView = AccountViewFactory.viewFor(account: account, user: user, displayContext: .conversationListHeader)

        accountView.unreadCountStyle = .current
        accountView.autoUpdateSelection = false

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(presentSettings))
        accountView.addGestureRecognizer(tapGestureRecognizer)

        accountView.accessibilityTraits = .button
        accountView.accessibilityIdentifier = "bottomBarSettingsButton"
        accountView.accessibilityHint = L10n.Accessibility.ConversationsList.AccountButton.hint

        if let selfUser = ZMUser.selfUser(),
           selfUser.clientsRequiringUserAttention.count > 0 {
            accountView.accessibilityLabel = L10n.Localizable.Self.NewDevice.Voiceover.label
        }

        return accountView.wrapInAvatarSizeContainer()
    }

    func updateLegalHoldIndictor() {
        switch selfUser.legalHoldStatus {
        case .disabled:
            topBar?.rightView = nil
        case .pending:
            topBar?.rightView = createPendingLegalHoldRequestView()
        case .enabled:
            topBar?.rightView = createLegalHoldView()
        }
    }

    @objc
    func presentLegalHoldInfo() {
        guard let selfUser = ZMUser.selfUser() else {
            assertionFailure("ZMUser.selfUser() is nil")
            return
        }

        LegalHoldDetailsViewController.present(in: self, user: selfUser, userSession: userSession)
    }

    @objc
    func presentLegalHoldRequest() {
        guard case .pending = selfUser.legalHoldStatus else {
            return
        }

        ZClientViewController.shared?.legalHoldDisclosureController?.discloseCurrentState(cause: .userAction)
    }

    @objc
    func presentSettings() {
        guard let selfUser = ZMUser.selfUser() else {
            assertionFailure("ZMUser.selfUser() is nil")
            return
        }

        let settingsViewController = createSettingsViewController(selfUser: selfUser)
        let keyboardAvoidingViewController = KeyboardAvoidingViewController(viewController: settingsViewController)

        if wr_splitViewController?.layoutSize == .compact {
            keyboardAvoidingViewController.modalPresentationStyle = .currentContext
            keyboardAvoidingViewController.transitioningDelegate = self
            present(keyboardAvoidingViewController, animated: true)
        } else {
            keyboardAvoidingViewController.modalPresentationStyle = .formSheet
            keyboardAvoidingViewController.view.backgroundColor = .black
            present(keyboardAvoidingViewController, animated: true)
        }
    }

    func createSettingsViewController(selfUser: ZMUser) -> UIViewController {
        let selfProfileViewController = SelfProfileViewController(selfUser: selfUser, userSession: userSession)
        return selfProfileViewController.wrapInNavigationController(navigationControllerClass: NavigationController.self)
    }

    func scrollViewDidScroll(scrollView: UIScrollView!) {
        topBar?.leftSeparatorLineView.scrollViewDidScroll(scrollView: scrollView)
        topBar?.rightSeparatorLineView.scrollViewDidScroll(scrollView: scrollView)
    }
}

extension ConversationListTopBarViewController: UIViewControllerTransitioningDelegate {

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SwizzleTransition(direction: .vertical)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SwizzleTransition(direction: .vertical)
    }
}

extension ConversationListTopBarViewController: UserObserving {

    func userDidChange(_ changes: UserChangeInfo) {

        if changes.nameChanged {
            availabilityViewController?.userStatus.name = changes.user.name ?? ""
        }

        if changes.availabilityChanged {
            availabilityViewController?.userStatus.availability = changes.user.availability
        }

        if changes.nameChanged || changes.teamsChanged {
            updateTitleView()
            updateAccountView()
        }

        if changes.legalHoldStatusChanged {
            updateLegalHoldIndictor()
        }
    }
}

// MARK: - UserStatusViewControllerDelegate

extension ConversationListTopBarViewController: UserStatusViewControllerDelegate {

    func userStatusViewController(_ viewController: UserStatusViewController, didSelect availability: Availability) {
        guard viewController === availabilityViewController else { return }

        userSession.perform { [weak self] in
            self?.selfUser.availability = availability
        }
    }
}

extension UIView {

    func wrapInAvatarSizeContainer() -> UIView {
        let container = UIView()

        container.addSubview(self)

        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: CGFloat.ConversationAvatarView.iconSize),
            container.heightAnchor.constraint(equalToConstant: CGFloat.ConversationAvatarView.iconSize),

            container.centerYAnchor.constraint(equalTo: centerYAnchor),
            container.centerXAnchor.constraint(equalTo: centerXAnchor)])

        return container

    }
}
