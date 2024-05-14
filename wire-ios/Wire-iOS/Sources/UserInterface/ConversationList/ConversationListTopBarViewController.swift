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

final class ConversationListTopBarViewController: UIViewController {

    weak var delegate: ConversationListTopBarViewControllerDelegate?

    private let account: Account

    private let selfUser: SelfUserType
    private var userSession: UserSession
    private let selfProfileViewControllerBuilder: ViewControllerBuilder
    private var observerToken: NSObjectProtocol?

    var topBar: TopBar? {
        view as? TopBar
    }

    private weak var titleViewLabel: UILabel?

    init(
        account: Account,
        selfUser: SelfUserType,
        userSession: UserSession,
        selfProfileViewControllerBuilder: ViewControllerBuilder
    ) {
        self.account = account
        self.selfUser = selfUser
        self.userSession = userSession
        self.selfProfileViewControllerBuilder = selfProfileViewControllerBuilder

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

        setupTitleView()
        setupNavigationBarItemStackViews()
        updateAccountView()
        updateLegalHoldIndictor()
        setupRightNavigationBarButtons()
    }

    // MARK: - Navigation Bar Items

    private func setupNavigationBarItemStackViews() {

        let leftNavigationBarItemsStackView = UIStackView()
        topBar?.leftView = leftNavigationBarItemsStackView

        let rightNavigationBarItemsStackView = UIStackView()
        rightNavigationBarItemsStackView.spacing = 24
        topBar?.rightView = rightNavigationBarItemsStackView
    }

    private func setupRightNavigationBarButtons() {
        guard let stackView = topBar?.rightView as? UIStackView else { return }

        let filerImage = UIImage(resource: .ConversationList.Header.filterConversations)
        let filterConversationsAction = UIAction(image: filerImage) { _ in
            assertionFailure("TODO [WPB-7298]: implement filtering")
        }
        stackView.addArrangedSubview(UIButton(primaryAction: filterConversationsAction))

        let newConversationImage = UIImage(resource: .ConversationList.Header.newConversation)
        let newConversationAction = UIAction(image: newConversationImage) { [weak self] _ in
            self?.delegate?.conversationListTopBarViewControllerDidSelectNewConversation(self!)
        }
        stackView.addArrangedSubview(UIButton(primaryAction: newConversationAction))
    }

    // MARK: - Title View

    func setupTitleView() {
        let titleLabel = UILabel()
        titleLabel.font = FontSpec(.normal, .semibold).font
        titleLabel.textColor = SemanticColors.Label.textDefault
        titleLabel.accessibilityTraits = .header
        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        titleLabel.text = L10n.Localizable.List.title
        titleLabel.accessibilityValue = L10n.Localizable.List.title
        topBar?.middleView = titleLabel
        self.titleViewLabel = titleLabel
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

    private func updateAccountView() {
        guard let stackView = topBar?.leftView as? UIStackView else { return }

        stackView.arrangedSubviews.first?.removeFromSuperview()
        stackView.insertArrangedSubview(createAccountView(), at: 0)
    }

    private func createAccountView() -> UIView {
        guard let session = ZMUserSession.shared() else { return .init() }

        let accountView = AccountViewBuilder(
            account: account,
            user: .selfUser(inUserSession: session),
            displayContext: .conversationListHeader
        ).build()
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
        guard let currentStackView = topBar?.leftView as? UIStackView else { return }

        currentStackView.arrangedSubviews[1...].forEach { $0.removeFromSuperview() }
        switch selfUser.legalHoldStatus {
        case .disabled:
            break
        case .pending:
            currentStackView.addArrangedSubview(createPendingLegalHoldRequestView())
        case .enabled:
            currentStackView.addArrangedSubview(createLegalHoldView())
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
            present(keyboardAvoidingViewController, animated: true)
        } else {
            keyboardAvoidingViewController.modalPresentationStyle = .formSheet
            keyboardAvoidingViewController.view.backgroundColor = .black
            present(keyboardAvoidingViewController, animated: true)
        }
    }

    func createSettingsViewController(selfUser: ZMUser) -> UIViewController {
        selfProfileViewControllerBuilder
            .build()
            .wrapInNavigationController(navigationControllerClass: NavigationController.self)
    }

    func scrollViewDidScroll(scrollView: UIScrollView) {
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

    func userDidChange(_ changeInfo: UserChangeInfo) {
        if changeInfo.nameChanged || changeInfo.teamsChanged {
            updateAccountView()
        }
        if changeInfo.legalHoldStatusChanged {
            updateLegalHoldIndictor()
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
            container.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
        return container
    }
}
