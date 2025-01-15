//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
public final class LandingViewModel: ObservableObject {

    let router: Router
    let determineAuthenticationMethod: any DetermineAuthenticationMethodUseCaseProtocol

    public init(
        router: Router,
        determineAuthenticationMethod: any DetermineAuthenticationMethodUseCaseProtocol
    ) {
        self.router = router
        self.determineAuthenticationMethod = determineAuthenticationMethod
    }

    func isValidEmailOrSSOCode(_ emailOrSSOCode: String) -> Bool {
        !emailOrSSOCode.isEmpty
    }

    func submitEmailOrSSOCode(_ emailOrSSOCode: String) {
        Task { [router] in
            let method = await self.determineAuthenticationMethod.invoke(
                emailOrSSOCode: emailOrSSOCode
            )

            switch method {
            case .login(let email):
                router.navigate(to: LandingView.Destination.login(email: email))

            case .loginOrRegister(let email):
                router.navigate(to: LandingView.Destination.loginOrRegister(email: email))

            default:
                break
            }
        }
    }

}

struct DetermineAuthenticationMethodUseCaseMock: DetermineAuthenticationMethodUseCaseProtocol {

    func invoke(emailOrSSOCode: String) async -> AuthenticationMethod {
        if emailOrSSOCode.hasSuffix("@wire.com") {
            return .loginOrRegister(email: emailOrSSOCode)
        } else {
            return .login(email: emailOrSSOCode)
        }
    }

}
