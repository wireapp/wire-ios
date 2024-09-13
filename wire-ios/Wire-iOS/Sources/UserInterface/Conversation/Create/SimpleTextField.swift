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
import WireDesign

protocol SimpleTextFieldDelegate: AnyObject {
    func textField(_ textField: SimpleTextField, valueChanged value: SimpleTextField.Value)
    func textFieldReturnPressed(_ textField: SimpleTextField)
    func textFieldDidEndEditing(_ textField: SimpleTextField)
    func textFieldDidBeginEditing(_ textField: SimpleTextField)
}

final class SimpleTextField: UITextField, DynamicTypeCapable {
    // MARK: - Properties

    var attribute: [NSAttributedString.Key: Any] = [
        .foregroundColor: SemanticColors.SearchBar.textInputViewPlaceholder,
        .font: FontSpec.smallRegularFont.font!,
    ]
    enum Value {
        case valid(String)
        case error(SimpleTextFieldValidator.ValidationError)
    }

    fileprivate let textFieldValidator = SimpleTextFieldValidator()

    weak var textFieldDelegate: SimpleTextFieldDelegate?

    var value: Value? {
        let validator = SimpleTextFieldValidator()
        guard let text else { return nil }
        return if let error = validator.validate(text: text) {
            .error(error)
        } else {
            .valid(text)
        }
    }

    // MARK: - UI constants

    var textInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 8)
    var placeholderInsets: UIEdgeInsets

    // MARK: Initialization

    /// Init with kind for keyboard style and validator type. Default is .unknown
    ///
    /// - Parameter kind: the type of text field
    init() {
        let leftInset: CGFloat = 8

        let topInset: CGFloat = 0
        self.placeholderInsets = UIEdgeInsets(top: topInset, left: leftInset, bottom: 0, right: 16)

        super.init(frame: .zero)

        setupTextFieldProperties()

        tintColor = .accent()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private methods

    private func setupTextFieldProperties() {
        returnKeyType = .next
        autocapitalizationType = .words
        accessibilityIdentifier = "NameField"
        autocorrectionType = .no
        contentVerticalAlignment = .center
        font = ValidatedTextField.enteredTextFont.font
        delegate = textFieldValidator
        textFieldValidator.delegate = self

        keyboardAppearance = .default
        textColor = SemanticColors.SearchBar.textInputView
        backgroundColor = SemanticColors.SearchBar.backgroundInputView
    }

    // MARK: - Methods

    func redrawFont() {
        font = ValidatedTextField.enteredTextFont.font
        attribute[.font] = FontSpec.smallRegularFont.font
    }

    // MARK: - Override methods

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        let textRect = super.textRect(forBounds: bounds)

        return textRect.inset(by: textInsets)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        let editingRect: CGRect = super.editingRect(forBounds: bounds)
        return editingRect.inset(by: textInsets)
    }

    // MARK: - Placeholder

    func attributedPlaceholderString(placeholder: String) -> NSAttributedString {
        placeholder && attribute
    }

    func updatePlaceholderAttributedText(attributes: [NSAttributedString.Key: Any]) {
        attributedPlaceholder = NSAttributedString(string: placeholder ?? "", attributes: attributes)
    }

    override var placeholder: String? {
        get {
            super.placeholder
        }

        set {
            if let newValue {
                attributedPlaceholder = attributedPlaceholderString(placeholder: newValue)
            }
        }
    }

    override var accessibilityValue: String? {
        get {
            guard let text,
                  !text.isEmpty else {
                return super.accessibilityValue ?? placeholder
            }
            return text
        }

        set {
            super.accessibilityValue = newValue
        }
    }

    override func drawPlaceholder(in rect: CGRect) {
        super.drawPlaceholder(in: rect.inset(by: placeholderInsets))
    }
}

// MARK: SimpleTextField Extension

extension SimpleTextField: SimpleTextFieldValidatorDelegate {
    func textFieldValueChanged(_ text: String?) {
        let validator = SimpleTextFieldValidator()
        let newValue = { () -> SimpleTextField.Value in
            guard let text else { return .error(.empty) }
            if let error = validator.validate(text: text) {
                return .error(error)
            } else {
                return .valid(text)
            }
        }()
        textFieldDelegate?.textField(self, valueChanged: newValue)
    }

    func textFieldValueSubmitted(_: String) {
        textFieldDelegate?.textFieldReturnPressed(self)
    }

    func textFieldDidEndEditing() {
        textFieldDelegate?.textFieldDidEndEditing(self)
    }

    func textFieldDidBeginEditing() {
        textFieldDelegate?.textFieldDidBeginEditing(self)
    }
}
