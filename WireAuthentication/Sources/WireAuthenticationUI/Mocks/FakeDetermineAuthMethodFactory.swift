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
import SwiftUI
import WireAuthenticationAPI
import WireNetwork
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
            environment: mockDependencies.backendEnvironment,
            existsAnotherAccount: existsAnotherAccount,
            isMultibackendEnabled: false
        )
        viewModel.emailOrSSOCode = emailOrSSOCode
        return viewModel
    }

    func loginView(
        email: String?,
        didDetectDomainConflict: Bool,
        environment: BackendEnvironment2
    ) -> LoginViaEmailView {
        fatalError()
    }

    func loginOrRegisterView(
        email: String?,
        didDetectDomainConflict: Bool,
        environment: BackendEnvironment2
    ) -> LoginViaEmailView {
        fatalError()
    }

    func noHistoryView(result: AuthenticationResult) -> NoHistoryView {
        fatalError()
    }

    // MARK: - UseCases

    func determineAuthMethodUseCase() async throws -> any WireAuthenticationAPI.DetermineAuthMethodUseCaseProtocol {
        try await mockDependencies.determineAuthMethodUseCase()
    }

    @MainActor
    func fetchBackendConfigUseCase() -> any WireAuthenticationAPI.FetchBackendConfigUseCaseProtocol {
        mockDependencies.fetchBackendConfigUseCase()
    }

    func loginViaSSOUseCase(environment: BackendEnvironment2?) async throws -> any WireAuthenticationAPI
        .LoginViaSSOUseCaseProtocol {
        try await mockDependencies.loginViaSSOUseCase(environment: environment)
    }

    func validateEmailOrSSOCodeUseCase() -> any WireAuthenticationAPI.ValidateEmailOrSSOCodeUseCaseProtocol {
        mockDependencies.validateEmailOrSSOCodeUseCase()
    }
}
