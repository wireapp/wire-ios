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

import Combine
import Foundation
import SwiftUI
import WireAuthenticationAPI
import WireLogging

@MainActor
package final class DetermineAuthMethodViewModel: ObservableObject {

    package typealias Factory =
        DetermineAuthMethodUseCaseFactory &
        FetchBackendConfigUseCaseFactory &
        LoginViaSSOUseCaseFactory &
        ValidateEmailOrSSOCodeUseCaseFactory

    package enum ModalDestination: Hashable, Identifiable, Sendable {
        package var id: Self { self }

        case switchBackendConfirmation(
            email: String?,
            backendInfo: BackendInfo
        )
    }

    package var componentFactory: (any DetermineAuthMethodFactory)!
    private let router: any Router
    private let factory: any Factory
    private let bridge: WireAuthenticationBridge
    package let backendInfo: BackendInfo
    private var cancellable: AnyCancellable?

    @Published var emailOrSSOCode: String = ""
    @Published private(set) var isLoading = false
    @Published var alert: Alert?
    @Published var modalDestination: ModalDestination?
    @Published var existsAnotherAccount: Bool

    var isNextButtonEnabled: Bool {
        !isValidEmailOrSSOCode()
    }

    var isOnPremiseBackend: Bool {
        backendInfo.environmentType != .production
    }

    package init(
        router: any Router,
        factory: any Factory,
        bridge: WireAuthenticationBridge,
        backendInfo: BackendInfo,
        emailOrSSOCode: String = "",
        existsAnotherAccount: Bool,
        isLoading: Bool = false
    ) {
        self.router = router
        self.factory = factory
        self.bridge = bridge
        self.backendInfo = backendInfo
        self.emailOrSSOCode = emailOrSSOCode
        self.existsAnotherAccount = existsAnotherAccount
        self.isLoading = isLoading

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

            case ProxyModeError.proxyCredentialsRequired:
                // Login via email is the only place we ask from proxy credentials.
                router.navigate(
                    to: DetermineAuthMethodView.Destination.login(
                        email: nil,
                        didDetectDomainConflict: false,
                        backendInfo: backendInfo
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
            router.navigate(to: DetermineAuthMethodView.Destination.login(
                email: email,
                didDetectDomainConflict: didDetectDomainConflict,
                backendInfo: backendInfo
            ))

        case let .loginOrRegisterViaEmail(email):
            router.navigate(to: DetermineAuthMethodView.Destination.loginOrRegister(
                email: email,
                didDetectDomainConflict: false,
                backendInfo: backendInfo
            ))

        case let .loginViaSSO(code):
            do {
                let authResult = try await loginViaSSO(code: code, backendInfo: nil)
                router.navigate(to: DetermineAuthMethodView.Destination.noHistory(authResult))
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
        backendInfo: BackendInfo?
    ) async throws -> AuthenticationResult {
        let loginViaSSO = try await factory.loginViaSSOUseCase(backendInfo: backendInfo)
        return try await loginViaSSO.invoke(code: code)
    }

    private func handleOnPremLogin(
        email: String?,
        backendConfigURL: URL
    ) async {
        guard !existsAnotherAccount else {
            alert = .switchBackendFailed
            return
        }

        do {
            let useCase = factory.fetchBackendConfigUseCase()
            let backendConfig = try await Task.detached {
                try await useCase.invoke(at: backendConfigURL)
            }.value

            WireLogger.authentication.info("Fetching backend config succeeded")

            modalDestination = .switchBackendConfirmation(
                email: email,
                backendInfo: BackendInfo(
                    environmentType: .custom(url: backendConfigURL),
                    backendConfig: backendConfig
                )
            )
        } catch {
            WireLogger.authentication.error("Fetching backend config failed: \(error)")
            router.presentAlert(for: error)
        }
    }

    func switchBackend(
        email: String?,
        backendInfo: BackendInfo
    ) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let authResult = try await loginViaSSO(
                code: nil,
                backendInfo: backendInfo
            )
            router.navigate(to: DetermineAuthMethodView.Destination.noHistory(authResult))
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
                router.presentSheet(
                    RootView.ModalDestination.authFlow(backendInfo: backendInfo)
                )
            case let .authenticationFailed(samlError):
                WireLogger.authentication.error(
                    "sso authentication failed with SAML error: \(String(describing: samlError))"
                )
                alert = .ssoLoginFailed
            default:
                router.presentAlert(for: error)
            }
        } catch ProxyModeError.proxyCredentialsRequired {
            // Login via email is the only place we ask from proxy credentials.
            router.navigate(
                to: DetermineAuthMethodView.Destination.login(
                    email: email,
                    didDetectDomainConflict: false,
                    backendInfo: backendInfo
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
