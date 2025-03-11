//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import Foundation
import UIKit
import WireAuthenticationAPI
import WireLogging
import WireReusableUIComponents

@MainActor
package final class LoginViaEmailViewModel: ObservableObject {

    @Published var password: String = "" {
        didSet { showPasswordRules = !isPasswordValid }
    }

    @Published private(set) var showPasswordRules = false
    @Published private(set) var isLoading = false
    @Published var alert: Alert?

    private let router: any Router
    private let loginViaEmailUseCase: any LoginViaEmailUseCaseProtocol
    private let backendEnvironment: WireAuthenticationBackendEnvironment
    private let forgotPasswordURL: URL
    private let passwordValidator: any PasswordValidator
    private let onCreateAccount: () -> Void

    let email: String
    let canCreateAccount: Bool
    let didDetectDomainConflict: Bool

    // MARK: - Life cycle

    package init(
        router: any Router,
        loginViaEmailUseCase: any LoginViaEmailUseCaseProtocol,
        backendEnvironment: WireAuthenticationBackendEnvironment,
        email: String,
        accountsURL: URL,
        passwordValidator: any PasswordValidator,
        canCreateAccount: Bool,
        didDetectDomainConflict: Bool,
        onCreateAccount: @escaping () -> Void
    ) {
        self.router = router
        self.loginViaEmailUseCase = loginViaEmailUseCase
        self.backendEnvironment = backendEnvironment
        self.email = email
        self.forgotPasswordURL = accountsURL.appendingPathComponent("forgot")
        self.passwordValidator = passwordValidator
        self.canCreateAccount = canCreateAccount
        self.didDetectDomainConflict = didDetectDomainConflict
        self.onCreateAccount = onCreateAccount
    }

    var localizedPasswordRules: String? {
        passwordValidator.localizedRulesDescription
    }

    var isPasswordValid: Bool {
        passwordValidator.isPasswordValid(trimmedPassword)
    }

    func submitPassword() async {
        isLoading = true

        let loginTask = Task.detached { [loginViaEmailUseCase, email, trimmedPassword] in
            try await loginViaEmailUseCase.invoke(
                email: email,
                password: trimmedPassword,
                verificationCode: nil
            )
        }

        do {
            let (cookies, token) = try await loginTask.value

            let emailCredentials = EmailCredentials(
                email: email,
                password: trimmedPassword,
                verificationCode: nil
            )

            let authenticationResult = AuthenticationResult(
                userID: token.userID,
                cookies: cookies,
                accessToken: token,
                emailCredentials: emailCredentials,
                backendEnvironment: backendEnvironment
            )

            router.presentSheet(
                RootView.ModalDestination.noHistory(
                    authenticationResult: authenticationResult,
                    didDetectDomainConflict: didDetectDomainConflict
                )
            )

            WireLogger.authentication.info("login via email succeeded")
        } catch {
            WireLogger.authentication.info("login via email returned an error: \(error)")

            switch error {
            case LoginViaEmailUseCaseFailure.invalidCredentials:
                alert = .invalidCredentials
            case LoginViaEmailUseCaseFailure.twoFactorAuthenticationRequired:
                router.navigate(
                    to: LoginViaEmailView.Destination.verifyLogin(email: email, password: password)
                )
            case LoginViaEmailUseCaseFailure.accountPendingActivation:
                alert = .accountPendingActivation
            case LoginViaEmailUseCaseFailure.accountSuspended:
                alert = .accountSuspended
            case LoginViaEmailUseCaseFailure.noInternet:
                alert = .noInternet
            default:
                WireLogger.authentication.error("Unexpected error during login via email: \(error)")
                alert = .unknownError
            }
        }

        isLoading = false
    }

    func recoverPassword() {
        UIApplication.shared.open(forgotPasswordURL)
    }

    func createAccount() {
        onCreateAccount()
    }

    // MARK: - Private

    private var trimmedPassword: String {
        password.trimmingCharacters(in: .whitespacesAndNewlines)
    }

}

// MARK: Alerts

package extension LoginViaEmailViewModel {

    package struct Alert: Hashable, Identifiable, Sendable {
        package var id: Self { self }

        let title: String
        let message: String

        private typealias Title = L10n.Authentication.Error.Title
        private typealias Message = L10n.Authentication.Error.Message

        static let noInternet = Alert(title: Title.noInternet, message: Message.noInternet)
        static let invalidCredentials = Alert(title: Title.invalidCredentials, message: Message.invalidCredentials)
        static let accountPendingActivation = Alert(
            title: Title.accountPendingActivation,
            message: Message.accountPendingActivation
        )
        static let accountSuspended = Alert(title: Title.accountSuspended, message: Message.accountSuspended)
        static let unknownError = Alert(title: Title.general, message: Message.general)
    }

}
