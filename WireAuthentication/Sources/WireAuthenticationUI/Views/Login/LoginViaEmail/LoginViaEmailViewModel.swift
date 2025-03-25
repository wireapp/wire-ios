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
        SubmitProxyCredentialsUseCaseFactory &
        LoginViaEmailUseCaseFactory &
        CreateAuthenticationResultUseCaseFactory

    @Published private(set) var isLoading = false
    @Published var alert: Alert?

    private let router: any Router
    private let factory: any Factory
    let backendInfo: BackendInfo

    private let onCreateAccount: () -> Void

    let email: String?
    let canCreateAccount: Bool
    let didDetectDomainConflict: Bool

    // MARK: - Life cycle

    package init(
        router: any Router,
        factory: any Factory,
        email: String?,
        backendInfo: BackendInfo,
        canCreateAccount: Bool,
        didDetectDomainConflict: Bool,
        onCreateAccount: @escaping () -> Void
    ) {
        self.router = router
        self.factory = factory
        self.email = email
        self.backendInfo = backendInfo
        self.canCreateAccount = canCreateAccount
        self.didDetectDomainConflict = didDetectDomainConflict
        self.onCreateAccount = onCreateAccount
    }

    private var forgotPasswordURL: URL {
        backendInfo.backendConfig.endpoints.accountsURL.appendingPathComponent("forgot")
    }

    var hasProxySupport: Bool {
        backendInfo.backendConfig.proxySettings != nil
    }

    var proxyServer: String {
        backendInfo.backendConfig.endpoints.backendURL.absoluteString
    }

    func isValidPassword(_ password: String) -> Bool {
        !password.isEmpty
    }

    var isValidEmail: Bool {
        guard let email else { return false }
        return !email.isEmpty
    }

    var isOnPremiseBackend: Bool {
        backendInfo.environmentType != .production
    }

    func submit(password: String, proxyCredentials: ProxyCredentials?) async {
        guard let email else { return }

        isLoading = true

        let sanitizedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            if let proxyCredentials {
                try submitProxyCredentials(proxyCredentials)
            }

            let (cookies, accessToken) = try await logIn(
                email: email,
                password: sanitizedPassword
            )

            WireLogger.authentication.info("Login via email succeeded")

            let emailCredentials = EmailCredentials(
                email: email,
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
                            email: email,
                            password: password
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
        UIApplication.shared.open(forgotPasswordURL)
    }

    func createAccount() {
        onCreateAccount()
    }

    func canSubmitPassword(password: String, proxyCredentials: ProxyCredentials) -> Bool {
        let validCredentials = isValidEmail && isValidPassword(password)

        guard hasProxySupport else {
            return validCredentials
        }

        let validProxyCredentials = !proxyCredentials.username.isEmpty && !proxyCredentials.password.isEmpty
        return validCredentials && validProxyCredentials
    }

    // MARK: - Private

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
