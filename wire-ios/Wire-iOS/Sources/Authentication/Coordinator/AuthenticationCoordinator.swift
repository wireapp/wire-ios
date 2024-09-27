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
import WireReusableUIComponents
import WireSyncEngine

/// Provides and asks for context when registering users.

protocol AuthenticationCoordinatorDelegate: AnyObject {
    /// The coordinator finished authenticating the user.

    func userAuthenticationDidComplete(userSession: UserSession)
}

/// Manages the flow of authentication for the user. Decides which steps to take for login, registration
/// and team creation.
///
/// Interaction with the different components is abstracted away in the *actions*. You can execute actions
/// yourself, in response to user interaction. However, most of the time, actions are passed by the responder
/// chain, which is composed of objects that compute the actions to execute in response to a notification
/// or delegate call from one of the abstracted components.

final class AuthenticationCoordinator: NSObject, AuthenticationEventResponderChainDelegate {
    /// The handle to the OS log for authentication events.
    let log = ZMSLog(tag: "Authentication")

    /// The navigation controller that presents the authentication interface.
    weak var presenter: UINavigationController? {
        didSet { activityIndicator = presenter.map { .init(view: $0.view) } }
    }

    /// The object receiving updates from the authentication state and providing state.
    weak var delegate: AuthenticationCoordinatorDelegate?

    private var activityIndicator: BlockingActivityIndicator?

    // MARK: - Event Handling Properties

    /// The object responsible for handling events.
    ///
    /// You use this object to tag events as they happen. It then iterates over the internal
    /// event handlers in the chain, to decide what actions to take.
    ///
    /// The authentication coordinator is the delegate of the event responder chain, as it is
    /// responsible for executing the actions provided by the selected event handler.

    let eventResponderChain: AuthenticationEventResponderChain

    // MARK: - State

    /// The displayed view controller.
    var currentViewController: AuthenticationStepViewController?

    /// The object controlling the state of authentication.
    let stateController: AuthenticationStateController

    /// The object hepls accessing to some authentication information.
    let statusProvider: AuthenticationStatusProvider

    /// The object that manages active user sessions.
    let sessionManager: ObservableSessionManager

    /// The object that determines what features are available.
    let featureProvider: AuthenticationFeatureProvider

    /// The object to use to create the UI for authentication steps.
    let interfaceBuilder: AuthenticationInterfaceBuilder

    /// The object to use to start and control the company login flow.
    let companyLoginController = CompanyLoginController(withDefaultEnvironment: ())

    /// The object to use to restore backups.
    let backupRestoreController: BackupRestoreController

    // MARK: - Internal State

    private var loginObservers: [Any] = []
    private var unauthenticatedSessionObserver: Any?
    private var postLoginObservers: [Any] = []
    private var pendingAlert: AuthenticationCoordinatorAlert?
    private var registrationStatus: RegistrationStatus {
        unauthenticatedSession.registrationStatus
    }

    private var isTornDown = false

    var pendingModal: UIViewController?

    /// The user session to use before authentication has finished.
    var unauthenticatedSession: UnauthenticatedSession {
        sessionManager.activeUnauthenticatedSession
    }

    // MARK: - Initialization

    /// Creates a new authentication coordinator with the required supporting objects.
    init(
        presenter: UINavigationController,
        sessionManager: ObservableSessionManager,
        featureProvider: AuthenticationFeatureProvider,
        statusProvider: AuthenticationStatusProvider
    ) {
        self.presenter = presenter
        self.sessionManager = sessionManager
        self.statusProvider = statusProvider
        self.featureProvider = featureProvider
        self.stateController = AuthenticationStateController()
        self.interfaceBuilder = AuthenticationInterfaceBuilder(featureProvider: featureProvider)
        self.eventResponderChain = AuthenticationEventResponderChain(featureProvider: featureProvider)
        self.backupRestoreController = BackupRestoreController(target: presenter)
        super.init()
        updateLoginObservers()
        self.unauthenticatedSessionObserver = sessionManager
            .addUnauthenticatedSessionManagerCreatedSessionObserver(self)
        companyLoginController?.delegate = self
        backupRestoreController.delegate = self
        presenter.delegate = self
        stateController.delegate = self
        eventResponderChain.configure(delegate: self)
        addBackendSwitchObserver()
    }

