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
import WireReusableUIComponents

// MARK: - TextFieldValidationDelegate

protocol TextFieldValidationDelegate: AnyObject {
    /// Delegate for validation. It is called when every time .editingChanged event fires
    ///
    /// - Parameters:
    ///   - sender: the sender is the textfield needs to validate
    ///   - error: An error object that indicates why the request failed, or nil if the request was successful.
    func validationUpdated(sender: UITextField, error: TextFieldValidator.ValidationError?)
}

// MARK: - ValidatedTextFieldDelegate

protocol ValidatedTextFieldDelegate: AnyObject {
    func buttonPressed(_ sender: UIButton)
}

// MARK: - ValidatedTextField

final class ValidatedTextField: AccessoryTextField, TextContainer {
    enum Kind: Equatable {
        case email
        case name(isTeam: Bool)
        case password(PasswordRuleSet, isNew: Bool)
        case passcode(PasswordRuleSet, isNew: Bool)
        case username
        case unknown
    }

    let textFieldValidator: TextFieldValidator
    weak var textFieldValidationDelegate: TextFieldValidationDelegate?
    weak var validatedTextFieldDelegate: ValidatedTextFieldDelegate?

    override var text: String? {
        didSet {
            validateInput()
        }
    }

    // MARK: - UI constants

    static let enteredTextFont = FontSpec(.normal, .regular, .inputText)
    static let placeholderFont = FontSpec(.small, .regular)
    static let ConfirmButtonWidth: CGFloat = 32

    typealias TextFieldColors = SemanticColors.SearchBar

    private var style: TextFieldStyle?

    private var isEditingTextField = false {
        didSet {
            guard let style else {
                return
            }
            layer.borderColor = isEditingTextField
                ? style.borderColorSelected.resolvedColor(with: traitCollection).cgColor
                : style.borderColorNotSelected.cgColor
        }
    }

    var isLoading = false {
        didSet {
            updateLoadingState()
        }
    }

    var kind: Kind {
        didSet {
            setupTextFieldProperties()
        }
    }

    var overrideButtonIcon: StyleKitIcon? {
        didSet {
            updateButtonIcon()
        }
    }

    /// Whether to display the confirm button.
    var showConfirmButton = true {
        didSet {
            confirmButton.isHidden = !showConfirmButton
        }
    }

    var enableConfirmButton: (() -> Bool)?

    lazy var confirmButton: IconButton = {
        let iconButton: IconButton
        switch kind {
        case .passcode, .password:
            iconButton = IconButton(style: .default, variant: .light)
            iconButton.accessibilityIdentifier = "RevealButton"
            iconButton.accessibilityLabel = "Reveal passcode"
            iconButton.isEnabled = true

        default:
            iconButton = IconButton(style: .circular, variant: .dark)
            iconButton.accessibilityIdentifier = "ConfirmButton"
            iconButton.accessibilityLabel = L10n.Localizable.General.next
            iconButton.isEnabled = false
        }
        return iconButton
    }()

    let accessoryContainer = UIView()

    /// Init with kind for keyboard style and validator type. Default is .unknown
    /// - Parameters:
    ///   - kind: the type of text field
    ///   - leftInset: placeholder left inset
    ///   - cornerRadius: optional corner radius override
    init(
        kind: Kind = .unknown,
        leftInset: CGFloat = 8,
        accessoryTrailingInset: CGFloat = 16,
        cornerRadius: CGFloat? = nil,
        setNewColors: Bool = false,
        style: TextFieldStyle
    ) {
        self.textFieldValidator = TextFieldValidator()
        self.kind = kind

        var textFieldAttributes: Attributes = if setNewColors == false {
            AccessoryTextField.Attributes(
                textFont: ValidatedTextField.enteredTextFont,
                textColor: UIColor.Team.textColor,
                placeholderFont: ValidatedTextField.placeholderFont,
                placeholderColor: UIColor.Team.placeholderColor,
                backgroundColor: UIColor.Team.textfieldColor,
                cornerRadius: cornerRadius ?? 0
            )
        } else {
            AccessoryTextField.Attributes(
                textFont: ValidatedTextField.enteredTextFont,
                textColor: TextFieldColors.textInputView,
                placeholderFont: ValidatedTextField.placeholderFont,
                placeholderColor: TextFieldColors.textInputViewPlaceholder,
                backgroundColor: TextFieldColors.backgroundInputView,
                cornerRadius: cornerRadius ?? 0
            )
        }

        super.init(
            leftInset: leftInset,
            accessoryTrailingInset: accessoryTrailingInset,
            textFieldAttributes: textFieldAttributes
        )
        setupTextFieldProperties()

        setup()
        setupTextFieldProperties()
        updateButtonIcon()
        self.style = style
        applyStyle(style)
        configureObservers()
    }

