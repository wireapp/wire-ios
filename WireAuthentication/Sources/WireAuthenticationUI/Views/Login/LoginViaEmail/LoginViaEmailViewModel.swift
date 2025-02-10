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

import Foundation
import WireAuthenticationAPI
import WireReusableUIComponents

@MainActor
public final class LoginViaEmailViewModel: ObservableObject {

    let router: any Router
    let loginViaEmailUseCase: any LoginViaEmailUseCaseProtocol
    let email: String
    let forgotPasswordURL: URL
    let passwordValidator: any PasswordValidator

    // MARK: - Life cycle

    public init(
        router: any Router,
        loginViaEmailUseCase: any LoginViaEmailUseCaseProtocol,
        email: String,
        accountsURL: URL,
        passwordValidator: any PasswordValidator
    ) {
        self.router = router
        self.loginViaEmailUseCase = loginViaEmailUseCase
        self.email = email
        self.forgotPasswordURL = accountsURL.appendingPathComponent("forgot")
        self.passwordValidator = passwordValidator
    }

    func isValidPassword(_ password: String) -> Bool {
        passwordValidator.validate(password)
    }

    func submitPassword(_ password: String) {
        Task {
            do {
                try await loginViaEmailUseCase.invoke(
                    email: email,
                    password: password
                )
            } catch {
                // TODO: [WPB-15940] Error handling
                print("error: \(error)")
            }
        }
    }

}
