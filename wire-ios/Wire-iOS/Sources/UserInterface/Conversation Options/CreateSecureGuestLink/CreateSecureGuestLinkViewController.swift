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

import Down
import UIKit
import WireCommonComponents
import WireDesign
import WireSyncEngine

class CreateSecureGuestLinkViewController: UIViewController, CreatePasswordSecuredLinkViewModelDelegate {

    // MARK: - Properties

    typealias ViewColors = SemanticColors.View
    typealias LabelColors = SemanticColors.Label
    typealias SecuredGuestLinkWithPasswordLocale = L10n.Localizable.SecuredGuestLinkWithPassword
    typealias SecureGuestLinkAccessibilityLocale = L10n.Accessibility.CreateSecureGuestLink

    let conversation: ZMConversation
    let conversationSecureGuestLinkUseCase: CreateConversationGuestLinkUseCaseProtocol

    private lazy var viewModel: CreateSecureConversationGuestLinkViewModel = {
        CreateSecureConversationGuestLinkViewModel(delegate: self, conversationGuestLinkUseCase: conversationSecureGuestLinkUseCase)
    }()

    // MARK: - Initializer
    init(conversationSecureGuestLinkUseCase: CreateConversationGuestLinkUseCaseProtocol, conversation: ZMConversation) {
        self.conversationSecureGuestLinkUseCase = conversationSecureGuestLinkUseCase
        self.conversation = conversation
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
        button.setImage(.init(resource: .secureGuestLinkShield), for: .normal)
        button.setIconColor(SemanticColors.Icon.foregroundDefaultBlack, for: .normal)

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
        textField.delegate = self
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
        textField.accessibilityLabel = SecureGuestLinkAccessibilityLocale.SecuredGuestLinkPasswordValidatedTextField.description
        textField.accessibilityHint = SecureGuestLinkAccessibilityLocale.SecuredGuestLinkPasswordValidatedTextField.hint

        textField.showConfirmButton = false
        textField.addTarget(self, action: #selector(handlePasswordValidation(for:)), for: .editingChanged)
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        textField.addRevealButton(delegate: self)
        textField.placeholder = SecuredGuestLinkWithPasswordLocale.VerifyPasswordTextField.placeholder
        textField.addDoneButtonOnKeyboard()
        textField.returnKeyType = .done
        textField.delegate = self
        return textField
    }()

    private lazy var createSecuredLinkButton: ZMButton = {
        let button = ZMButton(
            style: .primaryTextButtonStyle,
            cornerRadius: 16,
            fontSpec: .buttonBigSemibold
        )

        button.accessibilityLabel = SecureGuestLinkAccessibilityLocale.CreateLinkButton.description
        button.accessibilityHint = SecureGuestLinkAccessibilityLocale.CreateLinkButton.hint
        button.accessibilityTraits = [.button]

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

        // Keyboard notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(
                keyboardWillShow
            ),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(
                keyboardWillHide
            ),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBar()
    }

    // MARK: - Setup UI

    private func setUpViews() {
        let contentSubviews: [UIView] = [
            warningLabel,
            generatePasswordButton,
            setPasswordLabel,
            securedGuestLinkPasswordTextfield,
            passwordRequirementsLabel,
            confirmPasswordLabel,
            securedGuestLinkPasswordValidatedTextField,
            createSecuredLinkButton
        ]

        contentSubviews.forEach { contentView.addSubview($0) }

        scrollView.addSubview(contentView)
        view.addSubview(scrollView)
    }

    private func setupNavigationBar() {
        navigationController?.navigationBar.backgroundColor = ViewColors.backgroundDefault
        navigationController?.navigationBar.tintColor = LabelColors.textDefault
        setupNavigationBarTitle(SecuredGuestLinkWithPasswordLocale.Header.title)

        navigationItem.rightBarButtonItem = UIBarButtonItem.closeButton(action: UIAction { [weak self] _ in
            self?.presentingViewController?.dismiss(animated: true)
        }, accessibilityLabel: L10n.Accessibility.CreateSecureGuestLink.CloseButton.description)

    }

    private func setupConstraints() {
        warningLabel.translatesAutoresizingMaskIntoConstraints = false
        generatePasswordButton.translatesAutoresizingMaskIntoConstraints = false
        setPasswordLabel.translatesAutoresizingMaskIntoConstraints = false
        securedGuestLinkPasswordTextfield.translatesAutoresizingMaskIntoConstraints = false
        passwordRequirementsLabel.translatesAutoresizingMaskIntoConstraints = false
        confirmPasswordLabel.translatesAutoresizingMaskIntoConstraints = false
        securedGuestLinkPasswordValidatedTextField.translatesAutoresizingMaskIntoConstraints = false
        createSecuredLinkButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

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
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            warningLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            warningLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            warningLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 30),

            generatePasswordButton.topAnchor.constraint(equalTo: warningLabel.bottomAnchor, constant: 40),
            generatePasswordButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            generatePasswordButton.heightAnchor.constraint(equalToConstant: 32),

