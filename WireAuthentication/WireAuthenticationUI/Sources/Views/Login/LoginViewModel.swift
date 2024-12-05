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

import Foundation
import SwiftUI
import WireAuthenticationAPI

@MainActor
final class LoginViewModel: ObservableObject {

    let router: Router
    let emailLogIn: any EmailLogInUseCaseProtocol

    let email = "foo@bar.com"
    let isRegistrationAllowed: Bool

    init(
        router: Router,
        emailLogIn: any EmailLogInUseCaseProtocol,
        isRegistrationAllowed: Bool
    ) {
        self.router = router
        self.emailLogIn = emailLogIn
        self.isRegistrationAllowed = isRegistrationAllowed
    }

    func isValidPassword(_ password: String) -> Bool {
        !password.isEmpty
    }

    func submitPassword(_ password: String) {
        Task { [email, router] in
            try await self.emailLogIn.invoke(
                email: email,
                password: password
            )

            await MainActor.run {
                router.navigate(to: .twoFactorAuthentication)
            }
        }
    }

}

struct EmailLogInUseCaseMock: EmailLogInUseCaseProtocol {

    func invoke(
        email: String,
        password: String
    ) async throws {

    }

}
