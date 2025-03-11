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
import WireReusableUIComponents

@MainActor
package final class LoginViaEmailOnPremViewModel: ObservableObject {

    package typealias Factory =
        LoginViaEmailUseCaseFactory &
        ResolveBackendMetadataUseCaseFactory

    private let router: any Router
    private let factory: any Factory
    private let passwordValidator: any PasswordValidator
    private let backendConfig: BackendConfig
    private let backendMetadata: WireAuthenticationAPI.BackendMetadata?

    let email: String
    let canCreateAccount: Bool

    // MARK: - Life cycle

    package init(
        router: any Router,
        factory: any Factory,
        email: String,
        backendConfig: BackendConfig,
        backendMetadata: WireAuthenticationAPI.BackendMetadata?,
        passwordValidator: any PasswordValidator,
        canCreateAccount: Bool
    ) {
        self.router = router
        self.factory = factory
        self.email = email
        self.passwordValidator = passwordValidator
        self.canCreateAccount = canCreateAccount
        self.backendConfig = backendConfig
        self.backendMetadata = backendMetadata
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

    var hasProxySupport: Bool {
        backendConfig.proxySettings != nil
    }

    var proxyServer: String {
        backendConfig.endpoints.backendURL.absoluteString
    }

    func isValidPassword(_ password: String) -> Bool {
        passwordValidator.isPasswordValid(password)
    }

    func submitPassword(_ password: String) async {
        let backendMetadata: WireAuthenticationAPI.BackendMetadata
        do {
            backendMetadata = try await resolveBackendMetadataIfNeeded()
        } catch {
            // TODO: [WPB-16415] handle unresolved api version
            fatalError()
        }

        let (cookies, accessToken): ([HTTPCookie], AccessToken)
        do {
            (cookies, accessToken) = try await login(
                password: password,
                backendMetadata: backendMetadata
            )
        } catch {
            // TODO: [WPB-15944] Error handling
            fatalError("error: \(error)")
        }

        let emailCredentials = EmailCredentials(
            email: email,
            password: password,
            verificationCode: nil
        )

        let backendEnvironment = WireAuthenticationBackendEnvironment(
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

        router.navigate(to: RootView.ModalDestination.noHistory(
            authenticationResult: authenticationResult,
            didDetectDomainConflict: false
        ))
    }

    func recoverPassword() {
        UIApplication.shared.open(forgotPasswordURL)
    }

    func createAccount() {
        // TODO: [WPB-15926] Initiate account registration flow
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

    private func login(
        password: String,
        backendMetadata: BackendMetadata
    ) async throws -> ([HTTPCookie], AccessToken) {
        let useCase = factory.loginViaEmailUseCase(apiVersion: backendMetadata.apiVersion)

        return try await Task.detached { [email] in
            try await useCase.invoke(
                email: email,
                password: password,
                verificationCode: ""
            )
        }.value
    }

}