    deinit {
        if !isTornDown {
            assertionFailure("AuthenticationCoordinator was not torn down.")
        }
    }

    func tearDown() {
        loginObservers.removeAll()
        unauthenticatedSessionObserver = nil
        postLoginObservers.removeAll()
        isTornDown = true
    }

    // MARK: - Blocking Activity Indicator

    func startActivityIndicator() {
        Task { @MainActor in
            activityIndicator?.start()
        }
    }

    func stopActivityIndicator() {
        Task { @MainActor in
            activityIndicator?.stop()
        }
    }
}

// MARK: - State Management

extension AuthenticationCoordinator: AuthenticationStateControllerDelegate {
    func stateDidChange(
        _ newState: AuthenticationFlowStep,
        mode: AuthenticationStateController.StateChangeMode
    ) {
        guard let presenter, newState.needsInterface else {
            return
        }

        guard let stepViewController = interfaceBuilder.makeViewController(for: newState) else {
            fatalError("Step \(newState) requires user interface, but the interface builder does not support it.")
        }

        stepViewController.authenticationCoordinator = self
        currentViewController = stepViewController

        switch mode {
        case .normal:
            presenter.pushViewController(stepViewController, animated: true)

        case .reset:
            presenter.setViewControllers([stepViewController], animated: true)

        case .replace:
            var viewControllers = presenter.viewControllers
            viewControllers[viewControllers.count - 1] = stepViewController
            presenter.setViewControllers(viewControllers, animated: true)

        case let .rewindToOrReset(milestone):
            var viewControllers = presenter.viewControllers
            let rewindedController = viewControllers.first { milestone.shouldRewind(to: $0) }
            if let rewindedController {
                viewControllers = [
                    viewControllers.prefix { !milestone.shouldRewind(to: $0) },
                    [rewindedController],
                    [stepViewController],
                ].flatMap { $0 }
                presenter.setViewControllers(viewControllers, animated: true)
            } else {
                presenter.setViewControllers([stepViewController], animated: true)
            }
        }
    }
}

// MARK: - Event Handling

extension AuthenticationCoordinator: AuthenticationActioner, SessionManagerCreatedSessionObserver {
    func sessionManagerCreated(userSession: ZMUserSession) {
        log.info("Session manager created session: \(userSession)")
        currentPostRegistrationFields().map(sendPostRegistrationFields)
    }

    func sessionManagerCreated(unauthenticatedSession: UnauthenticatedSession) {
        updateLoginObservers()
    }

    func addBackendSwitchObserver() {
        NotificationCenter.default.addObserver(
            forName: BackendEnvironment.backendSwitchNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.startAuthentication(with: nil, numberOfAccounts: SessionManager.numberOfAccounts)
        }
    }

    func updateLoginObservers() {
        loginObservers = [
            sessionManager.addSessionManagerCreatedSessionObserver(self),
        ]
        sessionManager.loginDelegate = self
        registrationStatus.delegate = self
    }

    /// Registers the post-login observation tokens if they were not already registered.

    fileprivate func registerPostLoginObserversIfNeeded() {
        guard postLoginObservers.isEmpty else {
            log.warn("Post login observers are already registered.")
            return
        }

        guard let selfUser = statusProvider.selfUser else {
            log.error("Post login observers were not registered because there is no self user.")
            return
        }

        guard let sharedSession = statusProvider.sharedUserSession else {
            log.error("Post login observers were not registered because there is no user session.")
            return
        }

        guard let userProfile = statusProvider.selfUserProfile else {
            log.error("Post login observers were not registered because there is no user profile.")
            return
        }

        postLoginObservers = [
            userProfile.add(observer: self),
            UserChangeInfo.add(observer: self, for: selfUser, in: sharedSession)!,
        ]
    }