            setPasswordLabel.leadingAnchor.constraint(equalTo: securedGuestLinkPasswordTextfield.leadingAnchor),
            setPasswordLabel.trailingAnchor.constraint(equalTo: securedGuestLinkPasswordTextfield.trailingAnchor),
            setPasswordLabel.bottomAnchor.constraint(equalTo: securedGuestLinkPasswordTextfield.topAnchor, constant: -6),

            securedGuestLinkPasswordTextfield.topAnchor.constraint(equalTo: generatePasswordButton.bottomAnchor, constant: 50),
            securedGuestLinkPasswordTextfield.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            securedGuestLinkPasswordTextfield.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            passwordRequirementsLabel.topAnchor.constraint(equalTo: securedGuestLinkPasswordTextfield.bottomAnchor, constant: 8),
            passwordRequirementsLabel.leadingAnchor.constraint(equalTo: securedGuestLinkPasswordTextfield.leadingAnchor),
            passwordRequirementsLabel.trailingAnchor.constraint(equalTo: securedGuestLinkPasswordTextfield.trailingAnchor),

            confirmPasswordLabel.topAnchor.constraint(equalTo: passwordRequirementsLabel.bottomAnchor, constant: 16),
            confirmPasswordLabel.leadingAnchor.constraint(equalTo: passwordRequirementsLabel.leadingAnchor),
            confirmPasswordLabel.trailingAnchor.constraint(equalTo: passwordRequirementsLabel.trailingAnchor),

            securedGuestLinkPasswordValidatedTextField.topAnchor.constraint(equalTo: confirmPasswordLabel.bottomAnchor, constant: 6),
            securedGuestLinkPasswordValidatedTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            securedGuestLinkPasswordValidatedTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            createSecuredLinkButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
            createSecuredLinkButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
            createSecuredLinkButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -18),
            createSecuredLinkButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    // MARK: - Button Actions

    @objc
    func generatePasswordButtonTapped() {
        viewModel.requestRandomPassword()
        textFieldDidChange(securedGuestLinkPasswordTextfield)
    }

    @objc
    func createSecuredLinkButtonTapped(_ sender: UIButton) {
        viewModel.createSecuredGuestLinkIfValid(
            conversation: conversation,
            passwordField: securedGuestLinkPasswordTextfield,
            confirmPasswordField: securedGuestLinkPasswordValidatedTextField
        )
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

    func announcePasswordValidationErrorForVoiceOver(for textField: ValidatedTextField) {
        let argument = textField == securedGuestLinkPasswordTextfield ? SecureGuestLinkAccessibilityLocale.SecuredGuestLinkPasswordTextfield.announcement : SecureGuestLinkAccessibilityLocale.SecuredGuestLinkPasswordValidatedTextField.announcement

        UIAccessibility.post(
            notification: .announcement,
            argument: argument
        )
    }

    // MARK: - Keyboard Handling

    @objc
    private func keyboardWillShow(notification: NSNotification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardFrame.height, right: 0)
            scrollView.contentInset = contentInsets
            scrollView.scrollIndicatorInsets = contentInsets
        }
    }

    @objc
    private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }

    // MARK: - CreatePasswordSecuredLinkViewModelDelegate

    func viewModel(
        _ viewModel: CreateSecureConversationGuestLinkViewModel,
        didGeneratePassword password: String
    ) {
        securedGuestLinkPasswordTextfield.text = password
        securedGuestLinkPasswordValidatedTextField.text = password
    }

    func viewModelDidValidatePasswordSuccessfully(_ viewModel: CreateSecureConversationGuestLinkViewModel) {

        UIAlertController.presentPasswordCopiedAlert(
            on: self,
            title: SecuredGuestLinkWithPasswordLocale.AlertController.title,
            message: SecuredGuestLinkWithPasswordLocale.AlertController.message
        )

    }

    func viewModel(_ viewModel: CreateSecureConversationGuestLinkViewModel, didFailToValidatePasswordWithReason reason: String) {

    }

    func viewModel(_ viewModel: CreateSecureConversationGuestLinkViewModel, didCreateLink link: String) {
        print("Link created successfully: \(link)")
    }

    func viewModel(_ viewModel: CreateSecureConversationGuestLinkViewModel, didFailToCreateLinkWithError error: Error) {
        print("Failed to create link: \(error.localizedDescription)")
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
        evaluateTextfieldsAndToggleCreateLinkButtonState()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === securedGuestLinkPasswordTextfield {
            // Move focus to the password confirmation text field
            securedGuestLinkPasswordValidatedTextField.becomeFirstResponder()
        } else {
            // Dismiss keyboard and finalize
            textField.resignFirstResponder()
            evaluateTextfieldsAndToggleCreateLinkButtonState()
        }

        return true
    }

    private func evaluateTextfieldsAndToggleCreateLinkButtonState() {
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
