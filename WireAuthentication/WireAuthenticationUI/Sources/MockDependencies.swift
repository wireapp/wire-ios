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

}

extension MockDependencies: DetermineAuthenticationMethodUseCaseProtocol {

    func invoke(emailOrSSOCode: String) async -> AuthenticationMethod {
        .login(email: emailOrSSOCode)
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

extension MockDependencies: SubmitTwoFactorAuthenticationCodeUseCaseProtocol {

    func invoke(code: String) async throws {
        // Success
    }

}

extension MockDependencies: LandingBuilder {

    private var landingViewModel: DetermineAuthMethodViewModel {
        DetermineAuthMethodViewModel(
            router: rootViewModel,
            determineAuthenticationMethod: self
        )
    }

    var landingView: DetermineAuthMethodView {
        DetermineAuthMethodView(
            viewModel: landingViewModel,
            builder: self
        )
    }

}

extension MockDependencies: LoginViaEmailBuilder {

    private func loginViewModel(email: String) -> LoginViaEmailViewModel {
        LoginViaEmailViewModel(
            router: rootViewModel,
            loginViaEmailUseCase: self,
            email: email,
            isRegistrationAllowed: false
        )
    }

    func loginViaEmailView(email: String) -> LoginViaEmailView {
        LoginViaEmailView(
            viewModel: loginViewModel(email: email)
        )
    }

}