    /// Executes the actions in response to an event.
    /// - parameter actions: The actions to execute.

    func executeActions(_ actions: [AuthenticationCoordinatorAction]) {
        for action in actions {
            switch action {
            case .showLoadingView:
                startActivityIndicator()

            case .hideLoadingView:
                stopActivityIndicator()

            case .completeBackupStep:
                unauthenticatedSession.continueAfterBackupImportStep()

            case let .executeFeedbackAction(action):
                currentViewController?.executeErrorFeedbackAction(action)

            case let .presentAlert(alertModel):
                presentAlert(for: alertModel)

            case let .presentErrorAlert(alertModel):
                presentErrorAlert(for: alertModel)

            case .completeLoginFlow:
                delegate?.userAuthenticationDidComplete(
                    userSession: statusProvider.sharedUserSession!
                )

            case .startPostLoginFlow:
                registerPostLoginObserversIfNeeded()

            case let .transition(nextStep, mode):
                stateController.transition(to: nextStep, mode: mode)

            case let .requestEmailVerificationCode(email, password):
                requestEmailVerificationCode(email: email, password: password, isResend: false)

            case .configureNotifications:
                sessionManager.configureUserNotifications()

            case let .startIncrementalUserCreation(unregisteredUser):
                stateController.transition(to: .incrementalUserCreation(unregisteredUser, .start))
                eventResponderChain.handleEvent(ofType: .registrationStepSuccess)

            case let .setMarketingConsent(consentValue):
                setMarketingConsent(consentValue)

            case .completeUserRegistration:
                finishRegisteringUser()

            case let .unwindState(popController):
                unwindState(popController: popController)

            case let .openURL(url):
                openURL(url)

            case .repeatAction:
                repeatAction()

            case let .displayInlineError(error):
                currentViewController?.displayError(error)

            case let .continueFlowWithLoginCode(code):
                continueFlow(withVerificationCode: code)

            case let .startRegistrationFlow(unverifiedCredential):
                activateNetworkSessions { [weak self] _ in
                    self?.startRegistration(unverifiedCredential)
                }

            case let .setFullName(fullName):
                updateUnregisteredUser(\.name, fullName)

            case let .setUserPassword(password):
                updateUnregisteredUser(\.password, password)

            case let .setUsername(username):
                updateUsername(username)

            case let .updateBackendEnvironment(url):
                companyLoginController?.updateBackendEnvironment(with: url)

            case let .startCompanyLogin(code):
                activateNetworkSessions { [weak self] _ in
                    self?.startCompanyLoginFlowIfPossible(linkCode: code)
                }

            case .startSSOFlow:
                startAutomaticSSOFlow()

            case let .startLoginFlow(request, credentials):
                startLoginFlow(request: request, proxyCredentials: credentials)

            case .startBackupFlow:
                backupRestoreController.startBackupFlow()

            case let .signOut(warn):
                signOut(warn: warn)

            case let .addEmailAndPassword(newCredentials):
                setEmailCredentialsForCurrentUser(newCredentials)

            case .configureDevicePermissions:
                guard
                    let session: UserSession = ZMUserSession.shared(),
                    session.encryptMessagesAtRest
                else {
                    eventResponderChain.handleEvent(ofType: .deviceConfigurationComplete)
                    return
                }

                session.evaluateAppLockAuthentication(
                    passcodePreference: .deviceOnly,
                    description: L10n.Localizable.Self.Settings.PrivacySecurity.LockApp.description
                ) { [weak self] _  in
                    DispatchQueue.main.async {
                        self?.eventResponderChain.handleEvent(ofType: .deviceConfigurationComplete)
                    }
                }

            case .startE2EIEnrollment:
                startE2EIdentityEnrollment()

            case .completeE2EIEnrollment:
                completeE2EIdentityEnrollment()
            }
        }
    }
}

// MARK: - External Input

extension AuthenticationCoordinator {
    /// Call this method when the application becomes unauthenticated and that the user
    /// needs to authenticate.
    ///
    /// - parameter error: The error that caused the unauthenticated state, if any.
    /// - parameter numberOfAccounts: The number of accounts that are signed in with the app.

