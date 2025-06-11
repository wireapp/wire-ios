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
import WireAuthenticationDomain
import WireReusableUIComponents

struct FakeDetermineAuthMethodFactory: DetermineAuthMethodFactory,
    DetermineAuthMethodUseCaseFactory,
    FetchBackendConfigUseCaseFactory,
    LoginViaSSOUseCaseFactory,
    ValidateEmailOrSSOCodeUseCaseFactory {

    var existsAnotherAccount: Bool = false
    var emailOrSSOCode: String = ""

    var mockDependencies = MockDependencies()

    var viewModel: DetermineAuthMethodViewModel {
        let viewModel = DetermineAuthMethodViewModel(
            factory: self,
            router: FakeRootFactory().viewModel,
            bridge: WireAuthenticationBridge(),
            backendInfo: mockDependencies.backendInfo,
            existsAnotherAccount: existsAnotherAccount
        )
        viewModel.emailOrSSOCode = emailOrSSOCode
        return viewModel
    }

    func loginViaEmailFactory(
        email: String?,
        canCreateAccount: Bool,
        didDetectDomainConflict: Bool,
        backendInfo: WireAuthenticationDomain.BackendInfo
    ) -> any LoginViaEmailFactory {
        fatalError()
    }

    func noHistoryFactory(authenticationResult: WireAuthenticationDomain.AuthenticationResult) -> any NoHistoryFactory {
        fatalError()
    }

    // MARK: - UseCases

    func determineAuthMethodUseCase() async throws -> any WireAuthenticationDomain.DetermineAuthMethodUseCaseProtocol {
        try await mockDependencies.determineAuthMethodUseCase()
    }

    func fetchBackendConfigUseCase() -> any WireAuthenticationDomain.FetchBackendConfigUseCaseProtocol {
        mockDependencies.fetchBackendConfigUseCase()
    }

    func loginViaSSOUseCase(backendInfo: WireAuthenticationDomain.BackendInfo?) async throws -> any WireAuthenticationDomain
        .LoginViaSSOUseCaseProtocol {
        try await mockDependencies.loginViaSSOUseCase(backendInfo: backendInfo)
    }

    func validateEmailOrSSOCodeUseCase() -> any WireAuthenticationDomain.ValidateEmailOrSSOCodeUseCaseProtocol {
        mockDependencies.validateEmailOrSSOCodeUseCase()
    }
}
