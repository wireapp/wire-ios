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
import WireDataModel
import WireDesign
import WireSystem
import WireTransport

/// The view controller to use to ask the user to enter their credentials.

final class AuthenticationCredentialsViewController: AuthenticationStepController,
    EmailPasswordTextFieldDelegate,
    TextFieldValidationDelegate,
    UITextFieldDelegate {
    typealias Registration = L10n.Localizable.Registration
    typealias TabBarStrings = L10n.Accessibility.TabBar
    weak var actioner: AuthenticationActioner?

    /// Types of flow provided by the view controller.
    enum FlowType {
        case login(AuthenticationPrefilledCredentials?)
        case registration
        case reauthentication(AuthenticationPrefilledCredentials?)
    }

    /// The type of flow presented by the view controller.
    private(set) var flowType: FlowType!

    /// The currently pre-filled credentials.
    var prefilledCredentials: AuthenticationPrefilledCredentials? {
        didSet {
            updatePrefilledCredentials()
        }
    }

    /// Whether we are in the registration flow.
    var isRegistering: Bool {
        if case .registration? = flowType {
            true
        } else {
            false
        }
    }

    var isReauthenticating: Bool {
        if case .reauthentication? = flowType {
            true
        } else {
            false
        }
    }

    override weak var authenticationCoordinator: AuthenticationCoordinator? {
        didSet {
            actioner = authenticationCoordinator
        }
    }

    var backendEnvironmentProvider: (() -> BackendEnvironmentProvider)!

    var backendEnvironment: BackendEnvironmentProvider {
        backendEnvironmentProvider()
    }

    var isProxyCredentialsRequired: Bool {
        backendEnvironment.proxy?.needsAuthentication == true
    }

    private var emailFieldValidationError: TextFieldValidator.ValidationError? = .tooShort(kind: .email)
    private var shouldUseScrollView = false
    private var loginActiveField: UIResponder? // used for login proxy case

    convenience init(
        flowType: FlowType,
        backendEnvironmentProvider: @escaping () -> BackendEnvironmentProvider = { BackendEnvironment.shared }
    ) {
        switch flowType {
        case let .login(credentials):
            let description = LogInStepDescription()
            self.init(description: description, contentCenterConstraintActivation: false)
            self.prefilledCredentials = credentials
            self.shouldUseScrollView = true
        case let .reauthentication(credentials):
            let description = ReauthenticateStepDescription(prefilledCredentials: credentials)
            self.init(description: description, contentCenterConstraintActivation: false)
            self.prefilledCredentials = credentials
            self.shouldUseScrollView = true
        case .registration:
            let description = PersonalRegistrationStepDescription()
            self.init(description: description, contentCenterConstraintActivation: true)
            self.shouldUseScrollView = false
        }

        self.backendEnvironmentProvider = backendEnvironmentProvider
        self.flowType = flowType
    }

    // MARK: - Views

    let contentStack = UIStackView()

    let emailPasswordInputField = EmailPasswordTextField()
    let emailInputField = ValidatedTextField(kind: .email, style: .default)
    let loginButton = ZMButton(
        style: .accentColorTextButtonStyle,
        cornerRadius: 16,
        fontSpec: .buttonBigSemibold
    )

    lazy var proxyCredentialsViewController = ProxyCredentialsViewController(
        backendURL: backendEnvironment.backendURL,
        textFieldDidUpdateText: { [weak self] _ in
            self?.updateLoginButtonState()
        },
        activeFieldChange: { [
            weak self
        ] textField in
            self?.loginActiveField = textField
        }
    )

    lazy var forgotPasswordButton = {
        let button = ZMButton(fontSpec: .smallLightFont)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: FontSpec.smallSemiboldFont.font!,
            .foregroundColor: SemanticColors.Button.textUnderlineEnabled,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
        ]

        let attributeString = NSMutableAttributedString(
            string: L10n.Localizable.Signin.forgotPassword.capitalized,
            attributes: attributes
        )

        button.translatesAutoresizingMaskIntoConstraints = false
        button.setAttributedTitle(attributeString, for: .normal)
        button.accessibilityLabel = L10n.Accessibility.Authentication.ForgotPasswordButton.description
        button.addTarget(self, action: #selector(forgotPasswordTapped), for: .touchUpInside)

        return button
    }()

    // MARK: - Lifecycle

    override func loadView() {
        if shouldUseScrollView {
            view = UIScrollView()
        } else {
            view = UIView()
        }
        // avoid constraint breaking on layout pass
        view.frame = UIScreen.main.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        updateCredentialsType()
        updatePrefilledCredentials()

        (view as? UIScrollView)?.keyboardDismissMode = .onDrag
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loginActiveField = contextualFirstResponder
    }

    private func setupProxyView() {
        let verticalSpacing: CGFloat = 24
        let horizontalMargin: CGFloat = 31

        let innerTopStackView = UIStackView()
        innerTopStackView.axis = .vertical
        innerTopStackView.spacing = verticalSpacing

        addCustomBackendViewIfNeeded(to: innerTopStackView, space: 66)

        innerTopStackView.addArrangedSubview(emailInputField)
        innerTopStackView.addArrangedSubview(emailPasswordInputField)
        innerTopStackView.addArrangedSubview(forgotPasswordButton)
        innerTopStackView.setCustomSpacing(40, after: forgotPasswordButton)

        let innerBottomStackView = UIStackView()
        innerBottomStackView.axis = .vertical
        innerBottomStackView.addArrangedSubview(loginButton)

        innerTopStackView.isLayoutMarginsRelativeArrangement = true
        innerTopStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 0,
            leading: horizontalMargin,
            bottom: 0,
            trailing: horizontalMargin
        )

        innerBottomStackView.isLayoutMarginsRelativeArrangement = true
        innerBottomStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: isProxyCredentialsRequired ? 40 : 0,
            leading: horizontalMargin,
            bottom: 32,
            trailing: horizontalMargin
        )

        contentStack.addArrangedSubview(innerTopStackView)
        if isProxyCredentialsRequired {
            addProxyCredentialsSection()
        }
        contentStack.addArrangedSubview(innerBottomStackView)

        contentStack.setCustomSpacing(40, after: innerTopStackView)
    }

    private func setupDefaultView() {
        let horizontalMargin: CGFloat = 31
        let emptyView = UIView()
        contentStack.spacing = 24

        addCustomBackendViewIfNeeded(to: contentStack, space: 0)

        if stepDescription.subtext == nil, shouldUseScrollView {
            contentStack.addArrangedSubview(emptyView)
            contentStack.setCustomSpacing(56, after: emptyView)
        }
        contentStack.addArrangedSubview(emailInputField)
        contentStack.addArrangedSubview(emailPasswordInputField)
        contentStack.addArrangedSubview(forgotPasswordButton)
        contentStack.addArrangedSubview(loginButton)

        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 0,
            leading: horizontalMargin,
            bottom: 0,
            trailing: horizontalMargin
        )
    }

    private func addCustomBackendViewIfNeeded(to uiStackView: UIStackView, space: CGFloat) {
        guard let infoView = customBackendInfo() else { return }
        uiStackView.addArrangedSubview(infoView)
        uiStackView.setCustomSpacing(space, after: infoView)
    }

    override func createMainView() -> UIView {
        contentStack.axis = .vertical
        contentStack.distribution = .fill

        // log in button
        loginButton.setTitle(L10n.Localizable.Landing.Login.Button.title.capitalized, for: .normal)
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        updateLoginButtonState()

        // Email Password Input View
        emailPasswordInputField.allowEditingPrefilledValue = !isReauthenticating
        emailPasswordInputField.delegate = self
        emailPasswordInputField.passwordField.addRevealButton(delegate: self)

        // Email input view
        emailInputField.delegate = self
        emailInputField.textFieldValidationDelegate = self
        emailInputField.placeholder = L10n.Localizable.Email.placeholder.capitalized
        emailInputField.addTarget(self, action: #selector(emailTextInputDidChange), for: .editingChanged)
        emailInputField.confirmButton.addTarget(self, action: #selector(emailConfirmButtonTapped), for: .touchUpInside)
        emailInputField.enableConfirmButton = { [weak self] in
            self?.emailFieldValidationError == nil
        }

        if isProxyCredentialsRequired {
            setupProxyView()
        } else {
            setupDefaultView()
        }
        return contentStack
    }

    @objc
    func loginButtonTapped(sender: UIButton) {
        guard isProxyCredentialsRequired else {
            emailPasswordInputField.confirmButtonTapped()
            return
        }

        let input: (EmailPasswordInput, AuthenticationProxyCredentialsInput?) = (
            .init(
                email: emailPasswordInputField.emailField.input,
                password: emailPasswordInputField.passwordField.input
            ),
            .init(
                username: proxyCredentialsViewController.usernameInput.input,
                password: proxyCredentialsViewController.passwordInput.input
            )
        )
        valueSubmitted(input)
    }

    @objc
    func forgotPasswordTapped(sender: UIButton) {
        actioner?.executeAction(.openURL(WireURLs.shared.passwordReset))
    }

    override func createConstraints() {
        super.createConstraints()
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loginButton.heightAnchor.constraint(equalToConstant: 48),
        ])

        if shouldUseScrollView {
            NSLayoutConstraint.activate([
                contentStack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor),
                contentStack.trailingAnchor.constraint(greaterThanOrEqualTo: view.trailingAnchor),
                contentStack.widthAnchor.constraint(equalToConstant: 375),
                contentStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                contentStack.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor, constant: 86),
            ])
        }
    }

    override func updateKeyboard(with keyboardFrame: CGRect) {
        guard let scrollView = view as? UIScrollView else {
            return super.updateKeyboard(with: keyboardFrame)
        }

        guard let activeField = loginActiveField as? UIView else {
            scrollView.contentInset.bottom = 0
            scrollView.verticalScrollIndicatorInsets.bottom = 0
            return
        }
        let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardFrame.height, right: 0.0)
        scrollView.contentInset = contentInsets
        scrollView.verticalScrollIndicatorInsets = contentInsets

        let activeRect = activeField.convert(activeField.bounds, to: scrollView)
        scrollView.scrollRectToVisible(activeRect, animated: true)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        wr_supportedInterfaceOrientations
    }

    @objc
    func customBackendInfoViewTapped(sender: UITapGestureRecognizer) {
        let intent = AuthenticationShowCustomBackendInfoHandler.Intent.showCustomBackendInfo
        authenticationCoordinator?.eventResponderChain.handleEvent(ofType: .userInput(intent))
    }

    private var contextualFirstResponder: UIResponder? {
        switch flowType {
        case .login:
            emailPasswordInputField
        case .registration:
            emailInputField
        case .reauthentication:
            emailPasswordInputField
        case .none:
            .none
        }
    }

    override func showKeyboard() {
        contextualFirstResponder?.becomeFirstResponderIfPossible()
    }

    override func dismissKeyboard() {
        contextualFirstResponder?.resignFirstResponder()
    }

    private func updateCredentialsType() {
        clearError()

        emailPasswordInputField.isHidden = isRegistering
        emailInputField.isHidden = !isRegistering
        loginButton.isHidden = isRegistering
        forgotPasswordButton.isHidden = isRegistering

        setSecondaryViewHidden(false)
    }

    private func updatePrefilledCredentials() {
        guard let prefilledCredentials else { return }
        emailPasswordInputField.prefill(email: prefilledCredentials.credentials.emailAddress)
    }

    override func clearInputFields() {
        emailInputField.text = nil
        emailPasswordInputField.emailField.text = nil
        emailPasswordInputField.passwordField.text = nil
        showKeyboard()
    }

    // MARK: - Events

    override func accessibilityPerformMagicTap() -> Bool {
        (contextualFirstResponder as? MagicTappable)?.performMagicTap() == true
    }

    @objc
    private func emailConfirmButtonTapped(sender: IconButton) {
        valueSubmitted(emailInputField.input)
    }

    @objc
    private func emailTextInputDidChange(sender: ValidatedTextField) {
        sender.validateInput()
    }

    func validationUpdated(sender: UITextField, error: TextFieldValidator.ValidationError?) {
        emailFieldValidationError = error
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard textField == emailInputField, emailInputField.isInputValid else {
            return false
        }

        valueSubmitted(emailInputField.input)
        return true
    }

    // MARK: - Email / Password Input

    func textFieldDidUpdateText(_: EmailPasswordTextField) {
        updateLoginButtonState()
    }

    func textField(_ textField: EmailPasswordTextField, didConfirmCredentials credentials: (String, String)) {
        guard !isProxyCredentialsRequired else {
            proxyCredentialsViewController.usernameInput.becomeFirstResponder()
            return
        }
        let input: (EmailPasswordInput, AuthenticationProxyCredentialsInput?) = (
            EmailPasswordInput(email: credentials.0, password: credentials.1),
            nil
        )
        valueSubmitted(input)
    }

    func textFieldDidSubmitWithValidationError(_ textField: EmailPasswordTextField) {
        guard !isProxyCredentialsRequired, !textField.isPasswordEmpty else {
            proxyCredentialsViewController.usernameInput.becomeFirstResponder()
            return
        }
        // no-op: we do not update the UI depending on the validity of the input
    }

    private func updateLoginButtonState() {
        guard isProxyCredentialsRequired else {
            loginButton.isEnabled = emailPasswordInputField.hasValidInput
            return
        }
        let validEmailPassword = emailPasswordInputField.emailValidationError == nil && emailPasswordInputField
            .passwordValidationError == nil
        let validProxyCredentials = proxyCredentialsViewController.usernameInput
            .isInputValid && proxyCredentialsViewController.passwordInput.isInputValid
        loginButton.isEnabled = validEmailPassword &&
            ((isProxyCredentialsRequired && validProxyCredentials) || !isProxyCredentialsRequired)
    }

    // MARK: - Proxy Credentials

    private func customBackendInfo() -> CustomBackendView? {
        guard let url = backendEnvironment.environmentType.customUrl else {
            return nil
        }
        let info = CustomBackendView()
        info.setBackendUrl(url)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(customBackendInfoViewTapped(sender:)))
        info.addGestureRecognizer(tapGesture)
        info.heightAnchor.constraint(equalToConstant: 30).isActive = true
        return info
    }

    private func addProxyCredentialsSection() {
        guard proxyCredentialsViewController.parent == nil else { return }
        addChild(proxyCredentialsViewController)
        contentStack.addArrangedSubview(proxyCredentialsViewController.view)
        proxyCredentialsViewController.didMove(toParent: self)
    }

    func textField(_ textField: UITextField, editing: Bool) {
        loginActiveField = editing ? textField : nil
    }
}

extension AuthenticationCredentialsViewController: ValidatedTextFieldDelegate {
    func buttonPressed(_: UIButton) {
        emailPasswordInputField.passwordField.isSecureTextEntry.toggle()
        emailPasswordInputField.passwordField.updatePasscodeIcon()
    }
}

extension ValidatedTextField {
    func addRevealButton(delegate: ValidatedTextFieldDelegate) {
        showConfirmButton = true
        validatedTextFieldDelegate = delegate
        overrideButtonIcon = StyleKitIcon.AppLock.reveal
    }
}