    func startAuthentication(with error: NSError?, numberOfAccounts: Int) {
        eventResponderChain.handleEvent(ofType: .flowStart(error, numberOfAccounts))
    }

    /// Creates a new unregistered user for starting a registration flow.

    func makeUnregisteredUser() -> UnregisteredUser {
        let user = UnregisteredUser()
        user.accentColor = .blue
        return user
    }

    /// Notifies the event responder chain that user input was provided.
    ///
    /// The responder chain will then go through all the input event handlers and
    /// pick the first that accepts the input.
    ///
    /// - parameter input: The input provided by the user.

    func handleUserInput(_ input: Any) {
        eventResponderChain.handleEvent(ofType: .userInput(input))
    }
}

// MARK: - Actions

extension AuthenticationCoordinator {
    // MARK: - State

    /// Unwinds the state.
    private func unwindState(popController: Bool) {
        if popController {
            _ = presenter?.popViewController(animated: true)
        } else {
            stateController.unwindState()
        }
    }

    /// Signs the current user out with a warning.
    private func signOut(warn: Bool) {
        if warn {
            let signOutAction = AuthenticationCoordinatorAlertAction(
                title: L10n.Localizable.General.ok,
                coordinatorActions: [
                    .showLoadingView,
                    .signOut(
                        warn: false
                    ),
                ],
                style: .destructive
            )

            let alertModel = AuthenticationCoordinatorAlert(
                title: L10n.Localizable.Self.Settings.AccountDetails.LogOut.Alert.title,
                message: L10n.Localizable.Self.Settings.AccountDetails.LogOut.Alert.message,
                actions: [.cancel, signOutAction]
            )

            presentAlert(for: alertModel)
        } else {
            guard let accountId = unauthenticatedSession.accountId,
                  let unauthenticatedAccount = sessionManager.accountManager.account(with: accountId) else {
                fatal("No unauthenticated account to log out from")
            }

            sessionManager.delete(account: unauthenticatedAccount)
        }
    }

    /// Repeats the current action.
    func repeatAction() {
        switch stateController.currentStep {
        case .enterActivationCode, .enterEmailVerificationCode:
            resendVerificationCode()
        default:
            return
        }
    }

    // MARK: - Modals

    /// Opens the browser and reopens the current alert upon dismissal if needed.
    private func openURL(_ url: URL) {
        let browser = BrowserViewController(url: url)
        browser.onDismiss = {
            if let alertModel = self.pendingAlert {
                self.stopActivityIndicator()
                self.presentAlert(for: alertModel)
                self.pendingAlert = nil
            }
        }

        presenter?.present(browser, animated: true, completion: nil)
    }

    /// Presents an error alert.
    private func presentErrorAlert(for alertModel: AuthenticationCoordinatorErrorAlert) {
        presenter?.showAlert(for: alertModel.error) { _ in
            self.executeActions(alertModel.completionActions)
        }
    }

    /// Presents an alert.
    private func presentAlert(for alertModel: AuthenticationCoordinatorAlert) {
        let alert = UIAlertController(title: alertModel.title, message: alertModel.message, preferredStyle: .alert)

        for actionModel in alertModel.actions {
            let action = UIAlertAction(title: actionModel.title, style: actionModel.style) { _ in
                if actionModel.coordinatorActions.contains(where: \.retainsModal) {
                    self.pendingAlert = alertModel
                }

                self.executeActions(actionModel.coordinatorActions)
            }

            alert.addAction(action)
        }

        presenter?.present(alert, animated: true)
    }

    // MARK: - Registration Code

    /// Starts the registration flow with the specified credentials.
    ///
    /// This step will ask the registration status to send the activation code
    /// by text message or email. It will advance the state to `.sendActivationCode`.
    ///
    /// - parameter credentials: The unverified credentials to register with.

