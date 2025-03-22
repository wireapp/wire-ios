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

package protocol DetermineAuthMethodUseCaseFactory2 {

    func determineAuthMethodUseCase() async throws -> any DetermineAuthMethodUseCaseProtocol

}

@MainActor
package final class DetermineAuthMethodViewModel: ObservableObject {

    package typealias Factory =
        DetermineAuthMethodUseCaseFactory &
        DetermineAuthMethodUseCaseFactory2 &
        FetchBackendConfigUseCaseFactory &
        OpenAppStoreUseCaseFactory &
        ResolveBackendMetadataUseCaseFactory &
        SSOLinkGeneratorFactory &
        ValidateEmailOrSSOCodeUseCaseFactory

    package enum ModalDestination: Hashable, Identifiable, Sendable {
        package var id: Self { self }

        case ssoLogin(url: URL, backendEnvironment: WireAuthenticationBackendEnvironment)
        case switchBackend(email: String?, environmentType: BackendEnvironmentType, backendConfig: BackendConfig)
    }

    private let router: any Router
    private let factory: any Factory
    private let bridge: WireAuthenticationBridge
    private var ssoLinkGenerator: (any SSOLinkGeneratorProtocol)?
    private let environmentType: BackendEnvironmentType
    private let backendMetadata: BackendMetadata?
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
        backendMetadata: BackendMetadata?,
        emailOrSSOCode: String = "",
        canExitFlow: Bool,
        isLoading: Bool = false
    ) {
        self.router = router
        self.factory = factory
        self.bridge = bridge
        self.environmentType = environmentType
        self.backendMetadata = backendMetadata
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
                // TODO: delete this temp hack
                let backendEnvironment = WireAuthenticationBackendEnvironment(
                    environmentType: .production,
                    config: BackendConfig(
                        title: "example",
                        endpoints: Endpoints(
                            backendURL: URL(string: "")!,
                            backendWSURL: URL(string: "")!,
                            blackListURL: URL(string: "")!,
                            teamsURL: URL(string: "")!,
                            accountsURL: URL(string: "")!,
                            websiteURL: URL(string: "")!,
                            countlyURL: nil
                        ),
                        proxySettings: nil,
                        pinnedKeys: nil
                    ),
                    metadata: .init(
                        apiVersion: .v8,
                        domain: "example",
                        isFederationEnabled: false
                    )
                )
                let authenticationResult = AuthenticationResult(
                    userID: userID,
                    cookies: cookies,
                    accessToken: nil,
                    emailCredentials: nil,
                    backendEnvironment: backendEnvironment
                )

                router.navigate(to: DetermineAuthMethodView.Destination.noHistory(authenticationResult))

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
            case ResolveBackendMetadataUseCaseFailure.clientVersionObsolete:
                // TODO: this should probably be an alert on the root view
                alert = .obsoleteClient
            case ResolveBackendMetadataUseCaseFailure.backendAPIVersionObsolete:
                // TODO: this should probably be an alert on the root view
                alert = .obsoleteBackend
            default:
                alert = .general(for: error)
            }
        }
    }

    func onAlertDismiss() {
        ssoLinkGenerator?.flushToken()
        modalDestination = nil
    }

    func goToAppStore() {
        factory.openAppStoreUseCase().invoke()
        alert = nil
    }

    func exitFlow() {
        bridge.sendOutboundEvent(.exitFlowRequested)
    }

    // MARK: - Private

    private func handleAuthenticationMethod(
        _ method: AuthenticationMethod
    ) async {
        // TODO: remove this temp fix
        let backendMetadata = BackendMetadata(
            apiVersion: .v8,
            domain: "example.com",
            isFederationEnabled: false
        )
        switch method {
        case let .loginViaEmail(email, didDetectDomainConflict):
            router.navigate(to: DetermineAuthMethodView.Destination.login(
                email: email,
                didDetectDomainConflict: didDetectDomainConflict,
                environmentType: environmentType,
                backendConfig: backendConfig,
                backendMetadata: backendMetadata
            ))

        case let .loginOrRegisterViaEmail(email):
            router.navigate(to: DetermineAuthMethodView.Destination.loginOrRegister(
                email: email,
                environmentType: environmentType,
                backendConfig: backendConfig,
                backendMetadata: backendMetadata
            ))

        case let .loginViaSSO(code):
            let generator = factory.ssoLinkGenerator(apiVersion: backendMetadata.apiVersion)
            ssoLinkGenerator = generator

            do {
                let url = try await Task.detached { [generator] in
                    try await generator.generateSSOLink(ssoCode: code)
                }.value
                WireLogger.authentication.error("Generating SSO link succeeded")

                let backendEnvironment = WireAuthenticationBackendEnvironment(
                    environmentType: environmentType,
                    config: backendConfig,
                    metadata: backendMetadata
                )

                modalDestination = .ssoLogin(
                    url: url,
                    backendEnvironment: backendEnvironment
                )
            } catch {
                WireLogger.authentication.error("Generating SSO link failed: \(error)")

                switch error {
                case SSOLinkGeneratorFailure.invalidSSOCode:
                    alert = .incorrectSSOCode
                case SSOLinkGeneratorFailure.invalidSSOURL:
                    alert = .invalidSSOLink
                default:
                    alert = .general(for: error)
                }
            }

        case let .onPremLogin(email, backendConfigURL):
            await handleOnPremLogin(email: email, backendConfigURL: backendConfigURL)
        }
    }

    private func handleOnPremLogin(email: String?, backendConfigURL: URL) async {
        Task {
            do {
                let useCase = factory.fetchBackendConfigUseCase()
                let backendConfig = try await Task.detached {
                    try await useCase.invoke(at: backendConfigURL)
                }.value

                WireLogger.authentication.info("Fetching backend config succeeded")

                modalDestination = .switchBackend(
                    email: email,
                    environmentType: .custom(url: backendConfigURL),
                    backendConfig: backendConfig
                )
            } catch {
                WireLogger.authentication.error("Fetching backend config failed: \(error)")

                alert = .general(for: error)
            }
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
