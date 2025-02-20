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

    package enum Alert: Hashable, Identifiable, Sendable {
        package var id: Self { self }

        case noInternet
        case unknownError
    }

    @Published var password: String = "" {
        didSet { showPasswordRules = !isPasswordValid }
    }
    @Published private(set) var showPasswordRules = false
    @Published private(set) var isLoading = false
    @Published var alert: Alert?

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
        passwordValidator.isPasswordValid(password)
    }

    func submitPassword() async {
        isLoading = true

        do {
            // TODO: [WPB-15924] Handle happy path
            _ = try await self.loginViaEmailUseCase.invoke(
                email: email,
                password: password,
                verificationCode: ""
            )
            print(">>>> Login successful")
        } catch {
            switch error {
            case .invalidCredentials:
                break
            case .twoFactorAuthenticationRequired:
                router.navigate(
                    to: LoginViaEmailView.Destination.verifyLogin(email: email, password: password)
                )
            case .twoFactorAuthenticationFailed:
                break // This shouldn't happen in this view
            case .accountPendingActivation:
                break
            case .accountSuspended:
                break
            case .noInternet:
                alert = .noInternet
            case .other:
                alert = .unknownError
            }
        }

        isLoading = false
    }

    func recoverPassword() {
        UIApplication.shared.open(forgotPasswordURL)
    }

    func createAccount() {}

}
