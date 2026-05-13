//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
    typealias FlowType = AuthenticationCredentialsViewModel.FlowType
    weak var actioner: AuthenticationActioner?

    /// The type of flow presented by the view controller.
    var flowType: FlowType {
        viewModel.flowType
    }

    /// The currently pre-filled credentials.
    var prefilledCredentials: AuthenticationPrefilledCredentials? {
        didSet {
            viewModel?.prefilledCredentials = prefilledCredentials
            updatePrefilledCredentials()
        }
    }

    /// Whether we are in the registration flow.
    var isRegistering: Bool {
        viewModel.isRegistering
    }

    var isReauthenticating: Bool {
        viewModel.isReauthenticating
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
    private var viewModel: AuthenticationCredentialsViewModel!

    convenience init(
        flowType: FlowType,
        backendEnvironmentProvider: @escaping () -> BackendEnvironmentProvider = { BackendEnvironment.shared }
    ) {
        switch flowType {
        case let .login(credentials):
            let description = LogInStepDescription()
            self.init(description: description, contentCenterConstraintActivation: false)
            self.viewModel = AuthenticationCredentialsViewModel(flowType: flowType)
            self.prefilledCredentials = credentials
            self.shouldUseScrollView = viewModel.shouldUseScrollView
        case let .reauthentication(credentials):
            let description = ReauthenticateStepDescription(prefilledCredentials: credentials)
            self.init(description: description, contentCenterConstraintActivation: false)
            self.viewModel = AuthenticationCredentialsViewModel(flowType: flowType)
            self.prefilledCredentials = credentials
            self.shouldUseScrollView = viewModel.shouldUseScrollView
        case let .registration(credentials):
            let description = PersonalRegistrationStepDescription()
            self.init(description: description, contentCenterConstraintActivation: true)
            self.viewModel = AuthenticationCredentialsViewModel(flowType: flowType)
            self.prefilledCredentials = credentials
            self.shouldUseScrollView = viewModel.shouldUseScrollView
        }

        self.backendEnvironmentProvider = backendEnvironmentProvider
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
        activeFieldChange: { [weak self] textField in
            self?.loginActiveField = textField
        }
    )

    lazy var forgotPasswordButton = {
        let button = ZMButton(fontSpec: .smallLightFont)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: FontSpec.smallSemiboldFont.font!,
            .foregroundColor: SemanticColors.Button.textUnderlineEnabled,
            .underlineStyle: NSUnderlineStyle.single.rawValue
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
        let proxyUsername: String
        let proxyPassword: String
        if isProxyCredentialsRequired {
            proxyUsername = proxyCredentialsViewController.usernameInput.input
            proxyPassword = proxyCredentialsViewController.passwordInput.input
        } else {
            proxyUsername = ""
            proxyPassword = ""
        }

        let route = viewModel.loginButtonTapped(
            isProxyCredentialsRequired: isProxyCredentialsRequired,
            email: emailPasswordInputField.emailField.input,
            password: emailPasswordInputField.passwordField.input,
            proxyUsername: proxyUsername,
            proxyPassword: proxyPassword
        )
        switch route {
        case .confirmEmailPasswordInput:
            emailPasswordInputField.confirmButtonTapped()
        case let .submitCredentials(emailPasswordInput, proxyCredentialsInput):
            valueSubmitted((emailPasswordInput, proxyCredentialsInput))
        default:
            break
        }
    }

    @objc
    func forgotPasswordTapped(sender: UIButton) {
        complete(route: viewModel.forgotPasswordTapped())
    }

    override func createConstraints() {
        super.createConstraints()
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loginButton.heightAnchor.constraint(equalToConstant: 48)
        ])

        if shouldUseScrollView {
            NSLayoutConstraint.activate([
                contentStack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor),
                contentStack.trailingAnchor.constraint(greaterThanOrEqualTo: view.trailingAnchor),
                contentStack.widthAnchor.constraint(equalToConstant: 375),
                contentStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                contentStack.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor, constant: 86)
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
        complete(route: viewModel.customBackendInfoTapped())
    }

    private var contextualFirstResponder: UIResponder? {
        switch viewModel.contextualFirstResponder {
        case .emailPassword:
            emailPasswordInputField
        case .email:
            emailInputField
        case .proxyUsername:
            proxyCredentialsViewController.usernameInput
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

        let displayState = viewModel.displayState
        emailPasswordInputField.isHidden = displayState.isEmailPasswordInputHidden
        emailInputField.isHidden = displayState.isEmailInputHidden
        loginButton.isHidden = displayState.isLoginButtonHidden
        forgotPasswordButton.isHidden = displayState.isForgotPasswordButtonHidden

        setSecondaryViewHidden(false)
    }

    private func updatePrefilledCredentials() {
        switch viewModel.prefillTarget() {
        case let .registrationEmail(email):
            emailInputField.text = email
        case let .emailPassword(email):
            emailPasswordInputField.prefill(email: email)
        case .none:
            break
        }
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

    private func complete(route: AuthenticationCredentialsViewModel.Route) {
        switch route {
        case let .submitEmail(email):
            valueSubmitted(email)
        case let .submitCredentials(emailPasswordInput, proxyCredentialsInput):
            valueSubmitted((emailPasswordInput, proxyCredentialsInput))
        case .confirmEmailPasswordInput:
            emailPasswordInputField.confirmButtonTapped()
        case let .focus(target):
            focus(target)
        case .openForgotPassword:
            actioner?.executeAction(.openURL(URL.wr_passwordReset))
        case .showCustomBackendInfo:
            let intent = AuthenticationShowCustomBackendInfoHandler.Intent.showCustomBackendInfo
            authenticationCoordinator?.eventResponderChain.handleEvent(ofType: .userInput(intent))
        case .none:
            break
        }
    }

    private func focus(_ target: AuthenticationCredentialsViewModel.FocusTarget) {
        switch target {
        case .email:
            emailInputField.becomeFirstResponder()
        case .emailPassword:
            emailPasswordInputField.becomeFirstResponder()
        case .proxyUsername:
            proxyCredentialsViewController.usernameInput.becomeFirstResponder()
        case .none:
            break
        }
    }

    @objc
    private func emailConfirmButtonTapped(sender: IconButton) {
        complete(route: viewModel.emailConfirmed(emailInputField.input))
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

        complete(route: viewModel.emailConfirmed(emailInputField.input))
        return true
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        guard
            textField == emailInputField,
            !viewModel.canBeginEditingEmail(useWireAuthentication: DeveloperFlag.useWireAuthentication.isOn)
        else {
            return true
        }

        return false
    }

    // MARK: - Email / Password Input

    func textFieldDidUpdateText(_ textField: EmailPasswordTextField) {
        updateLoginButtonState()
    }

    func textField(_ textField: EmailPasswordTextField, didConfirmCredentials credentials: (String, String)) {
        complete(
            route: viewModel.credentialsConfirmed(
                email: credentials.0,
                password: credentials.1,
                isProxyCredentialsRequired: isProxyCredentialsRequired
            )
        )
    }

    func textFieldDidSubmitWithValidationError(_ textField: EmailPasswordTextField) {
        complete(
            route: viewModel.credentialsSubmittedWithValidationError(
                isProxyCredentialsRequired: isProxyCredentialsRequired,
                isPasswordEmpty: textField.isPasswordEmpty
            )
        )
    }

    private func updateLoginButtonState() {
        let hasValidProxyUsername: Bool
        let hasValidProxyPassword: Bool
        if isProxyCredentialsRequired {
            hasValidProxyUsername = proxyCredentialsViewController.usernameInput.isInputValid
            hasValidProxyPassword = proxyCredentialsViewController.passwordInput.isInputValid
        } else {
            hasValidProxyUsername = false
            hasValidProxyPassword = false
        }

        loginButton.isEnabled = viewModel.isLoginButtonEnabled(input: .init(
            isProxyCredentialsRequired: isProxyCredentialsRequired,
            hasValidEmailPasswordInput: emailPasswordInputField.hasValidInput,
            hasValidEmail: emailPasswordInputField.emailValidationError == nil,
            hasValidPassword: emailPasswordInputField.passwordValidationError == nil,
            hasValidProxyUsername: hasValidProxyUsername,
            hasValidProxyPassword: hasValidProxyPassword
        ))
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
    func buttonPressed(_ sender: UIButton) {
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
