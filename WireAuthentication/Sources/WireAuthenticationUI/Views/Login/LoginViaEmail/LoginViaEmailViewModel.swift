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

    package typealias Factory =
        LoginViaEmailFactory &
        CreateAuthenticationResultUseCaseFactory &
        LoginViaEmailUseCaseFactory &
        SubmitProxyCredentialsUseCaseFactory &
        ValidateEmailUseCaseFactory

    // MARK: - View state

    @Published var email: String
    @Published var password: String = ""

    @Published var proxyUsername: String = ""
    @Published var proxyPassword: String = ""

    @Published private(set) var isLoading = false
    @Published var alert: Alert?

    let backendInfo: BackendInfo
    let isEmailPrefilled: Bool
    let canCreateAccount: Bool

    var areProxyCredentialsRequired: Bool {
        backendInfo.backendConfig.proxySettings?.needsAuthentication == true
    }

    var proxyServer: String {
        backendInfo.backendConfig.endpoints.backendURL.absoluteString
    }

    func isPasswordValid(_ password: String) -> Bool {
        !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isOnPremiseBackend: Bool {
        backendInfo.environmentType != .production
    }

    var canSubmitCredentials: Bool {
        if areProxyCredentialsRequired {
            areAccountCredentialsValid && areProxyCredentialsValid
        } else {
            areAccountCredentialsValid
        }
    }

    // MARK: - Dependencies

    package let factory: any Factory
    private let router: any Router
    private let onCreateAccount: () -> Void
    private let didDetectDomainConflict: Bool

    // MARK: - Life cycle

    package init(
        factory: any Factory,
        router: any Router,
        email: String?,
        backendInfo: BackendInfo,
        canCreateAccount: Bool,
        didDetectDomainConflict: Bool,
        onCreateAccount: @escaping () -> Void
    ) {
        self.factory = factory
        self.router = router
        self.email = email ?? ""
        self.backendInfo = backendInfo
        self.canCreateAccount = canCreateAccount
        self.didDetectDomainConflict = didDetectDomainConflict
        self.isEmailPrefilled = email != nil
        self.onCreateAccount = onCreateAccount
    }

    // MARK: - Actions

    func submitCredentials() async {
        isLoading = true

        let sanitizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            if let proxyCredentials {
                try submitProxyCredentials(proxyCredentials)
            }

            let (cookies, accessToken) = try await logIn(
                email: sanitizedEmail,
                password: sanitizedPassword
            )

            WireLogger.authentication.info("Login via email succeeded")

            let emailCredentials = EmailCredentials(
                email: sanitizedEmail,
                password: sanitizedPassword,
                verificationCode: nil
            )

            let authenticationResult = try await createAuthenticationResult(
                cookies: cookies,
                accessToken: accessToken,
                emailCredentials: emailCredentials
            )

            router.navigate(
                to: LoginViaEmailView.Destination.noHistory(authenticationResult: authenticationResult)
            )

        } catch {
            WireLogger.authentication.error("Login via email failed: \(error)")

            switch error {
            case LoginViaEmailUseCaseFailure.invalidCredentials:
                alert = .invalidCredentials
            case LoginViaEmailUseCaseFailure.twoFactorAuthenticationRequired:
                router.navigate(
                    to: LoginViaEmailView.Destination
                        .verifyLogin(
                            email: sanitizedEmail,
                            password: sanitizedPassword,
                            proxyCredentials: proxyCredentials
                        )
                )
            case LoginViaEmailUseCaseFailure.accountPendingActivation:
                alert = .accountPendingActivation
            case LoginViaEmailUseCaseFailure.accountSuspended:
                alert = .accountSuspended
            default:
                router.presentAlert(for: error)
            }
        }

        isLoading = false
    }

    func recoverPassword() {
        UIApplication.shared.open(
            backendInfo.backendConfig.endpoints.accountsURL.appendingPathComponent("forgot")
        )
    }

    func createAccount() {
        onCreateAccount()
    }

    // MARK: - Private

    private var proxyCredentials: ProxyCredentials? {
        guard areProxyCredentialsRequired else {
            return nil
        }

        return ProxyCredentials(
            username: proxyUsername.trimmingCharacters(in: .whitespacesAndNewlines),
            password: proxyPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    private var areAccountCredentialsValid: Bool {
        let isEmailValid = factory.validateEmailUseCase().invoke(email: email) == .isValid
        let isPasswordValid = isPasswordValid(password)
        return isEmailValid && isPasswordValid
    }

    private var areProxyCredentialsValid: Bool {
        let isUsernameValid = !proxyUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let isPasswordValid = isPasswordValid(proxyPassword)
        return isUsernameValid && isPasswordValid
    }

    private func submitProxyCredentials(_ proxyCredentials: ProxyCredentials) throws {
        let useCase = factory.submitProxyCredentialsUseCase()
        try useCase.invoke(proxyCredentials: proxyCredentials)
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

    private func createAuthenticationResult(
        cookies: [HTTPCookie],
        accessToken: AccessToken,
        emailCredentials: EmailCredentials
    ) async throws -> AuthenticationResult {
        let useCase = factory.createAuthenticationResultUseCase()
        return try await Task.detached {
            try await useCase.invoke(
                userID: accessToken.userID,
                cookies: cookies,
                accessToken: accessToken,
                emailCredentials: emailCredentials
            )
        }.value
    }

}
