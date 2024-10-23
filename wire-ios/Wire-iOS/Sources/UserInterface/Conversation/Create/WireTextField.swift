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

class WireTextField: UITextField {

    // MARK: - Properties

    enum Value {
        case valid(String)
        case error(SimpleTextFieldValidator.ValidationError)
    }

    private let borderWidth: CGFloat = 1
    private let cornerRadius: CGFloat = 12

    var defaultBorderColor: UIColor = SemanticColors.SearchBar.borderInputView
    var selectedBorderColor: UIColor = UIColor.accent()

    weak var wireTextFieldDelegate: WireTextFieldDelegate?
    private let textFieldValidator = SimpleTextFieldValidator()

    var value: Value? {
        let validator = SimpleTextFieldValidator()
        guard let text else { return nil }
        return if let error = validator.validate(text: text) {
            .error(error)
        } else {
            .valid(text)
        }
    }

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Setup

    private func setup() {
        setupAppearance()
        setupPadding()
        setupTextFieldProperties()
        setupTextFieldEvents()
    }

    private func setupAppearance() {
        layer.borderWidth = borderWidth
        layer.cornerRadius = cornerRadius
        layer.borderColor = defaultBorderColor.cgColor
        layer.masksToBounds = true
        self.backgroundColor = SemanticColors.View.backgroundDefaultWhite
    }

    private func setupPadding() {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: frame.height))
        leftView = paddingView
        leftViewMode = .always
    }

    private func setupTextFieldProperties() {
        returnKeyType = .next
        autocapitalizationType = .words
        accessibilityIdentifier = "NameField"
        clearButtonMode = .whileEditing
        autocorrectionType = .no
        contentVerticalAlignment = .center
        font = .font(for: .body1)

        textFieldValidator.delegate = self
        delegate = textFieldValidator
    }

    private func setupTextFieldEvents() {
        addTarget(self, action: #selector(textFieldDidStartEditing), for: .editingDidBegin)
        addTarget(self, action: #selector(textFieldDidFinishEditing), for: .editingDidEnd)
    }

    // MARK: - UI Updates

    @objc private func textFieldDidStartEditing() {
        layer.borderColor = selectedBorderColor.cgColor
        wireTextFieldDelegate?.textFieldDidBeginEditing(self)
    }

    @objc private func textFieldDidFinishEditing() {
        layer.borderColor = defaultBorderColor.cgColor
        wireTextFieldDelegate?.textFieldDidEndEditing(self)
    }
}

// MARK: - SimpleTextFieldValidatorDelegate

extension WireTextField: SimpleTextFieldValidatorDelegate {

    func textFieldValueChanged(_ text: String?) {
        let validator = SimpleTextFieldValidator()
        let newValue = { () -> WireTextField.Value in
            guard let text else { return .error(.empty) }
            if let error = validator.validate(text: text) {
                return .error(error)
            } else {
                return .valid(text)
            }
        }()
        wireTextFieldDelegate?.textField(self, valueChanged: newValue)
    }

    func textFieldValueSubmitted(_ value: String) {
        wireTextFieldDelegate?.textFieldReturnPressed(self)
    }

    func textFieldDidEndEditing() {
        wireTextFieldDelegate?.textFieldDidEndEditing(self)
    }

    func textFieldDidBeginEditing() {
        wireTextFieldDelegate?.textFieldDidBeginEditing(self)
    }
}