    private func startRegistration(_ unverifiedEmail: String) {
        guard case let .createCredentials(unregisteredUser) = stateController.currentStep,
              let presenter else {
            log.error("Cannot start phone registration outside of registration flow.")
            return
        }

        UIAlertController.requestTOSApproval(over: presenter, forTeamAccount: false) { approved in
            if approved {
                unregisteredUser.acceptedTermsOfService = true
                unregisteredUser.unverifiedEmail = unverifiedEmail
                self.sendActivationCode(unverifiedEmail, unregisteredUser, isResend: false)
            }
        }
    }

    /// Sends the registration activation code.
    private func sendActivationCode(_ unverifiedEmail: String, _ user: UnregisteredUser, isResend: Bool) {
        startActivityIndicator()
        stateController.transition(to: .sendActivationCode(
            unverifiedEmail: unverifiedEmail,
            user: user,
            isResend: isResend
        ))
        registrationStatus.sendActivationCode(to: unverifiedEmail)
    }

    /// Asks the registration status to activate the credentials with the code provided by the user.
    private func activateCredentials(unverifiedEmail: String, user: UnregisteredUser, code: String) {
        startActivityIndicator()
        stateController.transition(to: .activateCredentials(unverifiedEmail: unverifiedEmail, user: user, code: code))
        registrationStatus.checkActivationCode(unverifiedEmail: unverifiedEmail, code: code)
    }

    // MARK: - Linear Registration

    /// Sets the marketing consent value for the user to be registered.
    private func setMarketingConsent(_ consentValue: Bool) {
        switch stateController.currentStep {
        case .incrementalUserCreation:
            updateUnregisteredUser(\.marketingConsent, consentValue)

        default:
            log.error("Cannot set marketing consent in current state \(stateController.currentStep)")
            return
        }
    }

    /// Updates a value of the unregistered user and notifies the responder chain of the success.
    private func updateUnregisteredUser<T>(_ keyPath: ReferenceWritableKeyPath<UnregisteredUser, T?>, _ newValue: T) {
        guard case let .incrementalUserCreation(unregisteredUser, _) = stateController.currentStep else {
            log.error("Cannot update unregistered user outide of the incremental user creation flow")
            return
        }

        unregisteredUser[keyPath: keyPath] = newValue
        eventResponderChain.handleEvent(ofType: .registrationStepSuccess)
    }

    /// Creates the user on the backend and advances the state.
    private func finishRegisteringUser() {
        guard case let .incrementalUserCreation(unregisteredUser, _) = stateController.currentStep else {
            return
        }

        stateController.transition(to: .createUser(unregisteredUser))
        registrationStatus.create(user: unregisteredUser)
    }

    // MARK: - Post Registration

    /// Computes the post registration fields, if any.
    private func currentPostRegistrationFields() -> AuthenticationPostRegistrationFields? {
        switch stateController.currentStep {
        case let .createUser(unregisteredUser):
            guard let marketingConsent = unregisteredUser.marketingConsent else {
                return nil
            }

            return AuthenticationPostRegistrationFields(marketingConsent: marketingConsent)

        default:
            return nil
        }
    }

    /// Sends the fields provided during registration that requires a registered user session.
    private func sendPostRegistrationFields(_ fields: AuthenticationPostRegistrationFields) {
        guard let userSession = statusProvider.sharedUserSession else {
            log.error("Could not save the marketing consent as there is no user session for the user.")
            return
        }

        // Marketing consent
        UIAlertController.newsletterSubscriptionDialogWasDisplayed = true
        userSession.submitMarketingConsent(with: fields.marketingConsent)
    }

    // MARK: - Login

    /// Starts the login flow with the specified request.
    private func startLoginFlow(
        request: AuthenticationLoginRequest,
        proxyCredentials: AuthenticationProxyCredentialsInput?
    ) {
        let action = { [weak self] in

            switch request {
            case let .email(address, password):
                let credentials = UserEmailCredentials(email: address, password: password)
                self?.startActivityIndicator()
                self?.stateController.transition(to: .authenticateEmailCredentials(credentials))
                self?.unauthenticatedSession.login(with: credentials)
            }
        }

        if let proxyCredentials {
            sessionManager.saveProxyCredentials(
                username: proxyCredentials.username,
                password: proxyCredentials.password
            )
        }

        activateNetworkSessions { [weak self] error in
            guard error == nil else {
                self?.sessionManager.removeProxyCredentials()
                self?.showAlertWithNoInternetConnectionError()
                return
            }
            action()
        }
    }

