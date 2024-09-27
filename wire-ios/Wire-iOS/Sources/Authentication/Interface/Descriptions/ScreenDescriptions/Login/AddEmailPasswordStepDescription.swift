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
import WireUtilities

// MARK: - AddEmailPasswordStepDescription

final class AddEmailPasswordStepDescription: DefaultValidatingStepDescription {
    // MARK: Lifecycle

    init() {
        self.backButton = BackButtonDescription()
        self.headline = L10n.Localizable.Registration.AddEmailPassword.Hero.title
        self.subtext = .markdown(from: L10n.Localizable.Registration.AddEmailPassword.Hero.paragraph, style: .login)
        self.initialValidation = .info(PasswordRuleSet.localizedErrorMessage)
        self.footerView = nil

        let loginDescription = CTAFooterDescription()
        self.secondaryView = loginDescription
        loginDescription.ctaButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)

        emailPasswordFieldDescription.textField.delegate = self

        updateLoginButtonState(emailPasswordFieldDescription.textField)
    }

    // MARK: Internal

    let backButton: BackButtonDescription?
    let headline: String
    let subtext: NSAttributedString?
    let secondaryView: AuthenticationSecondaryViewDescription?
    let initialValidation: ValueValidation
    let footerView: AuthenticationFooterViewDescription?

    var mainView: ViewDescriptor & ValueSubmission {
        emailPasswordFieldDescription
    }

    @objc
    func loginButtonTapped(sender: Any) {
        if let passwordError = emailPasswordFieldDescription.textField.passwordValidationError {
            emailPasswordFieldDescription.valueValidated?(.error(passwordError, showVisualFeedback: true))
            return
        }

        let credentials = (
            emailPasswordFieldDescription.textField.emailField.input,
            emailPasswordFieldDescription.textField.passwordField.input
        )
        emailPasswordFieldDescription.valueSubmitted?(credentials)
    }

    // MARK: Private

    private let emailPasswordFieldDescription = EmailPasswordFieldDescription(
        forRegistration: true,
        usePasswordDeferredValidation: true
    )

    private func updateLoginButtonState(_ textField: EmailPasswordTextField) {
        (secondaryView as? CTAFooterDescription)?.ctaButton.isEnabled = textField.emailField.isInputValid && textField
            .passwordField.isInputValid
    }
}

// MARK: EmailPasswordTextFieldDelegate

extension AddEmailPasswordStepDescription: EmailPasswordTextFieldDelegate {
    func textFieldDidUpdateText(_ textField: EmailPasswordTextField) {
        (secondaryView as? CTAFooterDescription)?.ctaButton.isEnabled = textField.emailField.isInputValid && textField
            .passwordField.isInputValid
    }

    func textField(_ textField: EmailPasswordTextField, didConfirmCredentials credentials: (String, String)) {}

    func textFieldDidSubmitWithValidationError(_: EmailPasswordTextField) {}
}

// MARK: - CTAFooterDescription

private final class CTAFooterDescription: ViewDescriptor, AuthenticationSecondaryViewDescription {
    // MARK: Lifecycle

    init() {
        ctaButton.setTitle(L10n.Localizable.AddEmailPasswordStep.CtaButton.title.capitalized, for: .normal)
    }

    // MARK: Internal

    var actioner: AuthenticationActioner?

    let ctaButton = ZMButton(
        style: .accentColorTextButtonStyle,
        cornerRadius: 16,
        fontSpec: .buttonBigSemibold
    )

    var views: [ViewDescriptor] {
        [self]
    }

    func create() -> UIView {
        let containerView = UIView()
        containerView.addSubview(ctaButton)

        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            ctaButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 31),
            ctaButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 31),
            ctaButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -31),
            ctaButton.heightAnchor.constraint(equalToConstant: 48),
            ctaButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 0),
        ])

        return containerView
    }

    func display(on error: Error) -> ViewDescriptor? {
        nil
    }
}
