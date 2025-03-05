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

import NeedleFoundation
import SwiftUI
import WireAPI
import WireAuthenticationAPI
internal import WireAuthenticationUI
internal import WireAuthenticationLogic
import WireReusableUIComponents

protocol LoginViaEmailOnPremComponentDependency: Dependency {

    @MainActor var router: any Router { get }
    var defaultBackendEnvironment: BackendEnvironment { get }
    var defaultAPIVersion: APIVersion { get }
    var minTLSVersion: TLSVersion { get }
    var passwordValidator: any PasswordValidator { get }

}

class LoginViaEmailOnPremComponent: Component<LoginViaEmailOnPremComponentDependency> {

    public var authenticationAPI: AuthenticationAPI {
        AuthenticationAPIBuilder(
            networkService: NetworkService.make(
                backendEnvironment: dependency.defaultBackendEnvironment,
                minTLSVersion: dependency.minTLSVersion
            )
        ).makeAPI(for: dependency.defaultAPIVersion)
    }

    public var loginViaEmailUseCase: any LoginViaEmailUseCaseProtocol {
        LoginViaEmailUseCase(authenticationAPI: authenticationAPI)
    }

    // MARK: - View

    @MainActor
    func view(email: String, backendConfig: BackendConfig) -> LoginViaEmailOnPremView {
        LoginViaEmailOnPremView(
            viewModel: viewModel(
                email: email,
                backendConfig: backendConfig
            )
        )
    }

    @MainActor
    private func viewModel(
        email: String,
        backendConfig: BackendConfig
    ) -> LoginViaEmailOnPremViewModel {
        LoginViaEmailOnPremViewModel(
            router: dependency.router,
            loginViaEmailUseCase: loginViaEmailUseCase,
            email: email,
            backendConfig: backendConfig,
            passwordValidator: dependency.passwordValidator,
            canCreateAccount: false
        )
    }

}
