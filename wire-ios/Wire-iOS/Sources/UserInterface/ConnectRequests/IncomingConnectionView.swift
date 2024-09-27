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

import Foundation
import WireCommonComponents
import WireSyncEngine

final class IncomingConnectionView: UIView {
    // MARK: Lifecycle

    // MARK: - Init

    init(
        user: UserType,
        classificationProvider: SecurityClassificationProviding? = ZMUserSession.shared()
    ) {
        self.user = user
        self.classificationProvider = classificationProvider

        super.init(frame: .zero)

        userImageView.userSession = ZMUserSession.shared()
        userImageView.initialsFont = UIFont.systemFont(ofSize: 55, weight: .semibold).monospaced()
        setup()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    // MARK: - Properties

    typealias UserAction = (UserType) -> Void
    typealias ConnectionRequest = L10n.Localizable.Inbox.ConnectionRequest

    var onAccept: UserAction?
    var onIgnore: UserAction?

    var user: UserType {
        didSet {
            setupLabelText()
            userImageView.user = user
        }
    }

    // MARK: Private

    private let usernameLabel = UILabel()
    private let userDetailView = UserNameDetailView()
    private let securityLevelView = SecurityLevelView()
    private let verticalStackView = UIStackView(axis: .vertical)
    private let userImageView = UserImageView()
    private let federatedIndicator = LabelIndicator(context: .federated)
    private let incomingConnectionFooter = UIView()
    private let warningView = WarningLabelView()
    private let acceptButton = ZMButton(
        style: .accentColorTextButtonStyle,
        cornerRadius: 16,
        fontSpec: .normalSemiboldFont
    )
    private let ignoreButton = ZMButton(
        style: .secondaryTextButtonStyle,
        cornerRadius: 16,
        fontSpec: .normalSemiboldFont
    )
    private let classificationProvider: SecurityClassificationProviding?

    // MARK: - Setup views and layout

    private func setup() {
        acceptButton.accessibilityLabel = "accept"
        acceptButton.setTitle(ConnectionRequest.connectButtonTitle, for: .normal)
        acceptButton.addTarget(self, action: #selector(onAcceptButton), for: .touchUpInside)

        ignoreButton.accessibilityLabel = "ignore"
        ignoreButton.setTitle(ConnectionRequest.ignoreButtonTitle, for: .normal)
        ignoreButton.addTarget(self, action: #selector(onIgnoreButton), for: .touchUpInside)

        userImageView.accessibilityLabel = "user image"
        userImageView.shouldDesaturate = false
        userImageView.size = .big
        userImageView.user = user

        updateFederatedIndicator()

        incomingConnectionFooter.addSubview(acceptButton)
        incomingConnectionFooter.addSubview(ignoreButton)

        warningView.update(withUser: user)
        warningView.translatesAutoresizingMaskIntoConstraints = false
        verticalStackView.spacing = 30.0
        verticalStackView.alignment = .center
        [usernameLabel, userDetailView, securityLevelView, verticalStackView, incomingConnectionFooter]
            .forEach(addSubview)
        [userImageView, federatedIndicator, warningView].forEach { verticalStackView.addArrangedSubview($0) }
        setupLabelText()
    }

    private func setupLabelText() {
        let viewModel = UserNameDetailViewModel(
            user: user,
            fallbackName: "",
            addressBookName: (user as? ZMUser)?.addressBookEntry?.cachedName
        )

        usernameLabel.attributedText = viewModel.title
        usernameLabel.accessibilityIdentifier = "name"
        userDetailView.configure(with: viewModel)
        securityLevelView.configure(
            with: [user],
            conversationDomain: nil,
            provider: classificationProvider
        )
    }

    private func createConstraints() {
        [
            incomingConnectionFooter,
            acceptButton,
            ignoreButton,
            usernameLabel,
            userDetailView,
            securityLevelView,
            federatedIndicator,
            userImageView,
            verticalStackView,
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            ignoreButton.leftAnchor.constraint(equalTo: incomingConnectionFooter.leftAnchor, constant: 16),
            ignoreButton.topAnchor.constraint(equalTo: incomingConnectionFooter.topAnchor, constant: 12),
            ignoreButton.bottomAnchor.constraint(equalTo: incomingConnectionFooter.bottomAnchor, constant: -16),
            ignoreButton.heightAnchor.constraint(equalToConstant: 40),
            ignoreButton.rightAnchor.constraint(equalTo: incomingConnectionFooter.centerXAnchor, constant: -8),

            acceptButton.rightAnchor.constraint(equalTo: incomingConnectionFooter.rightAnchor, constant: -16),
            acceptButton.leftAnchor.constraint(equalTo: incomingConnectionFooter.centerXAnchor, constant: 8),
            acceptButton.centerYAnchor.constraint(equalTo: ignoreButton.centerYAnchor),
            acceptButton.heightAnchor.constraint(equalTo: ignoreButton.heightAnchor),

            usernameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            usernameLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            usernameLabel.leftAnchor.constraint(greaterThanOrEqualTo: leftAnchor),

            userDetailView.centerXAnchor.constraint(equalTo: centerXAnchor),
            userDetailView.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 4),
            userDetailView.leftAnchor.constraint(greaterThanOrEqualTo: leftAnchor),

            securityLevelView.topAnchor.constraint(equalTo: userDetailView.bottomAnchor, constant: 4),
            securityLevelView.centerXAnchor.constraint(equalTo: centerXAnchor),
            securityLevelView.leadingAnchor.constraint(equalTo: leadingAnchor),
            securityLevelView.trailingAnchor.constraint(equalTo: trailingAnchor),
            securityLevelView.bottomAnchor.constraint(lessThanOrEqualTo: userImageView.topAnchor),

            userImageView.widthAnchor.constraint(equalTo: userImageView.heightAnchor),
            userImageView.heightAnchor.constraint(lessThanOrEqualToConstant: 264),

            verticalStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            verticalStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            verticalStackView.leftAnchor.constraint(greaterThanOrEqualTo: leftAnchor, constant: 54),

            incomingConnectionFooter.topAnchor.constraint(greaterThanOrEqualTo: warningView.bottomAnchor),
            incomingConnectionFooter.leftAnchor.constraint(equalTo: leftAnchor),
            incomingConnectionFooter.bottomAnchor.constraint(equalTo: bottomAnchor),
            incomingConnectionFooter.rightAnchor.constraint(equalTo: rightAnchor),
        ])
    }

    // MARK: - Methods

    private func updateFederatedIndicator() {
        federatedIndicator.isHidden = !user.isFederated
    }

    // MARK: - Actions

    @objc
    private func onAcceptButton(sender: AnyObject!) {
        onAccept?(user)
    }

    @objc
    private func onIgnoreButton(sender: AnyObject!) {
        onIgnore?(user)
    }
}
