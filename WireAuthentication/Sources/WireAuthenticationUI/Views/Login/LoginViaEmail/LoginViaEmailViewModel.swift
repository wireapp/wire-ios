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
import WireLogging
import WireReusableUIComponents

@MainActor
package final class LoginViaEmailViewModel: ObservableObject {

    package enum Alert: Hashable, Identifiable, Sendable {
        package var id: Self { self }

        case noInternet
        case unknownError
        case invalidCredentials
        case accountPendingActivation
        case accountSuspended
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
    private let bridge: WireAuthenticationBridge

    let email: String
    let canCreateAccount: Bool

    // MARK: - Life cycle

    package init(
        router: any Router,
        loginViaEmailUseCase: any LoginViaEmailUseCaseProtocol,
        email: String,
        accountsURL: URL,
        passwordValidator: any PasswordValidator,
        canCreateAccount: Bool,
        bridge: WireAuthenticationBridge
    ) {
        self.router = router
        self.loginViaEmailUseCase = loginViaEmailUseCase
        self.email = email
        self.forgotPasswordURL = accountsURL.appendingPathComponent("forgot")
        self.passwordValidator = passwordValidator
        self.canCreateAccount = canCreateAccount
        self.bridge = bridge
    }

    var localizedPasswordRules: String? {
        passwordValidator.localizedRulesDescription
    }

    var isPasswordValid: Bool {
        passwordValidator.isPasswordValid(password)
    }

    func submitPassword() async {
        isLoading = true

        do {
            let (cookies, token) = try await loginViaEmailUseCase.invoke(
                email: email,
                password: password,
                verificationCode: nil
            )
            bridge.completeFlow(cookies: cookies, accessToken: token)
        } catch {
            switch error {
            case .invalidCredentials:
                alert = .invalidCredentials
            case .twoFactorAuthenticationRequired:
                router.navigate(
                    to: LoginViaEmailView.Destination.verifyLogin(email: email, password: password)
                )
            case .twoFactorAuthenticationFailed:
                // This shouldn't happen in this view as we are not submitting a verification code
                WireLogger.authentication.critical("Two factor authentication failed in LoginViaEmailViewModel")
                alert = .unknownError
            case .accountPendingActivation:
                alert = .accountPendingActivation
            case .accountSuspended:
                alert = .accountSuspended
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

    func createAccount() {
        bridge.createAccount()
    }

}
