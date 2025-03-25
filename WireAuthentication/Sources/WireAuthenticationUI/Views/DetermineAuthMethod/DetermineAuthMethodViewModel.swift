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
        FetchSSOURLUseCaseFactory &
        SSOLinkGeneratorFactory &
        ValidateEmailOrSSOCodeUseCaseFactory &
        CreateAuthenticationResultUseCaseFactory

    package enum ModalDestination: Hashable, Identifiable, Sendable {
        package var id: Self { self }

        case ssoLogin(url: URL)
        case switchBackendConfirmation(
            email: String?,
            environmentType: BackendEnvironmentType,
            backendConfig: BackendConfig
        )
    }

    private let router: any Router
    private let factory: any Factory
    private let bridge: WireAuthenticationBridge
    private var ssoLinkGenerator: (any SSOLinkGeneratorProtocol)?
    private let environmentType: BackendEnvironmentType
    package let backendConfig: BackendConfig
    private var cancellable: AnyCancellable?

    @Published var emailOrSSOCode: String = ""
    @Published private(set) var isLoading = false
    @Published var alert: Alert?
    @Published var modalDestination: ModalDestination?
    @Published var canExitFlow: Bool

    var isNextButtonEnabled: Bool {
        !isValidEmailOrSSOCode()
    }

    var isOnPremiseBackend: Bool {
        environmentType != .production
    }

    package init(
        router: any Router,
        factory: any Factory,
        bridge: WireAuthenticationBridge,
        environmentType: BackendEnvironmentType,
        backendConfig: BackendConfig,
        emailOrSSOCode: String = "",
        canExitFlow: Bool,
        isLoading: Bool = false
    ) {
        self.router = router
        self.factory = factory
        self.bridge = bridge
        self.environmentType = environmentType
        self.backendConfig = backendConfig
        self.emailOrSSOCode = emailOrSSOCode
        self.canExitFlow = canExitFlow
        self.isLoading = isLoading

        self.cancellable = bridge.inboundEvents.sink { event in
            switch event {
            case let .backendSwitchRequested(configURL):
                Task { [weak self] in
                    await self?.handleOnPremLogin(email: nil, backendConfigURL: configURL)
                }

            case let .ssoAuthenticationSuccess(userID, cookies):
                Task { [weak self] in
                    await self?.handleSSOSuccess(userID: userID, cookies: cookies)
                }

            case .ssoAutheticationFailure:
                router.presentAlert(Alert.ssoLoginFailed)

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
            default:
                router.presentAlert(for: error)
            }
        }
    }

    func onAlertDismiss() {
        ssoLinkGenerator?.flushToken()
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
                environmentType: environmentType,
                backendConfig: backendConfig
            ))

        case let .loginOrRegisterViaEmail(email):
            router.navigate(to: DetermineAuthMethodView.Destination.loginOrRegister(
                email: email,
                didDetectDomainConflict: false,
                environmentType: environmentType,
                backendConfig: backendConfig
            ))

        case let .loginViaSSO(code):
            do {
                let url = try await generateSSOLink(code: code)
                WireLogger.authentication.error("Generating SSO link succeeded")
                modalDestination = .ssoLogin(url: url)
            } catch {
                WireLogger.authentication.error("Generating SSO link failed: \(error)")
                switch error {
                case SSOLinkGeneratorFailure.invalidSSOCode:
                    alert = .incorrectSSOCode
                case SSOLinkGeneratorFailure.invalidSSOURL:
                    alert = .invalidSSOLink
                default:
                    router.presentAlert(for: error)
                }
            }

        case let .onPremLogin(email, backendConfigURL):
            await handleOnPremLogin(email: email, backendConfigURL: backendConfigURL)
        }
    }

    private func generateSSOLink(code: UUID) async throws -> URL {
        let linkGenerator = try await factory.ssoLinkGenerator()
        ssoLinkGenerator = linkGenerator
        return try await Task.detached {
            try await linkGenerator.generateSSOLink(ssoCode: code)
        }.value
    }

    private func handleOnPremLogin(
        email: String?,
        backendConfigURL: URL
    ) async {
        do {
            let useCase = factory.fetchBackendConfigUseCase()
            let backendConfig = try await Task.detached {
                try await useCase.invoke(at: backendConfigURL)
            }.value

            WireLogger.authentication.info("Fetching backend config succeeded")

            modalDestination = .switchBackendConfirmation(
                email: email,
                environmentType: .custom(url: backendConfigURL),
                backendConfig: backendConfig
            )
        } catch {
            WireLogger.authentication.error("Fetching backend config failed: \(error)")
            router.presentAlert(for: error)
        }
    }

    func switchBackend(
        email: String?,
        environmentType: BackendEnvironmentType,
        backendConfig: BackendConfig
    ) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let useCase = try await factory.fetchSSOURLUseCase(
                environmentType: environmentType,
                backendConfig: backendConfig
            )

            if let ssoURL = try await useCase.invoke() {
                modalDestination = .ssoLogin(url: ssoURL)
            } else if let email {
                router.navigate(
                    to: DetermineAuthMethodView.Destination.login(
                        email: email,
                        didDetectDomainConflict: false,
                        environmentType: environmentType,
                        backendConfig: backendConfig
                    )
                )
            } else {
                router.presentSheet(
                    RootView.ModalDestination.onPremiseAuthFlow(
                        environmentType: environmentType,
                        backendConfig: backendConfig
                    )
                )
            }
        } catch FetchSSOURLUseCaseError.proxyCredentialsRequired {
            // Login via email is the only place we ask from proxy credentials.
            router.navigate(
                to: DetermineAuthMethodView.Destination.login(
                    email: email,
                    didDetectDomainConflict: false,
                    environmentType: environmentType,
                    backendConfig: backendConfig
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

    private func handleSSOSuccess(
        userID: UUID,
        cookies: [HTTPCookie]
    ) async {
        do {
            let useCase = factory.createAuthenticationResultUseCase()
            let result = try await Task.detached {
                try await useCase.invoke(
                    userID: userID,
                    cookies: cookies,
                    accessToken: nil,
                    emailCredentials: nil
                )
            }.value
            router.navigate(to: DetermineAuthMethodView.Destination.noHistory(result))
        } catch {
            router.presentAlert(for: error)
        }
    }

}
