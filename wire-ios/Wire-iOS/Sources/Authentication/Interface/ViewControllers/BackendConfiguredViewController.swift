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

/// Reports that the user tapped "Continue" after the backend was configured.
protocol BackendConfiguredViewControllerDelegate: AnyObject {
    func backendConfiguredViewControllerDidTapContinue()
}

/// Shown right after a backend configuration link has been successfully applied,
/// before the user proceeds to `.provideCredentials`.
final class BackendConfiguredViewController: UIViewController, AuthenticationCoordinatedViewController {

    var authenticationCoordinator: AuthenticationCoordinator?

    private var delegate: BackendConfiguredViewControllerDelegate? {
        authenticationCoordinator
    }

    // MARK: - Views

    private let headlineLabel: DynamicFontLabel = {
        let label = DynamicFontLabel(
            text: L10n.Localizable.NoDefaultBackend.title,
            style: .largeTitle,
            color: SemanticColors.Label.textDefault
        )
        label.textAlignment = .center
        label.numberOfLines = 0
        label.accessibilityTraits.insert(.header)
        return label
    }()

    private let checkmarkImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "checkmark"))
        imageView.tintColor = SemanticColors.Icon.foregroundCheckMarkInSystemMessage
        imageView.contentMode = .scaleAspectFit
        imageView.isAccessibilityElement = false
        return imageView
    }()

    private let messageLabel: DynamicFontLabel = {
        let label = DynamicFontLabel(
            text: L10n.Localizable.NoDefaultBackend.Setup.message,
            fontSpec: .normalSemiboldFont,
            color: SemanticColors.Label.textDefault
        )
        label.numberOfLines = 0
        return label
    }()

    private let subtitleLabel: DynamicFontLabel = {
        let label = DynamicFontLabel(
            text: L10n.Localizable.NoDefaultBackend.Setup.subtitle,
            style: .body1,
            color: SemanticColors.Label.textDefault
        )
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let continueButton = ZMButton(
        style: .accentColorTextButtonStyle,
        cornerRadius: 16,
        fontSpec: .buttonBigSemibold
    )

    private var contentStackView: UIStackView!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = SemanticColors.View.backgroundDefault
        configureSubviews()
        createConstraints()
    }

    // MARK: - Setup

    private func configureSubviews() {
        continueButton.setTitle(L10n.Localizable.NoDefaultBackend.Setup.Button.continue, for: .normal)
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)

        let messageRow = UIStackView(arrangedSubviews: [checkmarkImageView, messageLabel])
        messageRow.axis = .horizontal
        messageRow.spacing = 8
        messageRow.alignment = .center
        messageRow.translatesAutoresizingMaskIntoConstraints = false

        let messageRowContainer = UIView()
        messageRowContainer.addSubview(messageRow)
        NSLayoutConstraint.activate([
            messageRow.centerXAnchor.constraint(equalTo: messageRowContainer.centerXAnchor),
            messageRow.topAnchor.constraint(equalTo: messageRowContainer.topAnchor),
            messageRow.bottomAnchor.constraint(equalTo: messageRowContainer.bottomAnchor),
            messageRow.leadingAnchor.constraint(greaterThanOrEqualTo: messageRowContainer.leadingAnchor),
            messageRow.trailingAnchor.constraint(lessThanOrEqualTo: messageRowContainer.trailingAnchor)
        ])

        let contentStack = UIStackView(arrangedSubviews: [
            messageRowContainer,
            subtitleLabel,
            continueButton
        ])
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.setCustomSpacing(32, after: subtitleLabel)

        view.addSubview(headlineLabel)
        view.addSubview(contentStack)
        contentStackView = contentStack

        for subview in [headlineLabel, contentStack, checkmarkImageView] {
            subview.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    private func createConstraints() {
        NSLayoutConstraint.activate([
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 20),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 20),

            continueButton.heightAnchor.constraint(equalToConstant: 48),

            headlineLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            headlineLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 31),
            headlineLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -31),

            contentStackView.topAnchor.constraint(
                greaterThanOrEqualTo: headlineLabel.bottomAnchor,
                constant: 16
            ),
            contentStackView.bottomAnchor.constraint(
                lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -24
            ),
            contentStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor).withPriority(.init(999)),
            contentStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 31),
            contentStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -31)
        ])
    }

    // MARK: - Actions

    @objc
    private func continueTapped() {
        delegate?.backendConfiguredViewControllerDidTapContinue()
    }
}

// MARK: - AuthenticationCoordinatedViewController

extension BackendConfiguredViewController {

    func displayError(_ error: Error) {
        // no-op
    }

    func executeErrorFeedbackAction(_ feedbackAction: AuthenticationErrorFeedbackAction) {
        // no-op
    }

    func didRewindToThisView() {
        // no-op
    }
}
