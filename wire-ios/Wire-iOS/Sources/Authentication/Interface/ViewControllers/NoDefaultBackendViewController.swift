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

import SwiftUI
import UIKit
import WireCommonComponents
import WireDesign
import WireTransport

/// Reports that the user entered or scanned a configuration link that was
/// successfully validated and applied.
protocol NoDefaultBackendViewControllerDelegate: AnyObject {
    func noDefaultBackendViewControllerDidConfigureBackend(_ configurationURL: URL)
    func didRequestUserConfirmationToSwitchToBackend(environment: BackendEnvironment, didConfirm: @escaping (Bool) -> Void)
}

/// Displayed when the app has no default backend bundled. Lets the user enter
/// or scan a backend configuration link; once it's validated and applied, the
/// flow moves on to `.provideCredentials`.
final class NoDefaultBackendViewController: UIViewController, AuthenticationCoordinatedViewController {

    var authenticationCoordinator: AuthenticationCoordinator?

    private var delegate: NoDefaultBackendViewControllerDelegate? {
        authenticationCoordinator
    }

    private let viewModel = NoDefaultBackendViewModel()

    // MARK: - Views

    private let headlineLabel: DynamicFontLabel = {
        let label = DynamicFontLabel(
            text: L10n.Localizable.Registration.Signin.title,
            style: .largeTitle,
            color: SemanticColors.Label.textDefault
        )
        label.textAlignment = .center
        label.numberOfLines = 0
        label.accessibilityTraits.insert(.header)
        return label
    }()

