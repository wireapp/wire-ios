//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

import Down
import UIKit
import WireCommonComponents

class CreateSecureGuestLinkViewController: UIViewController, CreatePasswordSecuredLinkViewModelDelegate {

    // MARK: - Properties

    typealias ViewColors = SemanticColors.View
    typealias LabelColors = SemanticColors.Label
    typealias SecuredGuestLinkWithPasswordLocale = L10n.Localizable.SecuredGuestLinkWithPassword
    typealias SecureGuestLinkAccessibilityLocale = L10n.Accessibility.CreateSecureGuestLink

    weak var delegate: ValidatedTextFieldDelegate?

    private lazy var viewModel: CreateSecureGuestLinkViewModel = {
        CreateSecureGuestLinkViewModel(delegate: self)
    }()

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()

    private let contentView: UIView = {
        let view = UIView()
        return view
    }()

    private let warningLabel: UILabel = {
        var label = UILabel()
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.attributedText = .markdown(from: SecuredGuestLinkWithPasswordLocale.WarningLabel.title, style: .warningLabelStyle)
        return label
    }()

    private lazy var generatePasswordButton: SecondaryTextButton = {
        let button = SecondaryTextButton(
            fontSpec: FontSpec.buttonSmallSemibold,
            insets: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        )

        button.accessibilityLabel = SecureGuestLinkAccessibilityLocale.GeneratePasswordButton.description
        button.accessibilityHint = SecureGuestLinkAccessibilityLocale.GeneratePasswordButton.hint
        button.accessibilityTraits = [.button]

        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.setTitle(SecuredGuestLinkWithPasswordLocale.GeneratePasswordButton.title, for: .normal)
        button.setImage(Asset.Images.shield.image, for: .normal)
        button.addTarget(self, action: #selector(generatePasswordButtonTapped), for: .touchUpInside)
        button.imageEdgeInsets.right = 10.0
        return button
    }()

    private let setPasswordLabel: DynamicFontLabel = {
        let label = DynamicFontLabel(
            text: SecuredGuestLinkWithPasswordLocale.Textfield.header,
            fontSpec: .subheadlineFont,
            color: SemanticColors.Label.textFieldFloatingLabel
        )
        label.isAccessibilityElement = false
        label.textAlignment = .left
        return label
    }()

    private lazy var securedGuestLinkPasswordTextfield: ValidatedTextField = {
        let textField = ValidatedTextField(
            kind: .password(.guestLinkPassword, isNew: true),
            leftInset: 8,
            accessoryTrailingInset: 0,
            cornerRadius: 12,
            setNewColors: true,
            style: .default
        )
        textField.addRevealButton(delegate: self)

        textField.accessibilityLabel = SecureGuestLinkAccessibilityLocale.SecuredGuestLinkPasswordTextfield.description
        textField.accessibilityHint = SecureGuestLinkAccessibilityLocale.SecuredGuestLinkPasswordTextfield.hint

        textField.addTarget(self, action: #selector(handlePasswordValidation(for:)), for: .editingChanged)
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

        textField.placeholder = SecuredGuestLinkWithPasswordLocale.Textfield.placeholder
        textField.addDoneButtonOnKeyboard()
        return textField
    }()

    private let passwordRequirementsLabel: DynamicFontLabel = {
        let label = DynamicFontLabel(
            text: SecuredGuestLinkWithPasswordLocale.Textfield.footer,
            fontSpec: .mediumRegularFont,
            color: SemanticColors.Label.textFieldFloatingLabel
        )
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()

    private let confirmPasswordLabel: DynamicFontLabel = {
        let label = DynamicFontLabel(
            text: SecuredGuestLinkWithPasswordLocale.VerifyPasswordTextField.header,
            fontSpec: .subheadlineFont,
            color: SemanticColors.Label.textFieldFloatingLabel
        )
        label.isAccessibilityElement = false
        label.textAlignment = .left
        return label
    }()

    private lazy var securedGuestLinkPasswordValidatedTextField: ValidatedTextField = {
        let textField = ValidatedTextField(
            kind: .password(.guestLinkPassword, isNew: true),
            leftInset: 8,
            accessoryTrailingInset: 0,
            cornerRadius: 12,
            setNewColors: true,
            style: .default
        )
        textField.accessibilityLabel = "Guest Link Password"
        textField.accessibilityHint = "Enter the password for the secure guest link"

        textField.showConfirmButton = false
        textField.addTarget(self, action: #selector(handlePasswordValidation(for:)), for: .editingChanged)
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        textField.addRevealButton(delegate: self)
        textField.placeholder = SecuredGuestLinkWithPasswordLocale.VerifyPasswordTextField.placeholder
        textField.addDoneButtonOnKeyboard()
        textField.returnKeyType = .done

        return textField
    }()

    private lazy var createSecuredLinkButton: Button = {
        let button = Button(
            style: .primaryTextButtonStyle,
            cornerRadius: 16,
            fontSpec: .buttonBigSemibold
        )
        button.setTitle(SecuredGuestLinkWithPasswordLocale.CreateLinkButton.title, for: .normal)
        button.addTarget(self, action: #selector(createSecuredLinkButtonTapped), for: .touchUpInside)
        button.titleLabel?.numberOfLines = 0
        return button
    }()

    private var createSecureGuestLinkPasswordValidatorHelper = CreateSecureGuestLinkPasswordValidatorHelper()

    // MARK: - Override methods

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
        setupConstraints()
        textFieldDidChange(securedGuestLinkPasswordTextfield)

        contentView.accessibilityElements = [
            warningLabel,
            generatePasswordButton,
            securedGuestLinkPasswordTextfield,
            passwordRequirementsLabel,
            securedGuestLinkPasswordValidatedTextField,
            createSecuredLinkButton
        ]

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBar()
    }

    // MARK: - Setup UI

    private func setUpViews() {
        contentView.addSubview(warningLabel)
        contentView.addSubview(generatePasswordButton)
        contentView.addSubview(setPasswordLabel)
        contentView.addSubview(securedGuestLinkPasswordTextfield)
        contentView.addSubview(passwordRequirementsLabel)
        contentView.addSubview(confirmPasswordLabel)
        contentView.addSubview(securedGuestLinkPasswordValidatedTextField)
        contentView.addSubview(createSecuredLinkButton)

        scrollView.addSubview(contentView)

        view.addSubview(scrollView)
    }

    private func setupNavigationBar() {
        navigationController?.navigationBar.backgroundColor = ViewColors.backgroundDefault
        navigationController?.navigationBar.tintColor = LabelColors.textDefault
        navigationItem.setupNavigationBarTitle(title: SecuredGuestLinkWithPasswordLocale.Header.title)
        navigationItem.rightBarButtonItem = navigationController?.closeItem()
    }

    private func setupConstraints() {
        [warningLabel,
         generatePasswordButton,
         setPasswordLabel,
         securedGuestLinkPasswordTextfield,
         passwordRequirementsLabel,
         confirmPasswordLabel,
         securedGuestLinkPasswordValidatedTextField,
         createSecuredLinkButton,
         contentView,
         scrollView].prepareForLayout()
        let heightConstraint = contentView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.heightAnchor)
        heightConstraint.priority = UILayoutPriority.defaultLow

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            heightConstraint,

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.safeLeadingAnchor.constraint(equalTo: scrollView.safeLeadingAnchor),
            contentView.safeTrailingAnchor.constraint(equalTo: scrollView.safeTrailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            warningLabel.safeLeadingAnchor.constraint(equalTo: self.contentView.safeLeadingAnchor, constant: 20),
            warningLabel.safeTrailingAnchor.constraint(equalTo: self.contentView.safeTrailingAnchor, constant: -20),
            warningLabel.safeTopAnchor.constraint(equalTo: self.contentView.safeTopAnchor, constant: 30),

            generatePasswordButton.topAnchor.constraint(equalTo: warningLabel.bottomAnchor, constant: 40),
            generatePasswordButton.safeLeadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 20),
            generatePasswordButton.heightAnchor.constraint(equalToConstant: 32),

            setPasswordLabel.safeLeadingAnchor.constraint(equalTo: securedGuestLinkPasswordTextfield.safeLeadingAnchor),
            setPasswordLabel.safeTrailingAnchor.constraint(equalTo: securedGuestLinkPasswordTextfield.safeTrailingAnchor),
            setPasswordLabel.bottomAnchor.constraint(equalTo: securedGuestLinkPasswordTextfield.topAnchor, constant: -6),

            securedGuestLinkPasswordTextfield.topAnchor.constraint(equalTo: generatePasswordButton.bottomAnchor, constant: 50),
            securedGuestLinkPasswordTextfield.safeLeadingAnchor.constraint(equalTo: self.contentView.safeLeadingAnchor, constant: 16),
            securedGuestLinkPasswordTextfield.safeTrailingAnchor.constraint(equalTo: self.contentView.safeTrailingAnchor, constant: -16),

            passwordRequirementsLabel.topAnchor.constraint(equalTo: securedGuestLinkPasswordTextfield.bottomAnchor, constant: 8),
            passwordRequirementsLabel.safeLeadingAnchor.constraint(equalTo: securedGuestLinkPasswordTextfield.safeLeadingAnchor),
            passwordRequirementsLabel.safeTrailingAnchor.constraint(equalTo: securedGuestLinkPasswordTextfield.safeTrailingAnchor),

            confirmPasswordLabel.topAnchor.constraint(equalTo: passwordRequirementsLabel.bottomAnchor, constant: 16),
            confirmPasswordLabel.safeLeadingAnchor.constraint(equalTo: passwordRequirementsLabel.safeLeadingAnchor),
            confirmPasswordLabel.safeTrailingAnchor.constraint(equalTo: passwordRequirementsLabel.safeTrailingAnchor),

            securedGuestLinkPasswordValidatedTextField.topAnchor.constraint(equalTo: confirmPasswordLabel.bottomAnchor, constant: 6),
            securedGuestLinkPasswordValidatedTextField.safeLeadingAnchor.constraint(equalTo: self.contentView.safeLeadingAnchor, constant: 16),
            securedGuestLinkPasswordValidatedTextField.safeTrailingAnchor.constraint(equalTo: self.contentView.safeTrailingAnchor, constant: -16),

            createSecuredLinkButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
            createSecuredLinkButton.safeLeadingAnchor.constraint(equalTo: contentView.safeLeadingAnchor, constant: 18),
            createSecuredLinkButton.safeTrailingAnchor.constraint(equalTo: contentView.safeTrailingAnchor, constant: -18),
            createSecuredLinkButton.heightAnchor.constraint(equalToConstant: 56)
        ])

    }

    // MARK: - Button Actions

    @objc
    func generatePasswordButtonTapped() {
        viewModel.requestRandomPassword()
    }

    @objc
    func createSecuredLinkButtonTapped(_ sender: UIButton) {
        if handlePasswordValidation(for: securedGuestLinkPasswordTextfield) {
            UIPasteboard.general.string = securedGuestLinkPasswordTextfield.text

            UIAlertController.presentPasswordCopiedAlert(
                on: self,
                title: SecuredGuestLinkWithPasswordLocale.AlertController.title,
                message: SecuredGuestLinkWithPasswordLocale.AlertController.message
            )
        } else {
            // TODO: [AGIS] Sync with Wolfgang on the alert with the error
        }

    }

    @objc
    func handlePasswordValidation(for textField: ValidatedTextField) -> Bool {
        let labels: [UILabel] = textField == securedGuestLinkPasswordTextfield ? [passwordRequirementsLabel, setPasswordLabel] : [confirmPasswordLabel]

        let isValid = viewModel.validatePassword(for: textField, against: securedGuestLinkPasswordTextfield)

        if isValid {
            createSecureGuestLinkPasswordValidatorHelper.resetPasswordDefaultState(for: [textField], for: labels)
        } else {
            createSecureGuestLinkPasswordValidatorHelper.displayPasswordErrorState(for: [textField], for: labels)
            announcePasswordValidationErrorForVoiceOver(for: textField)
        }

        return isValid
    }

    // MARK: - Accessibility

    func announcePasswordValidationErrorForVoiceOver(for textField: UITextField) {
        if textField == securedGuestLinkPasswordTextfield {
            UIAccessibility.post(notification: .announcement, argument: SecureGuestLinkAccessibilityLocale.SecuredGuestLinkPasswordTextfield.announcement)
        } else {
            UIAccessibility.post(notification: .announcement, argument: SecureGuestLinkAccessibilityLocale.SecuredGuestLinkPasswordValidatedTextField.announcement)
        }

    }

    // MARK: - CreatePasswordSecuredLinkViewModelDelegate

    func viewModel(
        _ viewModel: CreateSecureGuestLinkViewModel,
        didGeneratePassword password: String
    ) {
        securedGuestLinkPasswordTextfield.text = password
        securedGuestLinkPasswordValidatedTextField.text = password
    }

}

// MARK: - ValidatedTextFieldDelegate

extension CreateSecureGuestLinkViewController: ValidatedTextFieldDelegate {

    func buttonPressed(_ sender: UIButton) {
        securedGuestLinkPasswordTextfield.isSecureTextEntry.toggle()
        securedGuestLinkPasswordTextfield.updatePasscodeIcon()
        securedGuestLinkPasswordValidatedTextField.isSecureTextEntry.toggle()
        securedGuestLinkPasswordValidatedTextField.updatePasscodeIcon()
    }
}

// MARK: - UITextFieldDelegate

extension CreateSecureGuestLinkViewController: UITextFieldDelegate {

    @objc
    func textFieldDidChange(_ textField: UITextField) {
        if let text1 = securedGuestLinkPasswordTextfield.text,
           let text2 = securedGuestLinkPasswordValidatedTextField.text,
           !text1.isEmpty,
           !text2.isEmpty,
           handlePasswordValidation(for: securedGuestLinkPasswordTextfield),
           text1 == text2 {
            createSecuredLinkButton.isEnabled = true
        } else {
            createSecuredLinkButton.isEnabled = false
        }
    }

}