    // Sends the login verification code to the email address
    private func requestEmailVerificationCode(email: String, password: String, isResend: Bool) {
        if !isResend {
            let nextStep = AuthenticationFlowStep.enterEmailVerificationCode(
                email: email,
                password: password,
                isResend: isResend
            )
            stateController.transition(to: nextStep)
        }
        unauthenticatedSession.requestEmailVerificationCodeForLogin(email: email)
    }

    private func requestEmailLogin(with credentials: UserEmailCredentials) {
        startActivityIndicator()
        stateController.transition(to: .authenticateEmailCredentials(credentials))
        unauthenticatedSession.login(with: credentials)
    }

    // MARK: - Generic Verification

    /// Resends the verification code to the user, if allowed by the current state.
    private func resendVerificationCode() {
        switch stateController.currentStep {
        case let .enterEmailVerificationCode(email, password, _):
            requestEmailVerificationCode(email: email, password: password, isResend: true)
        case let .enterActivationCode(credential, user):
            sendActivationCode(credential, user, isResend: true)
        default:
            log.error("Cannot send verification code in the current state (\(stateController.currentStep)")
        }
    }

    /// Checks the verification code provided by the user, and continues to the next appropriate step.
    /// - parameter code: The verification code provided by the user.

    private func continueFlow(withVerificationCode code: String) {
        switch stateController.currentStep {
        case let .enterEmailVerificationCode(email, password, _):
            let credentials = UserEmailCredentials(email: email, password: password, emailVerificationCode: code)
            requestEmailLogin(with: credentials)

        case let .enterActivationCode(unverifiedEmail, user):
            activateCredentials(unverifiedEmail: unverifiedEmail, user: user, code: code)

        default:
            log.error("Cannot continue flow with user code in the current state (\(stateController.currentStep)")
        }
    }

    // MARK: - Add Email And Password

    /// Sets th e-mail and password credentials for the current user.
    private func setEmailCredentialsForCurrentUser(_ credentials: UserEmailCredentials) {
        guard case .addEmailAndPassword = stateController.currentStep else {
            log.error("Cannot save e-mail and password outside of designated step.")
            return
        }

        guard let profile = statusProvider.selfUserProfile else {
            log.error("Cannot save e-mail and password outside of designated step.")
            return
        }

        stateController.transition(to: .registerEmailCredentials(credentials, isResend: false))
        startActivityIndicator()

        let result = setCredentialsWithProfile(profile, credentials: credentials) && sessionManager
            .update(credentials: credentials) == true

        if !result {
            let error = NSError(userSessionErrorCode: .invalidEmail, userInfo: nil)
            emailUpdateDidFail(error)
        }
    }

