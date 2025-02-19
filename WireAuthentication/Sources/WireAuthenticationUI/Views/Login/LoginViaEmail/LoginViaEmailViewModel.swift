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
import UIKit
import WireAuthenticationAPI
import WireReusableUIComponents

@MainActor
package final class LoginViaEmailViewModel: ObservableObject {

    private let router: any Router
    private let loginViaEmailUseCase: any LoginViaEmailUseCaseProtocol
    private let forgotPasswordURL: URL
    private let passwordValidator: any PasswordValidator

    let email: String
    let canCreateAccount: Bool

    // MARK: - Life cycle

    package init(
        router: any Router,
        loginViaEmailUseCase: any LoginViaEmailUseCaseProtocol,
        email: String,
        accountsURL: URL,
        passwordValidator: any PasswordValidator,
        canCreateAccount: Bool
    ) {
        self.router = router
        self.loginViaEmailUseCase = loginViaEmailUseCase
        self.email = email
        self.forgotPasswordURL = accountsURL.appendingPathComponent("forgot")
        self.passwordValidator = passwordValidator
        self.canCreateAccount = canCreateAccount
    }

    var localizedPasswordRules: String? {
        passwordValidator.localizedRulesDescription
    }

    func isValidPassword(_ password: String) -> Bool {
        passwordValidator.validate(password)
    }

    func submitPassword(_ password: String) {
        Task.detached {
            do {
                // TODO: [WPB-15924] Handle happy path
                _ = try await self.loginViaEmailUseCase.invoke(
                    email: self.email,
                    password: password,
                    verificationCode: ""
                )
            } catch {
                // TODO: [WPB-15924] Error handling
                print("error: \(error)")
            }
        }
    }

    func recoverPassword() {
        UIApplication.shared.open(forgotPasswordURL)
    }

    func createAccount() {}

}
