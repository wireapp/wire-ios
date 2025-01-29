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

    let router: Router
    let determineAuthMethod: any DetermineAuthMethodUseCaseProtocol

    public init(
        router: Router,
        determineAuthMethod: any DetermineAuthMethodUseCaseProtocol
    ) {
        self.router = router
        self.determineAuthMethod = determineAuthMethod
    }

    func isValidEmailOrSSOCode(_ emailOrSSOCode: String) -> Bool {
        !emailOrSSOCode.isEmpty
    }

    func submitEmailOrSSOCode(_ emailOrSSOCode: String) {
        Task { [router] in
            let method = await self.determineAuthMethod.invoke(
                emailOrSSOCode: emailOrSSOCode
            )

            switch method {
            case let .login(email):
                router.navigate(to: DetermineAuthMethodView.Destination.login(email: email))

            case let .loginOrRegister(email):
                router.navigate(to: DetermineAuthMethodView.Destination.loginOrRegister(email: email))

            default:
                break
            }
        }
    }

}
