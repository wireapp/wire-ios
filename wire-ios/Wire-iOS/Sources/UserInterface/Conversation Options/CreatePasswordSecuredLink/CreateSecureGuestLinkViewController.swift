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

    private var viewModel = CreateSecureGuestLinkViewModel()

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

    lazy var securedGuestLinkPasswordTextfield: ValidatedTextField = {
        let textField = ValidatedTextField(
            kind: .password(isNew: false),
            leftInset: 8,
            accessoryTrailingInset: 0,
            cornerRadius: 12,
            setNewColors: true,
            style: .default
        )
        textField.addRevealButton(delegate: self)
        textField.placeholder = SecuredGuestLinkWithPasswordLocale.Textfield.placeholder
        textField.delegate = self
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
        label.textAlignment = .left
        return label
    }()

    lazy var securedGuestLinkPasswordValidatedTextField: ValidatedTextField = {
        let textField = ValidatedTextField(
            kind: .password(isNew: false),
            leftInset: 8,
            accessoryTrailingInset: 0,
            cornerRadius: 12,
            setNewColors: true,
            style: .default
        )

        textField.showConfirmButton = false
        textField.addRevealButton(delegate: self)
        textField.placeholder = SecuredGuestLinkWithPasswordLocale.VerifyPasswordTextField.placeholder
        textField.delegate = self
        textField.addDoneButtonOnKeyboard()
        textField.returnKeyType = .done

        return textField
    }()

    // MARK: - Override methods

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.delegate = self
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

            securedGuestLinkPasswordTextfield.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            securedGuestLinkPasswordTextfield.topAnchor.constraint(equalTo: generatePasswordButton.bottomAnchor, constant: 50),
            securedGuestLinkPasswordTextfield.safeLeadingAnchor.constraint(equalTo: self.view.safeLeadingAnchor, constant: 16),
            securedGuestLinkPasswordTextfield.safeTrailingAnchor.constraint(equalTo: self.view.safeTrailingAnchor, constant: -16),

            passwordRequirementsLabel.topAnchor.constraint(equalTo: securedGuestLinkPasswordTextfield.bottomAnchor, constant: 8),
            passwordRequirementsLabel.safeLeadingAnchor.constraint(equalTo: securedGuestLinkPasswordTextfield.safeLeadingAnchor),
            passwordRequirementsLabel.safeTrailingAnchor.constraint(equalTo: securedGuestLinkPasswordTextfield.safeTrailingAnchor),

            confirmPasswordLabel.topAnchor.constraint(equalTo: passwordRequirementsLabel.bottomAnchor, constant: 16),
            confirmPasswordLabel.safeLeadingAnchor.constraint(equalTo: passwordRequirementsLabel.safeLeadingAnchor),
            confirmPasswordLabel.safeTrailingAnchor.constraint(equalTo: passwordRequirementsLabel.safeTrailingAnchor),

            securedGuestLinkPasswordValidatedTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
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

// MARK: - UITextFieldDelegate

extension CreateSecureGuestLinkViewController: UITextFieldDelegate {

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {

        if textField == securedGuestLinkPasswordTextfield {
            return viewModel.validatePassword(textfield: textField, with: string)
        } else if textField == securedGuestLinkPasswordValidatedTextField {
            let updatedString = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) ?? string
            return updatedString == securedGuestLinkPasswordTextfield.text
        }

        return true
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
 g