    private func configureObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textViewDidBeginEditing(_:)),
            name: UITextField.textDidBeginEditingNotification,
            object: self
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textViewDidEndEditing(_:)),
            name: UITextField.textDidEndEditingNotification,
            object: self
        )
    }

    @objc
    func textViewDidBeginEditing(_: Notification?) {
        isEditingTextField = true
    }

    @objc
    func textViewDidEndEditing(_: Notification?) {
        isEditingTextField = false
    }

    private func setupTextFieldProperties() {
        returnKeyType = .next

        switch kind {
        case .email:
            keyboardType = .emailAddress
            autocorrectionType = .no
            autocapitalizationType = .none
            accessibilityIdentifier = "EmailField"
            textContentType = .emailAddress

        case let .password(rules, isNew):
            isSecureTextEntry = true
            accessibilityIdentifier = "PasswordField"
            autocapitalizationType = .none
            textContentType = isNew ? .newPassword : .password
            passwordRules = rules.textInputPasswordRules

        case let .name(isTeam):
            autocapitalizationType = .words
            accessibilityIdentifier = "NameField"
            textContentType = isTeam ? .organizationName : .name

        case .username:
            autocapitalizationType = .none
            accessibilityIdentifier = "UsernameField"
            textContentType = .username

        case .unknown:
            keyboardType = .asciiCapable
            textContentType = nil

        case let .passcode(rules, isNew):
            keyboardType = .asciiCapable
            isSecureTextEntry = true
            accessibilityIdentifier = "PasscodeField"
            autocapitalizationType = .none
            returnKeyType = isNew ? .default : .continue
            // Hack: disable auto fill passcode
            textContentType = .oneTimeCode
            passwordRules = rules.textInputPasswordRules
        }
    }

    private func updateLoadingState() {
        updateButtonIcon()
        let animationKey = "rotation_animation"
        if isLoading {
            let animation = ProgressIndicatorRotationAnimation(rotationSpeed: 1.4, beginTime: 0)
            confirmButton.layer.add(animation, forKey: animationKey)
        } else {
            confirmButton.layer.removeAnimation(forKey: animationKey)
        }
    }

    private var buttonIcon: StyleKitIcon {
        isLoading
            ? .spinner
            : overrideButtonIcon ?? (UIApplication.isLeftToRightLayout ? .forwardArrow : .backArrow)
    }

    private var iconSize: StyleKitIcon.Size {
        isLoading ? .medium : .tiny
    }

    private func updateButtonIcon() {
        confirmButton.setIcon(buttonIcon, size: iconSize, for: .normal)

        if isLoading {
            confirmButton.setIconColor(UIColor.Team.inactiveButtonColor, for: .normal)
            confirmButton.setBackgroundImageColor(.clear, for: .normal)
            confirmButton.setBackgroundImageColor(.clear, for: .disabled)
        } else {
            switch kind {
            case .passcode, .password:
                confirmButton.setIconColor(UIColor.Team.textColor, for: .normal)
                confirmButton.setIconColor(UIColor.Team.textColor, for: .disabled)
                confirmButton.setBackgroundImageColor(.clear, for: .normal)
                confirmButton.setBackgroundImageColor(.clear, for: .disabled)

            default:
                confirmButton.setIconColor(UIColor.Team.textfieldColor, for: .normal)
                confirmButton.setIconColor(UIColor.Team.textfieldColor, for: .disabled)
                confirmButton.setBackgroundImageColor(UIColor.Team.activeButtonColor, for: .normal)
                confirmButton.setBackgroundImageColor(UIColor.Team.inactiveButtonColor, for: .disabled)
            }
        }

        confirmButton.adjustsImageWhenDisabled = false
    }

    private func setup() {
        accessoryStack.addArrangedSubview(confirmButton)

        confirmButton.addTarget(self, action: #selector(confirmButtonTapped(button:)), for: .touchUpInside)
        addTarget(self, action: #selector(textFieldDidChange(textField:)), for: .editingChanged)

        NSLayoutConstraint.activate([
            confirmButton.widthAnchor.constraint(equalToConstant: ValidatedTextField.ConfirmButtonWidth),
            confirmButton.heightAnchor.constraint(equalToConstant: ValidatedTextField.ConfirmButtonWidth),
        ])
    }

    @objc
    override func textFieldDidChange(textField: UITextField) {
        updateText(input)
    }

    /// Whether the input is valid.
    var isInputValid: Bool {
        enableConfirmButton?() ?? !input.isEmpty
    }

    var isValid: Bool {
        textFieldValidator.validate(text: text, kind: kind) == nil
    }

    func updateText(_ text: String) {
        self.text = text
    }

    private func updateConfirmButton() {
        confirmButton.isEnabled = isInputValid
    }

    // MARK: - text validation

    @objc
    private func confirmButtonTapped(button: UIButton) {
        validatedTextFieldDelegate?.buttonPressed(button)
        validateInput()
    }

    func validateInput() {
        let error = textFieldValidator.validate(
            text: text,
            kind: kind
        )

        textFieldValidationDelegate?.validationUpdated(sender: self, error: error)
        updateConfirmButton()
    }

    func validateText(text: String) -> TextFieldValidator.ValidationError? {
        textFieldValidator.validate(text: text, kind: kind)
    }
}