    @discardableResult
    private func setCredentialsWithProfile(_ profile: UserProfile, credentials: UserEmailCredentials) -> Bool {
        do {
            try profile.requestSettingEmailAndPassword(credentials: credentials)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Company Login

    var canStartCompanyLogin: Bool {
        switch stateController.currentStep {
        case .companyLogin:
            return true
        default:
            log.warn("Cannot start company login in step: \(stateController.currentStep)")
            return false
        }
    }

    /// Manually start the company login flow.
    private func startCompanyLoginFlowIfPossible(linkCode: UUID?) {
        if let linkCode {
            companyLoginController?.attemptLoginWithSSOCode(linkCode)
        } else {
            companyLoginController?.displayCompanyLoginPrompt()
        }
    }

    /// Automatically start the SSO flow if possible
    private func startAutomaticSSOFlow() {
        companyLoginController?.startAutomaticSSOFlow()
    }

    /// Call this method when the corrdinated view controller appears, to detect the sso code and display it if needed.
    func detectSSOCodeIfPossible() {
        if canStartCompanyLogin {
            companyLoginController?.isAutoDetectionEnabled = true
            companyLoginController?.detectSSOCode()
        } else {
            companyLoginController?.isAutoDetectionEnabled = false
        }
    }

    /// Call this method when company login fails or is cancelled by the user.
    func cancelCompanyLogin() {
        guard case .companyLogin = stateController.currentStep else {
            log.error("Cannot cancel company login outside of the dedicated flow.")
            return
        }

        stateController.unwindState()
    }

    // MARK: - End-to-end Identity

    private func startE2EIdentityEnrollment() {
        typealias E2ei = L10n.Localizable.Registration.Signin.E2ei

        guard let session = statusProvider.sharedUserSession else { return }
        let e2eiCertificateUseCase = session.enrollE2EICertificate
        guard let topmostViewController = UIApplication.shared.topmostViewController(onlyFullScreen: false) else {
            return
        }
        let oauthUseCase = OAuthUseCase(targetViewController: { topmostViewController })

        Task { @MainActor in
            do {
                let certificateChain = try await e2eiCertificateUseCase.invoke(authenticate: oauthUseCase.invoke)
                executeActions([
                    .hideLoadingView,
                    .transition(.enrollE2EIdentitySuccess(certificateChain), mode: .reset),
                ])
            } catch OAuthError.userCancelled {
                executeActions([
                    .hideLoadingView,
                ])
            } catch {
                executeActions([
                    .hideLoadingView,
                    .presentAlert(
                        .init(
                            title: E2ei.Error.Alert.title,
                            message: E2ei.Error.Alert.message,
                            actions: [.ok]
                        )
                    ),
                ])
            }
        }
    }

    private func completeE2EIdentityEnrollment() {
        executeActions([.showLoadingView])
        guard let session = statusProvider.sharedUserSession else { return }
        session.reportEndToEndIdentityEnrollmentSuccess()
    }

    private func showAlertWithNoInternetConnectionError() {
        typealias Alert = L10n.Localizable.SystemStatusBar.NoInternet

        executeActions(
            [.presentAlert(.init(
                title: Alert.title,
                message: Alert.explanation,
                actions: [.ok]
            ))]
        )
    }

    /// Call this method when ready to use network sessions : first login
    private func activateNetworkSessions(before action: @escaping (Error?) -> Void) {
        sessionManager.markNetworkSessionsAsReady(true)
        startActivityIndicator()
        sessionManager.resolveAPIVersion { [weak self] error in
            self?.stopActivityIndicator()
            if error != nil {
                self?.sessionManager.markNetworkSessionsAsReady(false)
            }
            action(error)
        }
    }

    private func updateUsername(_ username: String) {
        typealias AlreadyTakenError = L10n.Localizable.Registration.Signin.Username.AlreadyTakenError
        typealias UnknownError = L10n.Localizable.Registration.Signin.Username.UnknownError

        let changeUsername = statusProvider.sharedUserSession?.changeUsername

        Task {
            do {
                try await changeUsername?.invoke(username: username)
            } catch let error as ChangeUsernameError {
                await MainActor.run {
                    let alert = switch error {
                    case .taken:
                        AuthenticationCoordinatorAlert(
                            title: AlreadyTakenError.title,
                            message: AlreadyTakenError.message,
                            actions: [.ok]
                        )

                    case .unknown:
                        AuthenticationCoordinatorAlert(
                            title: UnknownError.title,
                            message: UnknownError.message,
                            actions: [.ok]
                        )
                    }
                    executeAction(.presentAlert(alert))
                }
            } catch {
                WireLogger.authentication.error("failed to update MLS migration status: \(error)")
                assertionFailure(String(reflecting: error))
            }
        }
    }
}

extension AuthenticationStateController.RewindMilestone {
    fileprivate func shouldRewind(to step: UIViewController) -> Bool {
        switch self {
        case .createCredentials:
            (step as? AuthenticationCredentialsViewController) != nil
        }
    }
}
