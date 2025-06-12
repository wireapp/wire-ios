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
import SwiftUI
import WireAuthenticationAPI
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

    func destinationView(for destination: DetermineAuthMethodDestination) -> AnyView {
        fatalError()
    }

    // MARK: - UseCases

    func determineAuthMethodUseCase() async throws -> any WireAuthenticationAPI.DetermineAuthMethodUseCaseProtocol {
        try await mockDependencies.determineAuthMethodUseCase()
    }

    func fetchBackendConfigUseCase() -> any WireAuthenticationAPI.FetchBackendConfigUseCaseProtocol {
        mockDependencies.fetchBackendConfigUseCase()
    }

    func loginViaSSOUseCase(backendInfo: WireAuthenticationAPI.BackendInfo?) async throws -> any WireAuthenticationAPI
        .LoginViaSSOUseCaseProtocol {
        try await mockDependencies.loginViaSSOUseCase(backendInfo: backendInfo)
    }

    func validateEmailOrSSOCodeUseCase() -> any WireAuthenticationAPI.ValidateEmailOrSSOCodeUseCaseProtocol {
        mockDependencies.validateEmailOrSSOCodeUseCase()
    }
}
