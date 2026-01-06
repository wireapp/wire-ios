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
        !isValidEmailOrSSOCode()
    }

    var isOnPremiseBackend: Bool {
        environment.environmentType != .default
    }

    // MARK: - Dependencies

    package let factory: any Factory
    private let router: any Router
    private let bridge: WireAuthenticationBridge
    package let environment: BackendEnvironment2
    private var cancellable: AnyCancellable?
    private let isMultibackendEnabled: Bool

    // MARK: - Life cycle

    package init(
        factory: any Factory,
        router: any Router,
        bridge: WireAuthenticationBridge,
        environment: BackendEnvironment2,
        emailOrSSOCode: String = "",
        existsAnotherAccount: Bool,
        isLoading: Bool = false,
        isMultibackendEnabled: Bool
    ) {
        self.factory = factory
        self.router = router
        self.bridge = bridge
        self.environment = environment
        self.emailOrSSOCode = emailOrSSOCode
        self.existsAnotherAccount = existsAnotherAccount
        self.isLoading = isLoading
        self.isMultibackendEnabled = isMultibackendEnabled

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

        case let .loginViaSSO(code):
            do {
                let authResult = try await loginViaSSO(code: code, environment: nil)
                router.navigate(to: DetermineAuthMethodDestination.noHistory(authResult))
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

    private func handleOnPremLogin(
        email: String?,
        backendConfigURL: URL
    ) async {
        guard isMultibackendEnabled || !existsAnotherAccount else {
            alert = .switchBackendFailed
            return
        }

        do {
            let useCase = factory.fetchBackendConfigUseCase()
            let environment = try await Task.detached {
                try await useCase.invoke(at: backendConfigURL)
            }.value

            WireLogger.authentication.info("Fetching backend config succeeded")

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
            router.navigate(
                to: DetermineAuthMethodDestination.noHistory(authResult)
            )
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

    private func isValidEmailOrSSOCode() -> Bool {
        do {
            let useCase = factory.validateEmailOrSSOCodeUseCase()
            _ = try useCase.invoke(input: emailOrSSOCode.trimmingCharacters(in: .whitespaces))
            return true
        } catch {
            return false
        }
    }

}
