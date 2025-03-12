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
        LoginViaEmailUseCaseFactory &
        ResolveBackendMetadataUseCaseFactory

    @Published var password: String = "" {
        didSet { showPasswordRules = !isPasswordValid }
    }

    @Published private(set) var showPasswordRules = false
    @Published private(set) var isLoading = false
    @Published var alert: Alert?
    @Published var proxyUsername: String = ""
    @Published var proxyPassword: String = ""
    @Published var showCustomBackendAlert = false

    private let router: any Router
    private let factory: any Factory
    private let backendEnvironment: WireAuthenticationBackendEnvironment
    private let passwordValidator: any PasswordValidator
    private let backendConfig: BackendConfig
    private let backendMetadata: BackendMetadata?
    private let onCreateAccount: () -> Void

    let email: String
    let canCreateAccount: Bool
    let didDetectDomainConflict: Bool

    // MARK: - Life cycle

    package init(
        router: any Router,
        factory: any Factory,
        backendEnvironment: WireAuthenticationBackendEnvironment,
        email: String,
        backendConfig: BackendConfig,
        backendMetadata: BackendMetadata?,
        passwordValidator: any PasswordValidator,
        canCreateAccount: Bool,
        didDetectDomainConflict: Bool,
        onCreateAccount: @escaping () -> Void
    ) {
        self.router = router
        self.factory = factory
        self.backendEnvironment = backendEnvironment
        self.email = email
        self.backendConfig = backendConfig
        self.backendMetadata = backendMetadata
        self.passwordValidator = passwordValidator
        self.canCreateAccount = canCreateAccount
        self.didDetectDomainConflict = didDetectDomainConflict
        self.onCreateAccount = onCreateAccount
    }

    private var forgotPasswordURL: URL {
        backendConfig.endpoints.accountsURL.appendingPathComponent("forgot")
    }

    var backendName: String {
        backendConfig.title
    }

    var backendInfo: String {
        [
            L10n.OnPremUserLogin.Alert.Message.backendName,
            backendName,
            "",
            L10n.OnPremUserLogin.Alert.Message.backendUrl,
            backendConfig.endpoints.backendURL.absoluteString
        ].joined(separator: "\n")
    }

    var localizedPasswordRules: String? {
        passwordValidator.localizedRulesDescription
    }

    var requiresProxyCredentials: Bool {
        backendConfig.proxySettings?.needsAuthentication ?? false
    }

    var proxyServer: String {
        backendConfig.proxySettings?.host ?? ""
    }

    var isPasswordValid: Bool {
        passwordValidator.isPasswordValid(trimmedPassword)
    }

    var isProxyPasswordValid: Bool {
        // We don't know the individual password requirements for proxies so we just check for non-empty.
        !proxyPassword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isProxyUsernameValid: Bool {
        // We don't know the individual username requirements for proxies so we just check for non-empty.
        !proxyUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isSubmitButtonEnabled: Bool {
        if requiresProxyCredentials {
            isPasswordValid && isProxyPasswordValid && isProxyUsernameValid && !isLoading
        } else {
            isPasswordValid && !isLoading
        }
    }

    func submitPassword() async {
        isLoading = true
        defer { isLoading = false }

        let backendMetadata: BackendMetadata
        do {
            backendMetadata = try await resolveBackendMetadataIfNeeded()
        } catch {
            WireLogger.authentication.error("Resolving backend metadata failed: \(error)")

            switch error {
            case ResolveBackendMetadataUseCaseFailure.backendAPIVersionObsolete:
                // TODO: [WPB-16415] handle unresolved api version
            case ResolveBackendMetadataUseCaseFailure.clientVersionObsolete:
                // TODO: [WPB-16415] handle unresolved api version
            default:
                alert = .general(for: error)
            }
        }

        do {
            let (cookies, token) = try await login(backendMetadata: backendMetadata)

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
                    to: LoginViaEmailView.Destination.verifyLogin(email: email, password: password)
                )
            case LoginViaEmailUseCaseFailure.accountPendingActivation:
                alert = .accountPendingActivation
            case LoginViaEmailUseCaseFailure.accountSuspended:
                alert = .accountSuspended
            default:
                alert = .general(for: error)
            }
        }
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

    private func resolveBackendMetadataIfNeeded() async throws -> WireAuthenticationAPI.BackendMetadata {
        if let backendMetadata {
            return backendMetadata
        }

        let useCase = factory.resolveBackendMetadataUseCase()

        return try await Task.detached {
            try await useCase.invoke()
        }.value
    }

    private func login(backendMetadata: BackendMetadata) async throws -> ([HTTPCookie], AccessToken) {
        // FIXME: Pass in proxy username and password if necessary
        let useCase = factory.loginViaEmailUseCase(apiVersion: backendMetadata.apiVersion)

        return try await Task.detached { [email, trimmedPassword] in
            try await useCase.invoke(
                email: email,
                password: trimmedPassword,
                verificationCode: ""
            )
        }.value
    }

}
