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
        //case cloudAccountAlreadyRegistered(UUID, [HTTPCookie])
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
    private let onCreateAccount: () -> Void
    private let isCloudAccountAlreadyRegistered: Bool

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
        isCloudAccountAlreadyRegistered: Bool,
        onCreateAccount: @escaping () -> Void
    ) {
        self.router = router
        self.loginViaEmailUseCase = loginViaEmailUseCase
        self.email = email
        self.forgotPasswordURL = accountsURL.appendingPathComponent("forgot")
        self.passwordValidator = passwordValidator
        self.canCreateAccount = canCreateAccount
        self.isCloudAccountAlreadyRegistered = isCloudAccountAlreadyRegistered
        self.onCreateAccount = onCreateAccount
    }

    var localizedPasswordRules: String? {
        passwordValidator.localizedRulesDescription
    }

    var isPasswordValid: Bool {
        passwordValidator.isPasswordValid(cleanPassword)
    }

    func submitPassword() async {
        isLoading = true

        let loginTask = Task.detached { [loginViaEmailUseCase, email, cleanPassword] in
            try await loginViaEmailUseCase.invoke(
                email: email,
                password: cleanPassword,
                verificationCode: nil
            )
        }

        do {
            let (cookies, token) = try await loginTask.value
//            if isCloudAccountAlreadyRegistered {
//                alert = .cloudAccountAlreadyRegistered(token.userID, cookies)
//            } else {
                router.presentSheet(
                    RootView.ModalDestination.noHistory(
                        userID: token.userID,
                        cookies: cookies,
                        isCloudAccountAlreadyRegistered: isCloudAccountAlreadyRegistered
                    )
                )
//            }
            WireLogger.authentication.info("login via email succeeded")
        } catch {
            WireLogger.authentication.info("login via email returned an error: \(error)")

            switch error {
            case LoginViaEmailUseCaseFailure.invalidCredentials:
                alert = .invalidCredentials
            case LoginViaEmailUseCaseFailure.twoFactorAuthenticationRequired:
                router.navigate(
                    to: LoginViaEmailView.Destination.verifyLogin(email: email, password: password)
                )
            case LoginViaEmailUseCaseFailure.accountPendingActivation:
                alert = .accountPendingActivation
            case LoginViaEmailUseCaseFailure.accountSuspended:
                alert = .accountSuspended
            case LoginViaEmailUseCaseFailure.noInternet:
                alert = .noInternet
            default:
                WireLogger.authentication.error("Unexpected error during login via email: \(error)")
                alert = .unknownError
            }
        }

        isLoading = false
    }

    func recoverPassword() {
        UIApplication.shared.open(forgotPasswordURL)
    }

    func createAccount() {
        onCreateAccount()
    }

    // MARK: - Private

    private var cleanPassword: String {
        password.trimmingCharacters(in: .whitespacesAndNewlines)
    }

}
