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

final class TextFieldDescription: NSObject, ValueSubmission {
    let placeholder: String
    let actionDescription: String
    let kind: ValidatedTextField.Kind
    var valueSubmitted: ValueSubmitted?
    var valueValidated: ValueValidated?
    var acceptsInput = true
    var validationError: TextFieldValidator.ValidationError?
    var showConfirmButton = true
    var canSubmit: (() -> Bool)?
    var textField: ValidatedTextField?
    var useDeferredValidation = false
    var acceptInvalidInput = true

    init(placeholder: String, actionDescription: String, kind: ValidatedTextField.Kind) {
        self.placeholder = placeholder
        self.actionDescription = actionDescription
        self.kind = kind
        self.validationError = .tooShort(kind: kind)
        super.init()

        self.canSubmit = { [weak self] in
            (self?.acceptsInput == true) && (self?.validationError == nil)
        }
    }
}

extension TextFieldDescription: ViewDescriptor {
    func create() -> UIView {
        let textField = ValidatedTextField(kind: kind, style: .default)
        textField.enablesReturnKeyAutomatically = true
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = placeholder
        textField.delegate = self
        textField.textFieldValidationDelegate = self
        textField.confirmButton.addTarget(
            self,
            action: #selector(TextFieldDescription.confirmButtonTapped(_:)),
            for: .touchUpInside
        )
        textField.addTarget(self, action: #selector(TextFieldDescription.editingChanged), for: .editingChanged)
        textField.confirmButton.accessibilityLabel = actionDescription
        textField.showConfirmButton = showConfirmButton
        textField.accessibilityHint = PasswordRuleSet.localizedErrorMessage

        textField.enableConfirmButton = { [weak self] in
            if self?.useDeferredValidation == true {
                return !textField.input.isEmpty
            } else {
                return self?.canSubmit?() == true
            }
        }

        self.textField = textField

        let textfieldContainer = UIView()
        textfieldContainer.addSubview(textField)
        textfieldContainer.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: textfieldContainer.topAnchor),
            textField.bottomAnchor.constraint(equalTo: textfieldContainer.bottomAnchor),
            textField.centerXAnchor.constraint(equalTo: textfieldContainer.centerXAnchor),
            textField.leadingAnchor.constraint(equalTo: textfieldContainer.leadingAnchor, constant: 31),
            textField.leadingAnchor.constraint(equalTo: textfieldContainer.trailingAnchor, constant: -31),
        ])

        return textfieldContainer
    }
}

extension TextFieldDescription: UITextFieldDelegate {
    @objc
    func confirmButtonTapped(_: AnyObject) {
        guard let textField, acceptsInput else { return }
        submitValue(with: textField.input)
    }

    @objc
    func editingChanged(sender: ValidatedTextField) {
        // If we use deferred validation, remove the error when the text changes
        guard useDeferredValidation else { return }
        valueValidated?(nil)
    }

    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        guard !acceptInvalidInput else { return acceptsInput }

        let editedText = (textField.text as NSString?)?.replacingCharacters(in: range, with: string)

        if let textField = self.textField, let editedText {
            validationError = textField.validateText(text: editedText)
            return validationError == nil || validationError == .tooShort(kind: kind)
        } else {
            return acceptsInput
        }
    }

    func textFieldShouldReturn(_: UITextField) -> Bool {
        guard let textField, acceptsInput else { return false }

        textField.validateInput()

        if validationError == .none || useDeferredValidation {
            submitValue(with: textField.input)
            return true
        } else {
            return false
        }
    }

    func submitValue(with text: String) {
        if let error = validationError {
            valueValidated?(.error(error, showVisualFeedback: textField?.input.isEmpty == false))
        } else {
            valueValidated?(nil)
            valueSubmitted?(text)
        }
    }
}

extension TextFieldDescription: TextFieldValidationDelegate {
    func validationUpdated(sender: UITextField, error: TextFieldValidator.ValidationError?) {
        validationError = error
    }
}
