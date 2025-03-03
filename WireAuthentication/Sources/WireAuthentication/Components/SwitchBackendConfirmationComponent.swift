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

protocol SwitchBackendConfirmationComponentDependency: Dependency {

    @MainActor var router: any Router { get }
    var defaultBackendEnvironment: BackendEnvironment { get }
    var defaultAPIVersion: APIVersion { get }
    var minTLSVersion: TLSVersion { get }
}

class SwitchBackendConfirmationComponent: Component<SwitchBackendConfirmationComponentDependency> {

    // MARK: - View

    @MainActor
    func view(environment: BackendEnvironmentInfo) -> SwitchBackendConfirmationView {
        SwitchBackendConfirmationView(viewModel: viewModel(environment: environment))
    }

    @MainActor
    private func viewModel(environment: BackendEnvironmentInfo) -> SwitchBackendConfirmationViewModel {
        SwitchBackendConfirmationViewModel(
            router: dependency.router,
            fetchDefaultSSOSettings: fetchDefaultSSOSettings(from: environment),
            environment: environment
        )
    }

    // MARK: - Private dependencies

    private func authenticationAPI(from environment: BackendEnvironmentInfo) -> AuthenticationAPI {
        AuthenticationAPIBuilder(
            networkService: NetworkService.make(
                backendEnvironment: BackendEnvironment(
                    url: environment.endpoints.backendURL,
                    webSocketURL: environment.endpoints.backendWSURL,
                    pinnedKeys: dependency.defaultBackendEnvironment.pinnedKeys,
                    proxySettings: dependency.defaultBackendEnvironment.proxySettings),
                minTLSVersion: dependency.minTLSVersion
            )
        ).makeAPI(for: dependency.defaultAPIVersion)
    }

    private func fetchDefaultSSOSettings(from environment: BackendEnvironmentInfo) -> some FetchDefaultSSOSettingsUseCaseProtocol {
        return FetchDefaultSSOSettingsUseCase(authenticationAPI: authenticationAPI(from: environment))
    }

}
