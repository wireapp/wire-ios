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

protocol EmailPasswordTextFieldDelegate: AnyObject {
    func textFieldDidUpdateText(_ textField: EmailPasswordTextField)
    func textFieldDidSubmitWithValidationError(_ textField: EmailPasswordTextField)
    func textField(_ textField: EmailPasswordTextField, didConfirmCredentials credentials: (String, String))
    func textField(_ textField: UITextField, editing: Bool)
}

extension EmailPasswordTextFieldDelegate {
    func textField(_ textField: UITextField, editing: Bool) {}
}

class RevisedEmailPasswordTextField: EmailPasswordTextField {

    override func configureConstraints() {
        [passwordField, emailField, contentStack].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            // dimensions
            passwordField.heightAnchor.constraint(equalToConstant: 48),
            emailField.heightAnchor.constraint(equalToConstant: 48),

            // contentStack
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 31),
            contentStack.topAnchor.constraint(equalTo: topAnchor),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -31),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

}

class EmailPasswordTextField: UIView, MagicTappable {

    let emailField = ValidatedTextField(kind: .email, cornerRadius: 12, setNewColors: true, style: .default)
    let passwordField = ValidatedTextField(kind: .password(isNew: false), cornerRadius: 12, setNewColors: true, style: .default)
    let contentStack = UIStackView()

    var hasPrefilledValue: Bool = false
    var allowEditingPrefilledValue: Bool = true {
        didSet {
            updateEmailFieldisEnabled()
        }
    }

    weak var delegate: EmailPasswordTextFieldDelegate?

    private(set) var emailValidationError: TextFieldValidator.ValidationError? = .tooShort(kind: .email)
    private(set) var passwordValidationError: TextFieldValidator.ValidationError? = .tooShort(kind: .email)

    // MARK: - Helpers

    var colorSchemeVariant: ColorSchemeVariant = .light {
        didSet {
            passwordField.colorSchemeVariant = colorSchemeVariant
            emailField.colorSchemeVariant = colorSchemeVariant
        }
    }

    var isPasswordEmpty: Bool {
        return passwordField.input.isEmpty
    }

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

    func configureSubviews() {
        contentStack.axis = .vertical
        contentStack.spacing = 36
        contentStack.alignment = .fill
        contentStack.distribution = .fill
        addSubview(contentStack)

        emailField.delegate = self
        emailField.addDoneButtonOnKeyboard()
        emailField.textFieldValidationDelegate = self
        emailField.placeholder = L10n.Localizable.Email.placeholder.capitalized
        emailField.showConfirmButton = false
        emailField.addTarget(self, action: #selector(textInputDidChange), for: .editingChanged)
        emailField.colorSchemeVariant = colorSchemeVariant
        emailField.addDoneButtonOnKeyboard()
        emailField.enableConfirmButton = { [weak self] in
            self?.emailValidationError == nil
        }

        contentStack.addArrangedSubview(emailField)

        passwordField.delegate = self
        passwordField.textFieldValidationDelegate = self
        passwordField.placeholder = L10n.Localizable.Password.placeholder.capitalized
        passwordField.addTarget(self, action: #selector(textInputDidChange), for: .editingChanged)
        passwordField.colorSchemeVariant = colorSchemeVariant
        passwordField.addDoneButtonOnKeyboard()
        passwordField.enableConfirmButton = { [weak self] in
            self?.isPasswordEmpty == false
        }

        contentStack.addArrangedSubview(passwordField)
    }

    func configureConstraints() {
        [passwordField, emailField, contentStack].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            // dimensions
            passwordField.heightAnchor.constraint(equalToConstant: 48),
            emailField.heightAnchor.constraint(equalToConstant: 48),

            // contentStack
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStack.topAnchor.constraint(equalTo: topAnchor),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    /// Pre-fills the e-mail text field.
    func prefill(email: String?) {
        hasPrefilledValue = email != nil
        emailField.text = email
        updateEmailFieldisEnabled()
    }

    func updateEmailFieldisEnabled() {
        emailField.isEnabled = !hasPrefilledValue || allowEditingPrefilledValue
    }

    // MARK: - Appearance

    func setTextColor(_ color: UIColor) {
        emailField.textColor = color
        passwordField.textColor = color
    }

    func setBackgroundColor(_ color: UIColor) {
        emailField.backgroundColor = color
        passwordField.backgroundColor = color
    }

    // MARK: - Responder

    override var isFirstResponder: Bool {
        return emailField.isFirstResponder || passwordField.isFirstResponder
    }

    override var canBecomeFirstResponder: Bool {
        return logicalFirstResponder.canBecomeFirstResponder
    }

    override func becomeFirstResponder() -> Bool {
        return logicalFirstResponder.becomeFirstResponder()
    }

    override var canResignFirstResponder: Bool {
        return emailField.canResignFirstResponder || passwordField.canResignFirstResponder
    }

    @discardableResult override func resignFirstResponder() -> Bool {
        if emailField.isFirstResponder {
            return emailField.resignFirstResponder()
        } else if passwordField.isFirstResponder {
            return passwordField.resignFirstResponder()
        } else {
            return false
        }
    }

    /// Returns the text field that should be used to become first responder.
    private var logicalFirstResponder: UITextField {
        // If we have a pre-filled email and the password field is empty, start with the password field
        if hasPrefilledValue && (passwordField.text ?? "").isEmpty {
            return passwordField
        } else {
            return emailField
        }
    }

    // MARK: - Submission

    @objc func confirmButtonTapped() {
        guard emailValidationError == nil && passwordValidationError == nil else {
            delegate?.textFieldDidSubmitWithValidationError(self)
            return
        }

        delegate?.textField(self, didConfirmCredentials: (emailField.input, passwordField.input))
    }

    func performMagicTap() -> Bool {
        guard emailField.isInputValid && passwordField.isInputValid else {
            return false
        }

        confirmButtonTapped()
        return true
    }

    @objc private func textInputDidChange(sender: UITextField) {
        if sender == emailField {
            emailField.validateInput()
        } else if sender == passwordField {
            passwordField.validateInput()
        }

        delegate?.textFieldDidUpdateText(self)
    }

    var hasValidInput: Bool {
        return emailField.isInputValid && passwordField.isInputValid
    }

}

extension EmailPasswordTextField: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.textField(textField, editing: true)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        delegate?.textField(textField, editing: false)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            emailField.validateInput()
            passwordField.validateInput()
            confirmButtonTapped()
        }

        return true
    }

}

extension EmailPasswordTextField: TextFieldValidationDelegate {
    func validationUpdated(sender: UITextField, error: TextFieldValidator.ValidationError?) {
        if sender == emailField {
            emailValidationError = error
        } else {
            passwordValidationError = error
        }
    }
}
