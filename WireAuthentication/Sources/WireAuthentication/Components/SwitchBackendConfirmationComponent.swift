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

protocol SwitchBackendConfirmationComponentDependency: Dependency {

    @MainActor var router: any Router { get }
    var authenticationAPI: AuthenticationAPI { get }
    var defaultBackendEnvironment: BackendEnvironment { get }
    var ssoCallbackURLScheme: String { get }
    var userDefaults: UserDefaults { get }

}

class SwitchBackendConfirmationComponent: Component<SwitchBackendConfirmationComponentDependency> {

    // MARK: - View

    @MainActor
    func view(email: String, environment: BackendEnvironmentInfo) -> SwitchBackendConfirmationView {
        SwitchBackendConfirmationView(viewModel: viewModel(email: email, environment: environment))
    }

    @MainActor
    private func viewModel(email: String, environment: BackendEnvironmentInfo) -> SwitchBackendConfirmationViewModel {
        SwitchBackendConfirmationViewModel(
            router: dependency.router,
            email: email,
            fetchDefaultSSOSettings: fetchDefaultSSOSettings,
            ssoLinkGenerator: ssoLinkGenerator,
            environment: environment
        )
    }

    // MARK: - Private dependencies

    private var fetchDefaultSSOSettings: any FetchDefaultSSOSettingsUseCaseProtocol {
        FetchDefaultSSOSettingsUseCase(authenticationAPI: dependency.authenticationAPI)
    }

    private var ssoLinkGenerator: SSOLinkGeneratorProtocol {
        SSOLinkGenerator(
            authenticationAPI: dependency.authenticationAPI,
            baseURL: dependency.defaultBackendEnvironment.url,
            callbackScheme: dependency.ssoCallbackURLScheme,
            defaults: dependency.userDefaults
        )
    }

}
