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
        ResolveBackendMetadataUseCaseFactory &
        SSOLinkGeneratorFactory &
        ValidateEmailOrSSOCodeUseCaseFactory

    package enum ModalDestination: Hashable, Identifiable, Sendable {
        package var id: Self { self }

        case ssoLogin(url: URL)
        case switchBackend(email: String, backendConfig: BackendConfig)
    }

    private let router: any Router
    private let factory: any Factory
    private var ssoLinkGenerator: (any SSOLinkGeneratorProtocol)?

    @Published var emailOrSSOCode: String = ""
    @Published private(set) var isLoading = false
    @Published var alert: Alert?
    @Published var modalDestination: ModalDestination?

    var isNextButtonEnabled: Bool {
        !isValidEmailOrSSOCode()
    }

    package init(
        router: any Router,
        factory: any Factory,
        emailOrSSOCode: String = "",
        isLoading: Bool = false
    ) {
        self.router = router
        self.factory = factory
        self.emailOrSSOCode = emailOrSSOCode
        self.isLoading = isLoading
    }

    func submitEmailOrSSOCode() async {
        isLoading = true
        defer {
            isLoading = false
        }

        let backendMetadata: BackendMetadata
        do {
            let useCase = factory.resolveBackendMetadataUseCase()
            backendMetadata = try await Task.detached { [useCase] in
                try await useCase.invoke()
            }.value
        } catch {
            // TODO: [WPB-16415] report via bridge that API version can't be resolved.
            fatalError()
        }

        do {
            let useCase = factory.determineAuthMethodUseCase(apiVersion: backendMetadata.apiVersion)
            let authMethod = try await Task.detached { [useCase, emailOrSSOCode] in
                try await useCase.invoke(emailOrSSOCode: emailOrSSOCode)
            }.value

            await handleAuthenticationMethod(
                authMethod,
                backendMetadata: backendMetadata
            )
        } catch {
            WireLogger.authentication.error("Error determining authentication method: \(error)")

            switch error {
            case DetermineAuthMethodUseCaseFailure.invalidEmailOrSSOCode:
                // No need to do anything here. In general this shouldn't happen because we validate before submitting.
                // It is probably worth restructuring the code to avoid this.
                break
            default:
                alert = .general(for: error)
            }
        }
    }

    func dismissmodalView() {
        // FIXME: This is not called
        ssoLinkGenerator?.flushToken()
        modalDestination = nil
    }

    // MARK: - Private

    private func handleAuthenticationMethod(
        _ method: AuthenticationMethod,
        backendMetadata: BackendMetadata
    ) async {
        switch method {
        case let .loginViaEmail(email, didDetectDomainConflict):
            router.navigate(to: DetermineAuthMethodView.Destination.login(
                email: email,
                didDetectDomainConflict: didDetectDomainConflict,
                backendMetadata: backendMetadata
            ))

        case let .loginOrRegisterViaEmail(email):
            router.navigate(to: DetermineAuthMethodView.Destination.loginOrRegister(
                email: email,
                backendMetadata: backendMetadata
            ))

        case let .loginViaSSO(code):
            let generator = factory.ssoLinkGenerator(apiVersion: backendMetadata.apiVersion)
            ssoLinkGenerator = generator

            do {
                let url = try await Task.detached { [generator] in
                    try await generator.generateSSOLink(ssoCode: code)
                }.value
                modalDestination = .ssoLogin(url: url)
            } catch {
                WireLogger.authentication.error("Error while generating SSO link: \(error)")

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
            do {
                let useCase = factory.fetchBackendConfigUseCase()
                let backendConfig = try await Task.detached {
                    try await useCase.invoke(at: backendConfigURL)
                }.value
                modalDestination = .switchBackend(email: email, backendConfig: backendConfig)
            } catch {
                WireLogger.authentication.error("Error fetching backend config: \(error)")

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
