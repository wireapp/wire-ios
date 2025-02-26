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

@MainActor
package final class DetermineAuthMethodViewModel: ObservableObject {

    package enum Alert: Hashable, Identifiable, Sendable {
        package var id: Self { self }

        case noInternet
        case invalidResponse
        case unknownError
        case onPremLoginNotPossible(recovery: AuthenticationMethod)
        case invalidSSOLink

    }

    package enum ModalDestination: Hashable, Identifiable {
        package var id: Self { self }

        case ssoLogin(url: URL)
    }

    private let router: any Router
    private let validateEmailOrSSOCode: any ValidateEmailOrSSOCodeUseCaseProtocol
    private let determineAuthMethod: any DetermineAuthMethodUseCaseProtocol
    private let ssoLinkGenerator: SSOLinkGeneratorProtocol

    @Published var emailOrSSOCode: String = ""
    @Published private(set) var isLoading = false
    @Published var alert: Alert?
    @Published var modalDestination: ModalDestination?

    var isNextButtonEnabled: Bool {
        !isValidEmailOrSSOCode()
    }

    package init(
        router: any Router,
        validateEmailOrSSOCode: any ValidateEmailOrSSOCodeUseCaseProtocol,
        determineAuthMethod: any DetermineAuthMethodUseCaseProtocol,
        ssoLinkGenerator: any SSOLinkGeneratorProtocol,
        emailOrSSOCode: String = "",
        isLoading: Bool = false,
        alert: Alert? = nil
    ) {
        self.router = router
        self.validateEmailOrSSOCode = validateEmailOrSSOCode
        self.determineAuthMethod = determineAuthMethod
        self.ssoLinkGenerator = ssoLinkGenerator
        self.emailOrSSOCode = emailOrSSOCode
        self.isLoading = isLoading
        self.alert = alert
    }

    func submitEmailOrSSOCode() async {
        isLoading = true

        do {
            let method = try await determineAuthMethod.invoke(emailOrSSOCode: emailOrSSOCode)
            await handleAuthenticationMethod(method)
        } catch {
            switch error {
            case .invalidEmailOrSSOCode:
                // No need to do anything here. In general this shouldn't happen. It is probably worth restructuring
                // things a little to make this error impossible to happen.
                break
            case let .onPremNotPossible(recovery):
                alert = .onPremLoginNotPossible(recovery: recovery)
            case .invalidResponse:
                alert = .invalidResponse
            case let .urlError(urlError):
                switch urlError.code {
                case .notConnectedToInternet, .networkConnectionLost:
                    alert = .noInternet
                default:
                    alert = .unknownError
                }
            case .unknown:
                alert = .unknownError
            }
        }

        isLoading = false
    }

    func didDismissAlert(alert: Alert) {
        switch alert {
        case let .onPremLoginNotPossible(method):
            Task.detached {
                await self.handleAuthenticationMethod(method)
            }
        default:
            break
        }
    }

    func dismissmodalView() {
        ssoLinkGenerator.flushToken()
        modalDestination = nil
    }

    // MARK: - Private

    private func handleAuthenticationMethod(_ method: AuthenticationMethod) async {
        switch method {
        case let .loginViaEmail(email):
            router.navigate(to: DetermineAuthMethodView.Destination.login(email: email))

        case let .loginOrRegisterViaEmail(email):
            router.navigate(to: DetermineAuthMethodView.Destination.loginOrRegister(email: email))

        case let .loginViaSSO(code):
            do {
                let url = try await ssoLinkGenerator.generateSSOLink(ssoCode: code)
                modalDestination = .ssoLogin(url: url)
            } catch {
                alert = .invalidSSOLink
            }

        case let .onPremLogin(email, backendConfig):
            // TODO: [WPB-15944] Handle on-prem login
            break
        }
    }

    private func isValidEmailOrSSOCode() -> Bool {
        do {
            _ = try validateEmailOrSSOCode.invoke(input: emailOrSSOCode.trimmingCharacters(in: .whitespaces))
            return true
        } catch {
            return false
        }
    }

}