    private let subheadlineLabel: DynamicFontLabel = {
        let label = DynamicFontLabel(
            text: L10n.Localizable.NoDefaultBackend.subheadline,
            style: .body1,
            color: SemanticColors.Label.textDefault
        )
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let paragraphLabel: DynamicFontLabel = {
        let label = DynamicFontLabel(
            text: L10n.Localizable.NoDefaultBackend.paragraph,
            style: .body1,
            color: SemanticColors.Label.textDefault
        )
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let fieldCaptionLabel: UILabel = {
        let label = UILabel()
        label.text = L10n.Localizable.NoDefaultBackend.TextField.caption
        label.font = FontSpec.headerRegularFont.font
        label.textColor = .accent()
        label.numberOfLines = 0
        return label
    }()

    private let configurationTextField = ValidatedTextField(kind: .unknown, style: .default)

    private let qrCodeButton: IconButton = {
        let button = IconButton()
        button.layer.borderColor = SemanticColors.View.borderInputBar.cgColor
        button.tintColor = SemanticColors.Icon.foregroundDefault

        let boldConfig = UIImage.SymbolConfiguration(weight: .black)
        let boldImage = UIImage(systemName: "qrcode", withConfiguration: boldConfig)
        button.setImage(boldImage, for: .normal)

        button.accessibilityIdentifier = "QR code button"
        button.accessibilityLabel = L10n.Accessibility.NoDefaultBackend.QrCodeButton.description

        return button
    }()

    private let errorLabel: UILabel = {
        let label = UILabel()
        label.font = AuthenticationStepController.errorMessageFont
        label.textColor = SemanticColors.Label.textErrorDefault
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        label.accessibilityIdentifier = "validation-failure"
        return label
    }()

    private let configureButton = ZMButton(
        style: .accentColorTextButtonStyle,
        cornerRadius: 16,
        fontSpec: .buttonBigSemibold
    )

    private var contentStackView: UIStackView!
    private var contentCenter: NSLayoutConstraint!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.delegate = self
        view.backgroundColor = SemanticColors.View.backgroundDefault
        configureSubviews()
        createConstraints()
        configureObservers()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configurationTextField.becomeFirstResponder()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func configureSubviews() {
        configurationTextField.showConfirmButton = false
        configurationTextField.keyboardType = .URL
        configurationTextField.autocapitalizationType = .none
        configurationTextField.autocorrectionType = .no
        configurationTextField.attributedPlaceholder = NSAttributedString(
            string: L10n.Localizable.NoDefaultBackend.TextField.placeholder,
            attributes: [
                .font: UIFont.systemFont(ofSize: 17),
                .foregroundColor: UIColor.Team.placeholderColor
            ]
        )
        configurationTextField.accessibilityIdentifier = "ConfigurationLinkTextField"
        configurationTextField.delegate = self
        configurationTextField.accessoryStack.addArrangedSubview(qrCodeButton)
        configurationTextField.addTarget(self, action: #selector(textFieldEditingChanged), for: .editingChanged)

        qrCodeButton.addTarget(self, action: #selector(qrButtonTapped), for: .touchUpInside)

        configureButton.setTitle(L10n.Localizable.NoDefaultBackend.Button.configure, for: .normal)
        configureButton.addTarget(self, action: #selector(configureButtonTapped), for: .touchUpInside)
        configureButton.isEnabled = false

        let fieldStack = UIStackView(arrangedSubviews: [fieldCaptionLabel, configurationTextField])
        fieldStack.axis = .vertical
        fieldStack.spacing = 8

        let contentStack = UIStackView(arrangedSubviews: [
            subheadlineLabel,
            paragraphLabel,
            fieldStack,
            errorLabel,
            configureButton
        ])
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.setCustomSpacing(32, after: paragraphLabel)
        contentStack.setCustomSpacing(8, after: fieldStack)

        view.addSubview(headlineLabel)
        view.addSubview(contentStack)
        contentStackView = contentStack

        for subview in [headlineLabel, contentStack, fieldStack, qrCodeButton] {
            subview.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    private func createConstraints() {
        contentCenter = contentStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        contentCenter.priority = .init(999)

        NSLayoutConstraint.activate([
            qrCodeButton.widthAnchor.constraint(equalToConstant: 32),
            qrCodeButton.heightAnchor.constraint(equalToConstant: 32),

            configurationTextField.heightAnchor.constraint(equalToConstant: 48),
            configureButton.heightAnchor.constraint(equalToConstant: 48),

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
            contentCenter,
            contentStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 31),
            contentStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -31)
        ])
    }

    private func configureObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardFrameChange),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardFrameChange),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc
    private func handleKeyboardFrameChange(notification: Notification) {
        let keyboardFrame = UIView.keyboardFrame(in: view, forKeyboardNotification: notification)

        guard keyboardFrame.height > 0 else {
            contentCenter.constant = 0
            return
        }

        let contentRect = CGRect(
            x: contentStackView.frame.origin.x,
            y: contentStackView.frame.origin.y + contentCenter.constant,
            width: contentStackView.frame.width,
            height: contentStackView.frame.height + 24
        )

        let overlap = keyboardFrame.intersection(contentRect).height

        if overlap > abs(contentCenter.constant) {
            contentCenter.constant = -overlap
        }
    }

    // MARK: - QR scanner

    @objc
    private func qrButtonTapped() {
        let scanner = QRCodeScannerViewController()
        scanner.title = "Scan QR code"
        scanner.onQRCodeScanned = { [weak self] scannedValue in
            self?.handleScannedCode(scannedValue)
        }

        let navigationController = UINavigationController(rootViewController: scanner)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()

        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.compactAppearance = appearance
        scanner.navigationItem.rightBarButtonItem = UIBarButtonItem.closeButton(
            action: UIAction { [weak navigationController] _ in
                navigationController?.dismiss(animated: true)
            },
            accessibilityLabel: L10n.Accessibility.NoDefaultBackend.CloseButton.description
        )

        present(navigationController, animated: true)
    }

    private func handleScannedCode(_ scannedValue: String) {
        presentedViewController?.dismiss(animated: true) { [weak self] in
            self?.configurationTextField.text = scannedValue
            self?.updateConfigureButtonEnabled()
            self?.viewModel.submitConfigurationLink(scannedValue)
        }
    }

    // MARK: - Configuration

    @objc
    private func configureButtonTapped() {
        configurationTextField.resignFirstResponder()
        viewModel.submitConfigurationLink(configurationTextField.text ?? "")
    }

    @objc
    private func textFieldEditingChanged() {
        updateConfigureButtonEnabled()
    }

    private func updateConfigureButtonEnabled() {
        let isEmpty = (configurationTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        configureButton.isEnabled = !isEmpty
    }

    private func setLoading(_ isLoading: Bool) {
        qrCodeButton.isEnabled = !isLoading
        configurationTextField.isUserInteractionEnabled = !isLoading

        if isLoading {
            configureButton.isEnabled = false
        } else {
            updateConfigureButtonEnabled()
        }
    }

    private func showError(_ message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
        configurationTextField.layer.borderColor = SemanticColors.Icon.foregroundDefaultRed.cgColor
    }

    private func clearError() {
        errorLabel.text = nil
        errorLabel.isHidden = true
    }
}

// MARK: - UITextFieldDelegate

extension NoDefaultBackendViewController: UITextFieldDelegate {

    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        clearError()
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        viewModel.submitConfigurationLink(configurationTextField.text ?? "")
        return true
    }
}

// MARK: - NoDefaultBackendViewModelDelegate

extension NoDefaultBackendViewController: NoDefaultBackendViewModelDelegate {

    func noDefaultBackendViewModel(_ viewModel: NoDefaultBackendViewModel, didChangeLoading isLoading: Bool) {
        setLoading(isLoading)
    }

    func noDefaultBackendViewModel(_ viewModel: NoDefaultBackendViewModel, didFailWithMessage message: String) {
        showError(message)
    }

    func noDefaultBackendViewModel(_ viewModel: NoDefaultBackendViewModel, didConfigureBackend configurationURL: URL) {
        delegate?.noDefaultBackendViewControllerDidConfigureBackend(configurationURL)

    }
    
    func noDefaultBackendViewModel(_ viewModel: NoDefaultBackendViewModel, requestUserConfirmationForBackendSwitch environment: BackendEnvironment, didConfirm: @escaping (Bool) -> Void) {
        delegate?.didRequestUserConfirmationToSwitchToBackend(environment: environment, didConfirm: didConfirm)
    }
    
}

// MARK: - AuthenticationCoordinatedViewController

extension NoDefaultBackendViewController {

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
