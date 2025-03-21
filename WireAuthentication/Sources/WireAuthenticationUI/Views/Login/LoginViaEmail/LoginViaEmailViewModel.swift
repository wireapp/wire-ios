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
        OpenAppStoreUseCaseFactory &
        ResolveBackendMetadataUseCaseFactory

    @Published private(set) var isLoading = false
    @Published var alert: Alert?

    private let router: any Router
    private let factory: any Factory
    private let environmentType: BackendEnvironmentType
    package let backendConfig: BackendConfig
    private let backendMetadata: BackendMetadata
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
        backendMetadata: BackendMetadata,
        canCreateAccount: Bool,
        didDetectDomainConflict: Bool,
        onCreateAccount: @escaping () -> Void
    ) {
        self.router = router
        self.factory = factory
        self.email = email
        self.environmentType = environmentType
        self.backendConfig = backendConfig
        self.backendMetadata = backendMetadata
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
        let backendMetadata: WireAuthenticationAPI.BackendMetadata
        do {
            backendMetadata = try await resolveBackendMetadataIfNeeded()
        } catch ResolveBackendMetadataUseCaseFailure.clientVersionObsolete {
            alert = .obsoleteClient
            return
        } catch ResolveBackendMetadataUseCaseFailure.backendAPIVersionObsolete {
            alert = .obsoleteBackend
            return
        } catch {
            alert = .general(for: error)
            return
        }

        let (cookies, accessToken): ([HTTPCookie], AccessToken)
        do {
            (cookies, accessToken) = try await login(
                email: email,
                password: password,
                backendMetadata: backendMetadata
            )
            WireLogger.authentication.info("Login via email succeeded")

            let emailCredentials = EmailCredentials(
                email: email,
                password: password,
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

            router.presentSheet(RootView.ModalDestination.noHistory(
                authenticationResult: authenticationResult,
                didDetectDomainConflict: false
            ))

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

        isLoading = false
    }

    func recoverPassword() {
        UIApplication.shared.open(forgotPasswordURL)
    }

    func goToAppStore() {
        factory.openAppStoreUseCase().invoke()
        alert = nil
    }

    func createAccount() {
        onCreateAccount()
    }

    // MARK: - Private

    private func resolveBackendMetadataIfNeeded() async throws -> BackendMetadata {
        let useCase = factory.resolveBackendMetadataUseCase()

        return try await Task.detached {
            try await useCase.invoke()
        }.value
    }

    private func login(
        email: String,
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
