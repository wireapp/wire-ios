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
final class MockDependencies {

    private var rootViewModel: RootViewModel {
        RootViewModel()
    }

    var rootView: RootView {
        RootView(
            viewModel: rootViewModel,
            builder: self
        )
    }

    func makeDetermineAuthMethodView(
        emailOrSSOCode: String,
        isLoading: Bool,
        alert: DetermineAuthMethodViewModel.Alert?
    ) -> DetermineAuthMethodView {
        DetermineAuthMethodView(
            viewModel: DetermineAuthMethodViewModel(
                router: rootViewModel,
                validateEmailOrSSOCode: self,
                determineAuthMethod: self,
                emailOrSSOCode: emailOrSSOCode,
                isLoading: isLoading,
                alert: alert
            ),
            builder: self
        )
    }

}

extension MockDependencies: ValidateEmailOrSSOCodeUseCaseProtocol {

    nonisolated func invoke(input: String) throws -> ValidatedEmailOrSSOCode {
        if input.contains("@") {
            return .email(email: input, domain: input.components(separatedBy: "@").last!)
        } else if input.hasSuffix("wire") {
            return .ssoCode(UUID())
        } else {
            throw ValidatedEmailOrSSOCodeFailure.invalidInput
        }
    }

}

extension MockDependencies: DetermineAuthMethodUseCaseProtocol {
    func invoke(
        emailOrSSOCode: String
    ) async throws(DetermineAuthMethodUseCaseFailure) -> AuthenticationMethod {
        try! await Task.sleep(for: .seconds(3))

        return .loginViaEmail(email: emailOrSSOCode)
    }
}

extension MockDependencies: LoginViaEmailUseCaseProtocol {

    func invoke(
        email: String,
        password: String,
        verificationCode: String?
    ) async throws(LoginViaEmailUseCaseFailure) -> ([HTTPCookie], String) {
        ([], "")
    }

}

extension MockDependencies: DetermineAuthMethodBuilder {

    private var determineAuthMethodViewModel: DetermineAuthMethodViewModel {
        DetermineAuthMethodViewModel(
            router: rootViewModel,
            validateEmailOrSSOCode: self,
            determineAuthMethod: self
        )
    }

    var determineAuthMethodView: DetermineAuthMethodView {
        DetermineAuthMethodView(
            viewModel: determineAuthMethodViewModel,
            builder: self
        )
    }

}

extension MockDependencies: LoginViaEmailBuilder {

    private func loginViewModel(email: String, canCreateAccount: Bool) -> LoginViaEmailViewModel {
        LoginViaEmailViewModel(
            router: rootViewModel,
            loginViaEmailUseCase: self,
            email: email,
            accountsURL: URL(string: "https://example.com")!,
            passwordValidator: MockPasswordValidator(validationCallback: { _ in true }),
            canCreateAccount: canCreateAccount
        )
    }

    func loginViaEmailView(email: String, canCreateAccount: Bool) -> LoginViaEmailView {
        LoginViaEmailView(
            viewModel: loginViewModel(email: email, canCreateAccount: canCreateAccount)
        )
    }

}

private struct MockPasswordValidator: PasswordValidator {

    let validationCallback: @Sendable (String) -> Bool

    init(validationCallback: @Sendable @escaping (String) -> Bool) {
        self.validationCallback = validationCallback
    }

    func validate(_ password: String) -> Bool {
        validationCallback(password)
    }

    var localizedRulesDescription: String? {
        "Password rules"
    }

}
