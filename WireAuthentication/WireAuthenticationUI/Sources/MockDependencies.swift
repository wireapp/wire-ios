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

    let router = Router()

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

    private var landingViewModel: LandingViewModel {
        LandingViewModel(
            router: router,
            determineAuthenticationMethod: self
        )
    }

    var landingView: LandingView {
        LandingView(
            viewModel: landingViewModel,
            builder: self
        )
    }

}

extension MockDependencies: LoginViaEmailBuilder {

    private func loginViewModel(email: String) -> LoginViewModel {
        LoginViewModel(
            router: router,
            loginViaEmailUseCase: self,
            email: email,
            isRegistrationAllowed: false
        )
    }

    func loginViaEmailView(email: String) -> LoginView {
        LoginView(
            viewModel: loginViewModel(email: email),
            builder: self
        )
    }

}

extension MockDependencies: VerifyEmailBuilder {

    private var verifyEmailViewModel: TwoFactorAuthenticationViewModel {
        TwoFactorAuthenticationViewModel(
            router: router,
            submitCode: self
        )
    }

    var verifyEmailView: TwoFactorAuthenticationView {
        TwoFactorAuthenticationView(viewModel: verifyEmailViewModel)
    }

}
