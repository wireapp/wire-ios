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
        errorMessage: String?
    ) -> DetermineAuthMethodView {
        DetermineAuthMethodView(
            viewModel: DetermineAuthMethodViewModel(
                router: rootViewModel,
                validateEmailOrSSOCode: self,
                determineAuthMethod: self,
                emailOrSSOCode: emailOrSSOCode,
                isLoading: isLoading,
                errorMessage: errorMessage
            ),
            builder: self
        )
    }

}

extension MockDependencies: ValidateEmailOrSSOCodeUseCaseProtocol {

    @MainActor
    func invoke(input: String) throws -> ValidatedEmailOrSSOCode {
        if input.contains("@") {
            return .email(input)
        } else if input.hasSuffix("wire") {
            return .ssoCode(input)
        } else {
            throw ValidatedEmailOrSSOCodeFailure.invalidInput
        }
    }

}

extension MockDependencies: DetermineAuthMethodUseCaseProtocol {

    func invoke(emailOrSSOCode: String) async throws -> AuthenticationMethod {
        try await Task.sleep(for: .seconds(3))

        return .loginViaEmail(email: emailOrSSOCode)
    }

}

extension MockDependencies: LoginViaEmailUseCaseProtocol {

    func invoke(
        email: String,
        password: String
    ) async throws(LoginViaEmailUseCaseFailure) {
        // Success
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

    private func loginViewModel(email: String) -> LoginViaEmailViewModel {
        LoginViaEmailViewModel(
            router: rootViewModel,
            loginViaEmailUseCase: self,
            email: email
        )
    }

    func loginViaEmailView(email: String) -> LoginViaEmailView {
        LoginViaEmailView(
            viewModel: loginViewModel(email: email)
        )
    }

}
