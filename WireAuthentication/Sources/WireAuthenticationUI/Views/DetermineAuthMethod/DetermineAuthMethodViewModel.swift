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
public final class DetermineAuthMethodViewModel: ObservableObject {

    let router: any Router
    let determineAuthMethod: any DetermineAuthMethodUseCaseProtocol

    @Published var emailOrSSOCode: String = ""
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    var isNextButtonEnabled: Bool {
        !isValidEmailOrSSOCode()
    }

    public init(
        router: any Router,
        determineAuthMethod: any DetermineAuthMethodUseCaseProtocol,
        emailOrSSOCode: String = "",
        isLoading: Bool = false,
        errorMessage: String? = nil
    ) {
        self.router = router
        self.determineAuthMethod = determineAuthMethod
        self.emailOrSSOCode = emailOrSSOCode
        self.isLoading = isLoading
        self.errorMessage = errorMessage
    }

    func submitEmailOrSSOCode() {
        isLoading = true

        Task { [self] in
            // TODO: [WPB-15920] Handle errors
            let method = try! await self.determineAuthMethod.invoke(
                emailOrSSOCode: emailOrSSOCode
            )

            switch method {
            case let .loginViaEmail(email):
                router.navigate(to: DetermineAuthMethodView.Destination.login(email: email))

            case let .loginOrRegisterViaEmail(email):
                router.navigate(to: DetermineAuthMethodView.Destination.loginOrRegister(email: email))

            case let .loginViaSSO(code):
                // TODO: [WPB-15920] Handle login via SSO
                break
            case let .onPremLogin(email, backendConfig):
                // TODO: [WPB-15920] Handle on-prem login
                break
            }

            Task { @MainActor in
                isLoading = false
            }
        }
    }

    // MARK: - Private

    private func isValidEmailOrSSOCode() -> Bool {
        !emailOrSSOCode.isEmpty
    }

}
