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
    var defaultAPIVersion: APIVersion { get }
    var minTLSVersion: TLSVersion { get }
    var ssoCallbackURLScheme: String { get }
    var userDefaults: UserDefaults { get }

}

class SwitchBackendConfirmationComponent: Component<SwitchBackendConfirmationComponentDependency> {

    // MARK: - View

    @MainActor
    func view(email: String, environment: BackendConfig) -> SwitchBackendConfirmationView {
        SwitchBackendConfirmationView(viewModel: viewModel(email: email, environment: environment))
    }

    @MainActor
    private func viewModel(email: String, environment: BackendConfig) -> SwitchBackendConfirmationViewModel {
        SwitchBackendConfirmationViewModel(
            router: dependency.router,
            email: email,
            fetchDefaultSSOSettings: fetchDefaultSSOSettings(environment: environment),
            ssoLinkGenerator: ssoLinkGenerator(environment: environment),
            environment: environment
        )
    }

    // MARK: - Private dependencies

    private func authenticationAPI(environment: BackendConfig) -> AuthenticationAPI {
        AuthenticationAPIBuilder(
            networkService: NetworkService.make(
                backendEnvironment: BackendEnvironment(
                    url: environment.endpoints.backendURL,
                    webSocketURL: environment.endpoints.backendWSURL,
                    pinnedKeys: environment.pinnedKeys?.map { trustData in
                        PinnedKey(
                            key: trustData.certificateKey,
                            hosts: trustData.hosts.map { host in
                                switch host.rule {
                                case .equals:
                                    .equals(host.value)
                                case .endsWith:
                                    .endsWith(host.value)
                                }
                            }
                        )
                    } ?? [],
                    proxySettings: convertProxySettings(from: environment.proxySettings)
                ),
                minTLSVersion: dependency.minTLSVersion
            )
        ).makeAPI(for: dependency.defaultAPIVersion)
    }

    private func convertProxySettings(from proxySettings: WireAuthenticationAPI.ProxySettings?) -> WireAPI
        .ProxySettings? {
        guard let proxySettings else {
            return nil
        }

        return .unauthenticated(host: proxySettings.host, port: proxySettings.port)
    }

    private func fetchDefaultSSOSettings(environment: BackendConfig) -> any FetchDefaultSSOSettingsUseCaseProtocol {
        FetchDefaultSSOSettingsUseCase(authenticationAPI: authenticationAPI(environment: environment))
    }

    private func ssoLinkGenerator(environment: BackendConfig) -> SSOLinkGeneratorProtocol {
        SSOLinkGenerator(
            authenticationAPI: authenticationAPI(environment: environment),
            baseURL: environment.endpoints.backendURL,
            callbackScheme: dependency.ssoCallbackURLScheme,
            defaults: dependency.userDefaults
        )
    }

}
