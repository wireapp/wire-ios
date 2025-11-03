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
import WireLegacyLogging
import WireNetwork
import WireReusableUIComponents

@MainActor
package final class ReloginViaEmailViewModel: ObservableObject {

    package typealias Factory =
        CreateAuthenticationResultUseCaseFactory &
        LoginViaEmailUseCaseFactory &
        ReloginViaEmailFactory &
        SubmitProxyCredentialsUseCaseFactory &
        ValidateEmailUseCaseFactory

    // MARK: - View state

    @Published var password: String = ""

    @Published var proxyUsername: String = ""
    @Published var proxyPassword: String = ""

    @Published var existsAnotherAccount: Bool

    @Published private(set) var isLoading = false
    @Published var alert: Alert?
    @Published var onSheetDismissAction: (() -> Void)?

    let email: String
    let environment: BackendEnvironment2

    var areProxyCredentialsRequired: Bool {
        environment.config.proxyConfig?.needsAuthentication == true
    }

    var proxyServer: String? {
        environment.config.proxyConfig?.host
    }

    func isPasswordValid(_ password: String) -> Bool {
        !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isOnPremiseBackend: Bool {
        environment.environmentType != .default
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
    private let bridge: WireAuthenticationBridge

    // MARK: - Life cycle

    package init(
        factory: any Factory,
        router: any Router,
        bridge: WireAuthenticationBridge,
        email: String,
        environment: BackendEnvironment2,
        existsAnotherAccount: Bool
    ) {
        self.factory = factory
        self.router = router
        self.bridge = bridge
        self.email = email
        self.environment = environment
        self.existsAnotherAccount = existsAnotherAccount
    }

    // MARK: - Actions

    func submitCredentials() async {
        isLoading = true

        let sanitizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            if let proxyCredentials {
                try await submitProxyCredentials(proxyCredentials)
            }

            let (cookies, accessToken) = try await logIn(
                email: sanitizedEmail,
                password: sanitizedPassword
            )

            WireLogger.authentication.info("Relogin via email succeeded")

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
                to: ReloginViaEmailDestination.noHistory(authenticationResult: authenticationResult)
            )

        } catch {
            WireLogger.authentication.error("Relogin via email failed: \(error)")

            switch error {
            case LoginViaEmailUseCaseFailure.invalidCredentials:
                alert = .invalidCredentials
            case LoginViaEmailUseCaseFailure.twoFactorAuthenticationRequired:
                router.navigate(
                    to: ReloginViaEmailDestination
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
            environment.config.endpoints.accountsURL.appendingPathComponent("forgot")
        )
    }

    func logout() {
        router.presentAlert(.logoutConfirmation)
    }

    func exitFlow() {
        bridge.sendOutboundEvent(.exitFlowRequested)
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

    private func submitProxyCredentials(_ proxyCredentials: ProxyCredentials) async throws {
        let useCase = factory.submitProxyCredentialsUseCase()
        try await useCase.invoke(proxyCredentials: proxyCredentials)
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
