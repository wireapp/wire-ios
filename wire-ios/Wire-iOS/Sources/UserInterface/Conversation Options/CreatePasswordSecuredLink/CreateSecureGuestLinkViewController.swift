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

    weak var delegate: ValidatedTextFieldDelegate?

    private lazy var viewModel: CreateSecureGuestLinkViewModel = {
        CreateSecureGuestLinkViewModel(delegate: self)
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

        textField.placeholder = SecuredGuestLinkWithPasswordLocale.Textfield.placeholder
        textField.addDoneButtonOnKeyboard()
        textField.textFieldValidationDelegate = self
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
        textField.textFieldValidator.customValidator = { [weak self] in
            guard $0 == self?.securedGuestLinkPasswordTextfield.text else {
                return .custom("passwords don't match")
            }

            return nil
        }
        textField.showConfirmButton = false
        textField.addRevealButton(delegate: self)
        textField.placeholder = SecuredGuestLinkWithPasswordLocale.VerifyPasswordTextField.placeholder
        textField.addDoneButtonOnKeyboard()
        textField.returnKeyType = .done
        textField.textFieldValidationDelegate = self

        return textField
    }()

    private let validationErrorTextColor = LabelColors.textErrorDefault
    private let defaultLabelColor = LabelColors.textFieldFloatingLabel

    // MARK: - Override methods

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
        setupConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBar()
    }

    // MARK: - Setup UI

    private func setUpViews() {
        view.addSubview(warningLabel)
        view.addSubview(generatePasswordButton)
        view.addSubview(setPasswordLabel)
        view.addSubview(securedGuestLinkPasswordTextfield)
        view.addSubview(passwordRequirementsLabel)
        view.addSubview(confirmPasswordLabel)
        view.addSubview(securedGuestLinkPasswordValidatedTextField)
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
         securedGuestLinkPasswordValidatedTextField].prepareForLayout()

        NSLayoutConstraint.activate([
            warningLabel.safeLeadingAnchor.constraint(equalTo: self.view.safeLeadingAnchor, constant: 20),
            warningLabel.safeTrailingAnchor.constraint(equalTo: self.view.safeTrailingAnchor, constant: -20),
            warningLabel.safeTopAnchor.constraint(equalTo: self.view.safeTopAnchor, constant: 30),

            generatePasswordButton.topAnchor.constraint(equalTo: warningLabel.bottomAnchor, constant: 40),
            generatePasswordButton.safeLeadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20),
            // This is a temporary constraint for the height.
            // It will change as soon as we add more elements to the View Controller
            generatePasswordButton.heightAnchor.constraint(equalToConstant: 32),

            setPasswordLabel.safeLeadingAnchor.constraint(equalTo: securedGuestLinkPasswordTextfield.safeLeadingAnchor),
            setPasswordLabel.safeTrailingAnchor.constraint(equalTo: securedGuestLinkPasswordTextfield.safeTrailingAnchor),
            setPasswordLabel.bottomAnchor.constraint(equalTo: securedGuestLinkPasswordTextfield.topAnchor, constant: -6),

            securedGuestLinkPasswordTextfield.topAnchor.constraint(equalTo: generatePasswordButton.bottomAnchor, constant: 50),
            securedGuestLinkPasswordTextfield.safeLeadingAnchor.constraint(equalTo: self.view.safeLeadingAnchor, constant: 16),
            securedGuestLinkPasswordTextfield.safeTrailingAnchor.constraint(equalTo: self.view.safeTrailingAnchor, constant: -16),

            passwordRequirementsLabel.topAnchor.constraint(equalTo: securedGuestLinkPasswordTextfield.bottomAnchor, constant: 8),
            passwordRequirementsLabel.safeLeadingAnchor.constraint(equalTo: securedGuestLinkPasswordTextfield.safeLeadingAnchor),
            passwordRequirementsLabel.safeTrailingAnchor.constraint(equalTo: securedGuestLinkPasswordTextfield.safeTrailingAnchor),

            confirmPasswordLabel.topAnchor.constraint(equalTo: passwordRequirementsLabel.bottomAnchor, constant: 16),
            confirmPasswordLabel.safeLeadingAnchor.constraint(equalTo: passwordRequirementsLabel.safeLeadingAnchor),
            confirmPasswordLabel.safeTrailingAnchor.constraint(equalTo: passwordRequirementsLabel.safeTrailingAnchor),

            securedGuestLinkPasswordValidatedTextField.topAnchor.constraint(equalTo: confirmPasswordLabel.bottomAnchor, constant: 6),
            securedGuestLinkPasswordValidatedTextField.safeLeadingAnchor.constraint(equalTo: self.view.safeLeadingAnchor, constant: 16),
            securedGuestLinkPasswordValidatedTextField.safeTrailingAnchor.constraint(equalTo: self.view.safeTrailingAnchor, constant: -16)
        ])

    }

    // MARK: - Button Actions

    @objc
    func generatePasswordButtonTapped() {
        viewModel.requestRandomPassword()
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

extension CreateSecureGuestLinkViewController: TextFieldValidationDelegate {

    private func displayPasswordErrorState(to textField: UITextField, for labels: [UILabel]) {
        textField.textColor = validationErrorTextColor
        textField.layer.borderColor = validationErrorTextColor.cgColor
        labels.forEach { $0.textColor = validationErrorTextColor }
    }

    private func resetPasswordDefaultState(to textField: UITextField, for labels: [UILabel]) {
        textField.applyStyle(.default)
        labels.forEach { $0.textColor = defaultLabelColor }
    }

    func validationUpdated(sender: UITextField, error: TextFieldValidator.ValidationError?) {
        if let error = error {
            switch sender {
            case securedGuestLinkPasswordTextfield:
                displayPasswordErrorState(to: sender, for: [passwordRequirementsLabel, setPasswordLabel])

            case securedGuestLinkPasswordValidatedTextField:
                displayPasswordErrorState(to: sender, for: [confirmPasswordLabel])

            default:
                break
            }

        } else {
            switch sender {
            case securedGuestLinkPasswordTextfield:
                resetPasswordDefaultState(to: sender, for: [passwordRequirementsLabel, setPasswordLabel])

            case securedGuestLinkPasswordValidatedTextField:
                resetPasswordDefaultState(to: sender, for: [confirmPasswordLabel])

            default:
                break
            }
        }
    }
}

extension CreateSecureGuestLinkViewController: ValidatedTextFieldDelegate {

    func buttonPressed(_ sender: UIButton) {
        securedGuestLinkPasswordTextfield.isSecureTextEntry.toggle()
        securedGuestLinkPasswordTextfield.updatePasscodeIcon()
        securedGuestLinkPasswordValidatedTextField.isSecureTextEntry.toggle()
        securedGuestLinkPasswordValidatedTextField.updatePasscodeIcon()
    }
}

// MARK: - DownStyle

private extension DownStyle {

    static var warningLabelStyle: DownStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        let style = DownStyle()
        style.baseFont = .preferredFont(forTextStyle: .caption1)
        style.baseFontColor = SemanticColors.Label.textDefault
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.lineHeightMultiple = 0.98
        style.baseParagraphStyle = paragraphStyle
        return style
    }

}
