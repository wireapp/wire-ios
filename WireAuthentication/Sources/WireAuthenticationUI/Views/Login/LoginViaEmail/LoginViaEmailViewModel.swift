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

    package typealias Factory = LoginViaEmailUseCaseFactory2

    @Published var password: String = "" {
        didSet { showPasswordRules = !isPasswordValid }
    }

    @Published private(set) var showPasswordRules = false
    @Published private(set) var isLoading = false
    @Published var alert: Alert?

    private let router: any Router
    private let factory: any Factory
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
        factory: any Factory,
        loginViaEmailUseCase: any LoginViaEmailUseCaseProtocol,
        backendEnvironment: WireAuthenticationBackendEnvironment,
        email: String,
        passwordValidator: any PasswordValidator,
        canCreateAccount: Bool,
        didDetectDomainConflict: Bool,
        onCreateAccount: @escaping () -> Void
    ) {
        self.router = router
        self.factory = factory
        self.loginViaEmailUseCase = loginViaEmailUseCase
        self.backendEnvironment = backendEnvironment
        self.email = email
        self.forgotPasswordURL = backendEnvironment.config.endpoints.accountsURL.appendingPathComponent("forgot")
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

        do {
            let (cookies, token) = try await logIn(
                email: email,
                password: trimmedPassword
            )

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

            WireLogger.authentication.error("Login via email succeeded")

            router.presentSheet(
                RootView.ModalDestination.noHistory(
                    authenticationResult: authenticationResult,
                    didDetectDomainConflict: didDetectDomainConflict
                )
            )
        } catch {
            WireLogger.authentication.error("Login via email failed: \(error)")

            switch error {
            case LoginViaEmailUseCaseFailure.invalidCredentials:
                alert = .invalidCredentials
            case LoginViaEmailUseCaseFailure.twoFactorAuthenticationRequired:
                router.navigate(
                    to: LoginViaEmailView.Destination.verifyLogin(password: password)
                )
            case LoginViaEmailUseCaseFailure.accountPendingActivation:
                alert = .accountPendingActivation
            case LoginViaEmailUseCaseFailure.accountSuspended:
                alert = .accountSuspended
            default:
                // TODO: handle api version errors
                alert = .general(for: error)
            }
        }

        isLoading = false
    }

    private func logIn(
        email: String,
        password: String
    ) async throws -> ([HTTPCookie], AccessToken) {
        let useCase = try await factory.loginViaEmailUseCase()
        return try await Task.detached {
            try await useCase.invoke(
                email: email,
                password: password,
                verificationCode: nil
            )
        }.value
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
