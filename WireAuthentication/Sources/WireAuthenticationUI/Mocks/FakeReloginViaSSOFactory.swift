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

struct FakeReloginViaSSOFactory: ReloginViaSSOFactory, LoginViaSSOUseCaseFactory, ValidateSSOCodeUseCaseFactory {

    let environment: BackendEnvironment2
    let existsAnotherAccount: Bool

    @MainActor var viewModel: ReloginViaSSOViewModel {
        ReloginViaSSOViewModel(
            factory: self,
            router: FakeRootFactory().viewModel,
            bridge: WireAuthenticationBridge(),
            environment: environment,
            existsAnotherAccount: existsAnotherAccount
        )
    }

    @MainActor
    func noHistoryView(result: AuthenticationResult) -> NoHistoryView {
        fatalError()
    }

    func loginViaSSOUseCase(environment: BackendEnvironment2?) async throws -> any LoginViaSSOUseCaseProtocol {
        try await MockDependencies().loginViaSSOUseCase(environment: environment)
    }

    func validateSSOCodeUseCase() -> any ValidateSSOCodeUseCaseProtocol {
        MockDependencies().validateSSOCodeUseCase()
    }
}
