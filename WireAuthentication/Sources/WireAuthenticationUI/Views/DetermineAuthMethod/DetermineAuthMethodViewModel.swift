//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import Combine
import Foundation
import SwiftUI
import WireAuthenticationAPI
import WireLogging
import WireNetwork

@MainActor
package final class DetermineAuthMethodViewModel: ObservableObject {

    package typealias Factory =
        DetermineAuthMethodFactory &
        DetermineAuthMethodUseCaseFactory &
        FetchBackendConfigUseCaseFactory &
        LoginViaSSOUseCaseFactory &
        ValidateEmailOrSSOCodeUseCaseFactory

    // MARK: - View state

    @Published var emailOrSSOCode: String = ""
    @Published private(set) var isLoading = false
    @Published var alert: Alert?
    @Published var modalDestination: DetermineAuthMethodSheet?
    @Published var existsAnotherAccount: Bool

    var isNextButtonEnabled: Bool {
        if overrideAllowEmailLoginOnly {
            isValidEmail
        } else {
            isValidEmail || isValidSSOCode
        }
    }

    var isOnPremiseBackend: Bool {
        environment.environmentType != .default
    }

    let overrideAllowEmailLoginOnly: Bool

    // MARK: - Dependencies

    package let factory: any Factory
    private let router: any Router
    private let bridge: WireAuthenticationBridge
    package let environment: BackendEnvironment2

    /// Whether accounts from more than one backend can be added in the same app.
    private let allowsMultipleBackends: Bool

    /// The `restAPIURL` hosts of the accounts already logged in on this device.
    private let existingBackendHosts: Set<String>
    private let isAccountAlreadyLoggedIn: (AuthenticationResult) -> Bool

    private var cancellable: AnyCancellable?

    // MARK: - Life cycle

    package init(
        factory: any Factory,
        router: any Router,
        bridge: WireAuthenticationBridge,
        environment: BackendEnvironment2,
        emailOrSSOCode: String = "",
        existsAnotherAccount: Bool,
        allowsMultipleBackends: Bool,
        existingBackendHosts: Set<String>,
        isLoading: Bool = false,
        isAccountAlreadyLoggedIn: @escaping (AuthenticationResult) -> Bool = { _ in false },
        overrideAllowEmailLoginOnly: Bool
    ) {
        self.factory = factory
        self.router = router
        self.bridge = bridge
        self.environment = environment
        self.emailOrSSOCode = emailOrSSOCode
        self.existsAnotherAccount = existsAnotherAccount
        self.allowsMultipleBackends = allowsMultipleBackends
        self.existingBackendHosts = existingBackendHosts
        self.isLoading = isLoading
        self.isAccountAlreadyLoggedIn = isAccountAlreadyLoggedIn
        self.overrideAllowEmailLoginOnly = overrideAllowEmailLoginOnly

        self.cancellable = bridge.inboundEvents.sink { [weak self] event in
            switch event {
            case let .backendSwitchRequested(configURL):
                Task { [weak self] in
                    await self?.handleOnPremLogin(email: nil, backendConfigURL: configURL)
                }
            case let .updateAnotherAccountExistence(newValue):
                self?.existsAnotherAccount = newValue
            default:
                break
            }
        }
    }

    // MARK: - Actions

    func submitEmailOrSSOCode() async {
        isLoading = true
        defer {
            isLoading = false
        }

        // When only email login is allowed, validate the input as an email before
        // navigating to the login flow. An SSO code or otherwise invalid input is ignored
        // (the submit button is also disabled for it).
        if overrideAllowEmailLoginOnly {
            guard let validatedEmail else { return }
            router.navigate(to: DetermineAuthMethodDestination.login(
                email: validatedEmail,
                didDetectDomainConflict: false,
                environment: environment
            ))
            return
        }

        do {
            let useCase = try await factory.determineAuthMethodUseCase()
            let authMethod = try await Task.detached { [useCase, emailOrSSOCode] in
                try await useCase.invoke(emailOrSSOCode: emailOrSSOCode)
            }.value

            await handleAuthenticationMethod(authMethod)
        } catch {
            WireLogger.authentication.error("Error determining authentication method: \(error)")

            switch error {
            case DetermineAuthMethodUseCaseFailure.invalidEmailOrSSOCode:
                // No need to do anything here. In general this shouldn't happen because we validate before submitting.
                // It is probably worth restructuring the code to avoid this.
                break

            case NetworkStackError.proxyCredentialsRequired:
                // Login via email is the only place we ask from proxy credentials.
                router.navigate(
                    to: DetermineAuthMethodDestination.login(
                        email: nil,
                        didDetectDomainConflict: false,
                        environment: environment
                    )
                )

            default:
                router.presentAlert(for: error)
            }
        }
    }

    func onAlertDismiss() {
        modalDestination = nil
    }

    func exitFlow() {
        bridge.sendOutboundEvent(.exitFlowRequested)
    }

    // MARK: - Private

    private func handleAuthenticationMethod(
        _ method: AuthenticationMethod
    ) async {
        // On-prem login resolves and checks its own target backend in `handleOnPremLogin`.
        // Every other method authenticates against the current flow environment, so block it
        // here when multibackend support is disabled and that backend differs from the one
        // already in use.
        if case .onPremLogin = method {
            // handled below in handleOnPremLogin
        } else if isBackendBlockedByMultibackendPolicy(environment) {
            WireLogger.authentication.info("Blocking login: multibackend support disabled")
            alert = .switchBackendBlocked
            return
        }

        switch method {
        case let .loginViaEmail(email, didDetectDomainConflict):
            router.navigate(to: DetermineAuthMethodDestination.login(
                email: email,
                didDetectDomainConflict: didDetectDomainConflict,
                environment: environment
            ))

        case let .loginOrRegisterViaEmail(email):
            router.navigate(to: DetermineAuthMethodDestination.loginOrRegister(
                email: email,
                didDetectDomainConflict: false,
                environment: environment
            ))

        case let .loginViaSSO(code, multiIngressIdentityProviderID):
            do {
                var authResult = try await loginViaSSO(code: code, environment: nil)
                authResult.multiIngressIdentityProviderID = multiIngressIdentityProviderID
                if isAccountAlreadyLoggedIn(authResult) {
                    alert = .alreadyLoggedIn
                } else {
                    router.navigate(to: DetermineAuthMethodDestination.noHistory(authResult))
                }
            } catch let error as LoginViaSSOUseCaseError {
                switch error {
                case .invalidCode:
                    alert = .incorrectSSOCode
                case .invalidURL:
                    alert = .invalidSSOLink
                case .userCancelled:
                    // no op
                    break
                case .noDefaultCodeAvailable:
                    // This shouldn't happen because we should be providing an sso code.
                    break
                case let .authenticationFailed(samlError):
                    WireLogger.authentication.error(
                        "sso authentication failed with SAML error: \(String(describing: samlError))"
                    )
                    alert = .ssoLoginFailed
                default:
                    router.presentAlert(for: error)
                }
            } catch {
                router.presentAlert(for: error)
            }

        case let .onPremLogin(email, backendConfigURL):
            await handleOnPremLogin(email: email, backendConfigURL: backendConfigURL)
        }
    }

    private func loginViaSSO(
        code: UUID?,
        environment: BackendEnvironment2?
    ) async throws -> AuthenticationResult {
        let loginViaSSO = try await factory.loginViaSSOUseCase(environment: environment)
        return try await loginViaSSO.invoke(code: code)
    }

    /// Whether the given backend may not be used because multibackend support is disabled and
    /// an account already exists on a different backend.
    ///
    /// Returns `false` when multibackend support is enabled, when no other account exists yet
    /// (switching the single backend is allowed), or when the backend matches one already in use.
    private func isBackendBlockedByMultibackendPolicy(_ backend: BackendEnvironment2) -> Bool {
        guard !allowsMultipleBackends, !existingBackendHosts.isEmpty else {
            return false
        }
        guard let host = backend.config.endpoints.restAPIURL.host() else {
            return false
        }
        return !existingBackendHosts.contains(host)
    }

    private func handleOnPremLogin(
        email: String?,
        backendConfigURL: URL
    ) async {
        do {
            let useCase = factory.fetchBackendConfigUseCase()
            let environment = try await Task.detached {
                try await useCase.invoke(at: backendConfigURL)
            }.value

            WireLogger.authentication.info("Fetching backend config succeeded")

            if isBackendBlockedByMultibackendPolicy(environment) {
                WireLogger.authentication.info("Blocking backend switch: multibackend support disabled")
                alert = .switchBackendBlocked
                return
            }

            modalDestination = .switchBackendConfirmation(
                email: email,
                environment: environment
            )
        } catch {
            WireLogger.authentication.error("Fetching backend config failed: \(error)")
            router.presentAlert(for: error)
        }
    }

    func switchBackend(
        email: String?,
        environment: BackendEnvironment2
    ) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let authResult = try await loginViaSSO(
                code: nil,
                environment: environment
            )
            if isAccountAlreadyLoggedIn(authResult) {
                alert = .alreadyLoggedIn
            } else {
                router.navigate(to: DetermineAuthMethodDestination.noHistory(authResult))
            }
        } catch let error as LoginViaSSOUseCaseError {
            switch error {
            case .invalidCode:
                alert = .incorrectSSOCode
            case .invalidURL:
                alert = .invalidSSOLink
            case .userCancelled:
                // No op
                break
            case .noDefaultCodeAvailable:
                router.popToRoot() // clear the navigation stack before replacing root
                router.presentSheet(.authFlow(environment: environment))
            case let .authenticationFailed(samlError):
                WireLogger.authentication.error(
                    "sso authentication failed with SAML error: \(String(describing: samlError))"
                )
                alert = .ssoLoginFailed
            default:
                router.presentAlert(for: error)
            }
        } catch NetworkStackError.proxyCredentialsRequired {
            // Login via email is the only place we ask from proxy credentials.
            router.navigate(
                to: DetermineAuthMethodDestination.login(
                    email: email,
                    didDetectDomainConflict: false,
                    environment: environment
                )
            )
        } catch {
            router.presentAlert(for: error)
        }
    }

    private var isValidEmail: Bool {
        validatedEmail != nil
    }

    /// The trimmed, validated email entered by the user, or `nil` if the input is not a valid email.
    private var validatedEmail: String? {
        guard case let .email(email, _) = try? validateEmailOrSSOCode() else {
            return nil
        }
        return email
    }

    private var isValidSSOCode: Bool {
        do {
            if case .ssoCode = try validateEmailOrSSOCode() {
                return true
            } else {
                return false
            }
        } catch {
            return false
        }
    }

    private func validateEmailOrSSOCode() throws -> ValidatedEmailOrSSOCode {
        let useCase = factory.validateEmailOrSSOCodeUseCase()
        return try useCase.invoke(input: emailOrSSOCode.trimmingCharacters(in: .whitespaces))
    }

}
