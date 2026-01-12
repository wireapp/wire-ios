//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import WireNetwork
import WireReusableUIComponents

struct FakeLoginViaEmailFactory: LoginViaEmailFactory, CreateAuthenticationResultUseCaseFactory,
    LoginViaEmailUseCaseFactory, SubmitProxyCredentialsUseCaseFactory, ValidateEmailUseCaseFactory {

    var mockDependencies = MockDependencies()

    var email: String?
    var environment: BackendEnvironment2
    var canCreateAccount: Bool
    var didDetectDomainConflict: Bool

    var viewModel: LoginViaEmailViewModel {
        .init(
            factory: self,
            router: FakeRootFactory().viewModel,
            email: email,
            environment: environment,
            canCreateAccount: canCreateAccount,
            didDetectDomainConflict: didDetectDomainConflict
        )
    }

    func verifyLoginView(email: String, password: String, proxyCredentials: ProxyCredentials?) -> VerificationCodeView {
        fatalError()
    }

    func noHistoryView(result: AuthenticationResult) -> NoHistoryView {
        fatalError()
    }

    func personalAccountCreationView(teamAccountCreationLink: URL?) -> PersonalAccountCreationView {
        fatalError()
    }

    @MainActor
    func createAuthenticationResultUseCase() -> any CreateAuthenticationResultUseCaseProtocol {
        mockDependencies.createAuthenticationResultUseCase()
    }

    func loginViaEmailUseCase() async throws -> any LoginViaEmailUseCaseProtocol {
        try await mockDependencies.loginViaEmailUseCase()
    }

    @MainActor
    func submitProxyCredentialsUseCase() -> any SubmitProxyCredentialsUseCaseProtocol {
        mockDependencies.submitProxyCredentialsUseCase()
    }

    func validateEmailUseCase() -> any ValidateEmailUseCaseProtocol {
        mockDependencies.validateEmailUseCase()
    }

}
