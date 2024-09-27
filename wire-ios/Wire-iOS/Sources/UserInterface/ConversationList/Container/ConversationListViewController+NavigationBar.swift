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
import WireSyncEngine

extension ConversationListViewController {
    func conversationListViewControllerViewModelRequiresUpdatingAccountView(_: ViewModel) {
        updateAccountView()
    }

    func conversationListViewControllerViewModelRequiresUpdatingLegalHoldIndictor(_: ViewModel) {
        updateLegalHoldIndictor()
    }

    // MARK: - Account View

    func updateAccountView() {
        navigationItem.leftBarButtonItem = .init(customView: createAccountView())
    }

    private func createAccountView() -> UIView {
        guard let session = ZMUserSession.shared() else {
            return .init()
        }

        let user = ZMUser.selfUser(inUserSession: session)

        let accountView = AccountViewBuilder(
            account: viewModel.account,
            user: user,
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
           !selfUser.clientsRequiringUserAttention.isEmpty {
            accountView.accessibilityLabel = L10n.Localizable.Self.NewDevice.Voiceover.label
        }

        return accountView.wrapInAvatarSizeContainer()
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

    // MARK: - Title View

    func updateTitleView() {
        if viewModel.selfUserLegalHoldSubject.isTeamMember {
            defer { userStatusViewController?.userStatus = viewModel.selfUserStatus }
            guard userStatusViewController == nil else {
                return
            }

            let userStatusViewController = UserStatusViewController(options: .header, settings: .shared)
            userStatusViewController.delegate = self
            navigationController?.addChild(userStatusViewController)
            navigationItem.titleView = userStatusViewController.view
            userStatusViewController.didMove(toParent: navigationController)
            self.userStatusViewController = userStatusViewController

        } else {
            defer {
                titleViewLabel?.text = viewModel.selfUserStatus.name
                titleViewLabel?.accessibilityValue = viewModel.selfUserStatus.name
            }
            guard titleViewLabel == nil else {
                return
            }
            if let userStatusViewController {
                removeChild(userStatusViewController)
            }

            let titleLabel = UILabel()
            titleLabel.font = FontSpec(.normal, .semibold).font
            titleLabel.textColor = SemanticColors.Label.textDefault
            titleLabel.accessibilityTraits = .header
            titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
            titleLabel.setContentHuggingPriority(.required, for: .horizontal)
            titleLabel.setContentHuggingPriority(.required, for: .vertical)
            navigationItem.titleView = titleLabel
            titleViewLabel = titleLabel
        }
    }

    // MARK: - Legal Hold

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
            imageView.centerYAnchor.constraint(equalTo: imageViewContainer.centerYAnchor),
        ])

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
            button.heightAnchor.constraint(equalToConstant: 24),
        ])

        return button
    }

    func updateLegalHoldIndictor() {
        switch viewModel.selfUserLegalHoldSubject.legalHoldStatus {
        case .disabled:
            navigationItem.rightBarButtonItem = nil
        case .pending:
            navigationItem.rightBarButtonItem = .init(customView: createPendingLegalHoldRequestView())
        case .enabled:
            navigationItem.rightBarButtonItem = .init(customView: createLegalHoldView())
        }
    }

    @objc
    func presentLegalHoldInfo() {
        guard let selfUser = ZMUser.selfUser() else {
            assertionFailure("ZMUser.selfUser() is nil")
            return
        }

        LegalHoldDetailsViewController.present(
            in: self,
            user: selfUser,
            userSession: viewModel.userSession,
            mainCoordinator: mainCoordinator
        )
    }

    @objc
    func presentLegalHoldRequest() {
        guard case .pending = viewModel.selfUserLegalHoldSubject.legalHoldStatus else {
            return
        }

        ZClientViewController.shared?.legalHoldDisclosureController?.discloseCurrentState(cause: .userAction)
    }
}

// MARK: - ConversationListViewController + UserStatusViewControllerDelegate

extension ConversationListViewController: UserStatusViewControllerDelegate {
    func userStatusViewController(_ viewController: UserStatusViewController, didSelect availability: Availability) {
        guard viewController === userStatusViewController else {
            return
        }

        // this should be done by some use case instead of accessing the `session` and the `UserType` directly here
        viewModel.userSession.perform { [weak self] in
            self?.viewModel.selfUserLegalHoldSubject.availability = availability
        }
    }
}

// MARK: - wrapInAvatarSizeContainer

extension UIView {
    func wrapInAvatarSizeContainer() -> UIView {
        let container = UIView()
        container.addSubview(self)
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: CGFloat.ConversationAvatarView.iconSize),
            container.heightAnchor.constraint(equalToConstant: CGFloat.ConversationAvatarView.iconSize),

            container.centerYAnchor.constraint(equalTo: centerYAnchor),
            container.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])
        return container
    }
}
