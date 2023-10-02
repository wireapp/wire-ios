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

import UIKit
import WireCommonComponents

class CreatePasswordSecuredLinkViewController: UIViewController,
                                               CreatePasswordSecuredLinkViewModelDelegate,
                                               VerifiedTextfieldDelegate {

    // MARK: - Properties

    typealias ViewColors = SemanticColors.View
    typealias LabelColors = SemanticColors.Label
    typealias SecuredGuestLinkWithPasswordLocale = L10n.Localizable.SecuredGuestLinkWithPassword

    private var viewModel = CreatePasswordSecuredLinkViewModel()

    private let warningLabel: UILabel = {
        var paragraphStyle = NSMutableParagraphStyle()
        var label = UILabel()
        label.textColor = SemanticColors.Label.textDefault
        label.font = FontSpec.mediumFont.font!
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        paragraphStyle.lineHeightMultiple = 0.98
        label.attributedText = NSMutableAttributedString(
            string: SecuredGuestLinkWithPasswordLocale.WarningLabel.title,
            attributes: [
                NSAttributedString.Key.paragraphStyle: paragraphStyle
            ]).semiBold(
                SecuredGuestLinkWithPasswordLocale.WarningLabel.subtitle,
                font: FontSpec.mediumSemiboldFont.font!
            )

        return label
    }()

    private let generatePasswordButton = SecondaryTextButton(fontSpec: FontSpec.buttonSmallSemibold,
                                                             insets: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))

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

        textField.showConfirmButton = false
        textField.placeholder = SecuredGuestLinkWithPasswordLocale.Textfield.placeholder

        // textField.delegate = self
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
        setupGeneratePasswordButton()
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

    private func setupGeneratePasswordButton() {
        generatePasswordButton.setTitle("Generate Password", for: .normal)
        generatePasswordButton.setImage(UIImage(named: "Shield"), for: .normal)
        generatePasswordButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        generatePasswordButton.imageEdgeInsets.right = 10.0
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
            securedGuestLinkPasswordValidatedTextField.topAnchor.constraint(equalTo: confirmPasswordLabel.bottomAnchor, constant: 2),
            securedGuestLinkPasswordValidatedTextField.safeLeadingAnchor.constraint(equalTo: self.view.safeLeadingAnchor, constant: 16),
            securedGuestLinkPasswordValidatedTextField.safeTrailingAnchor.constraint(equalTo: self.view.safeTrailingAnchor, constant: -16)
        ])

    }

    // MARK: - Button Actions

    @objc
    func buttonTapped() {
        viewModel.requestRandomPassword()
    }

    // MARK: - CreatePasswordSecuredLinkViewModelDelegate

    func generateButtonDidTap(_ password: String) {
        print("Generated Password: \(password)")
        securedGuestLinkPasswordTextfield.text = password
        securedGuestLinkPasswordValidatedTextField.text = password
    }

}

extension CreatePasswordSecuredLinkViewController: UITextFieldDelegate {

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
