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

    package typealias Factory = LoginViaEmailUseCaseFactory

    @Published private(set) var isLoading = false
    @Published var alert: Alert?

    private let router: any Router
    private let factory: any Factory
    private let environmentType: BackendEnvironmentType
    package let backendConfig: BackendConfig

    // TODO: delete
    private let backendMetadata = BackendMetadata.dummy

    private let onCreateAccount: () -> Void

    let email: String?
    let canCreateAccount: Bool
    let didDetectDomainConflict: Bool

    // MARK: - Life cycle

    package init(
        router: any Router,
        factory: any Factory,
        email: String?,
        environmentType: BackendEnvironmentType,
        backendConfig: BackendConfig,
        canCreateAccount: Bool,
        didDetectDomainConflict: Bool,
        onCreateAccount: @escaping () -> Void
    ) {
        self.router = router
        self.factory = factory
        self.email = email
        self.environmentType = environmentType
        self.backendConfig = backendConfig
        self.canCreateAccount = canCreateAccount
        self.didDetectDomainConflict = didDetectDomainConflict
        self.onCreateAccount = onCreateAccount
    }

    private var forgotPasswordURL: URL {
        backendConfig.endpoints.accountsURL.appendingPathComponent("forgot")
    }

    var hasProxySupport: Bool {
        backendConfig.proxySettings != nil
    }

    var proxyServer: String {
        backendConfig.endpoints.backendURL.absoluteString
    }

    func isValidPassword(_ password: String) -> Bool {
        true
    }

    var isValidEmail: Bool {
        guard let email else { return false }
        return !email.isEmpty
    }

    var isOnPremiseBackend: Bool {
        environmentType != .production
    }

    func submitPassword(_ password: String) async {
        guard let email else { return }

        isLoading = true

        let sanitizedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
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

            let backendEnvironment = WireAuthenticationBackendEnvironment(
                environmentType: environmentType,
                config: backendConfig,
                metadata: backendMetadata
            )

            let authenticationResult = AuthenticationResult(
                userID: accessToken.userID,
                cookies: cookies,
                accessToken: accessToken,
                emailCredentials: emailCredentials,
                backendEnvironment: backendEnvironment
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

    // MARK: - Private

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

}

// TODO: delete
public extension BackendMetadata {

    static let dummy = BackendMetadata(
        apiVersion: .v8,
        domain: "dummy.com",
        isFederationEnabled: false
    )

}
