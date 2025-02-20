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
    }

    private let router: any Router
    private let validateEmailOrSSOCode: any ValidateEmailOrSSOCodeUseCaseProtocol
    private let determineAuthMethod: any DetermineAuthMethodUseCaseProtocol

    @Published var emailOrSSOCode: String = ""
    @Published private(set) var isLoading = false
    @Published var alert: Alert?

    var isNextButtonEnabled: Bool {
        !isValidEmailOrSSOCode()
    }

    package init(
        router: any Router,
        validateEmailOrSSOCode: any ValidateEmailOrSSOCodeUseCaseProtocol,
        determineAuthMethod: any DetermineAuthMethodUseCaseProtocol,
        emailOrSSOCode: String = "",
        isLoading: Bool = false,
        alert: Alert? = nil
    ) {
        self.router = router
        self.validateEmailOrSSOCode = validateEmailOrSSOCode
        self.determineAuthMethod = determineAuthMethod
        self.emailOrSSOCode = emailOrSSOCode
        self.isLoading = isLoading
        self.alert = alert
    }

    func submitEmailOrSSOCode() async {
        isLoading = true

        do {
            let method = try await determineAuthMethod.invoke(emailOrSSOCode: emailOrSSOCode)
            handleAuthenticationMethod(method)
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
            handleAuthenticationMethod(method)
        default:
            break
        }
    }

    // MARK: - Private

    private func handleAuthenticationMethod(_ method: AuthenticationMethod) {
        switch method {
        case let .loginViaEmail(email):
            router.navigate(to: DetermineAuthMethodView.Destination.login(email: email))

        case let .loginOrRegisterViaEmail(email):
            router.navigate(to: DetermineAuthMethodView.Destination.loginOrRegister(email: email))

        case let .loginViaSSO(code):
            // TODO: [WPB-15943] Handle login via SSO
            break

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
