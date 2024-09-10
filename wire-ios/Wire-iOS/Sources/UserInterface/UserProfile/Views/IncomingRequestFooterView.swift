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
import WireDesign

protocol IncomingRequestFooterViewDelegate: AnyObject {
    /// Called when the user accepts or denies a connection request.
    func footerView(
        _ footerView: IncomingRequestFooterView,
        didRespondToRequestWithAction action: IncomingConnectionAction
    )
}

/**
 * A view that lets the user accept a connection request.
 */

class IncomingRequestFooterView: UIView {
    let titleLabel = UILabel()
    let acceptButton = LegacyButton(fontSpec: .smallSemiboldFont)
    let ignoreButton = LegacyButton(fontSpec: .smallSemiboldFont)

    let contentStack = UIStackView()

    /// The delegate of the view, that will be called when the user accepts or denies the request.
    weak var delegate: IncomingRequestFooterViewDelegate?

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
        configureConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    private func configureSubviews() {
        titleLabel.text = L10n.Localizable.connectionRequestPendingTitle.localizedUppercase
        titleLabel.font = .smallSemiboldFont
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        acceptButton.accessibilityIdentifier = "accept"
        acceptButton.setTitle(
            L10n.Localizable.Inbox.ConnectionRequest.connectButtonTitle.localizedUppercase,
            for: .normal
        )
        acceptButton.addTarget(self, action: #selector(acceptButtonTapped), for: .touchUpInside)
        acceptButton.layer.cornerRadius = 16

        ignoreButton.accessibilityIdentifier = "ignore"
        ignoreButton.setTitle(
            L10n.Localizable.Inbox.ConnectionRequest.ignoreButtonTitle.localizedUppercase,
            for: .normal
        )
        ignoreButton.addTarget(self, action: #selector(ignoreButtonTapped), for: .touchUpInside)
        ignoreButton.layer.cornerRadius = 16

        titleLabel.textColor = SemanticColors.Label.textDefault
        backgroundColor = SemanticColors.View.backgroundDefault

        acceptButton.applyStyle(.accentColorTextButtonStyle)

        ignoreButton.applyStyle(.secondaryTextButtonStyle)

        let buttonsStack = UIStackView(arrangedSubviews: [ignoreButton, acceptButton])
        buttonsStack.axis = .horizontal
        buttonsStack.spacing = 16
        buttonsStack.alignment = .fill
        buttonsStack.distribution = .fillEqually

        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = 24
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(buttonsStack)
        addSubview(contentStack)
    }

    private func configureConstraints() {
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // buttons
            ignoreButton.heightAnchor.constraint(equalToConstant: 48),
            acceptButton.heightAnchor.constraint(equalToConstant: 48),

            // contentStack
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24),
        ])
    }

    // MARK: - Events

    @objc
    private func acceptButtonTapped() {
        delegate?.footerView(self, didRespondToRequestWithAction: .accept)
    }

    @objc
    private func ignoreButtonTapped() {
        delegate?.footerView(self, didRespondToRequestWithAction: .ignore)
    }
}
