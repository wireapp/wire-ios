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
import WireLogging

protocol SwitchBackendConfirmationComponentDependency: Dependency {

    @MainActor var router: any Router { get }
    var defaultAPIVersion: APIVersion { get }
    var minTLSVersion: TLSVersion { get }
    var ssoCallbackURLScheme: String { get }
    var userDefaults: UserDefaults { get }

}

class SwitchBackendConfirmationComponent: Component<SwitchBackendConfirmationComponentDependency> {

    public let backendConfig: BackendConfig

    init(
        parent: any Scope,
        backendConfig: BackendConfig
    ) {
        self.backendConfig = backendConfig
        super.init(parent: parent)
    }

    // MARK: - View

    @MainActor
    func view(email: String) -> SwitchBackendConfirmationView {
        SwitchBackendConfirmationView(viewModel: viewModel(email: email), factory: self)
    }

    @MainActor
    private func viewModel(email: String) -> SwitchBackendConfirmationViewModel {
        SwitchBackendConfirmationViewModel(
            router: dependency.router,
            email: email,
            fetchDefaultSSOSettings: fetchDefaultSSOSettings(environment: backendConfig),
            ssoLinkGenerator: ssoLinkGenerator(environment: backendConfig),
            environment: backendConfig
        )
    }

    // MARK: - Private dependencies

    private var authenticationAPI: AuthenticationAPI {
        AuthenticationAPIBuilder(
            networkService: NetworkService.make(
                backendEnvironment: BackendEnvironment(
                    url: backendConfig.endpoints.backendURL,
                    webSocketURL: backendConfig.endpoints.backendWSURL,
                    pinnedKeys: backendConfig.pinnedKeys?.compactMap { trustData in
                        do {
                            return try PinnedKey(
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
                        } catch {
                            WireLogger.authentication.error("Failed to create PinnedKey: \(error)")
                            return nil
                        }
                    } ?? [],
                    proxySettings: convertProxySettings(from: backendConfig.proxySettings)
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
        FetchDefaultSSOSettingsUseCase(authenticationAPI: authenticationAPI)
    }

    private func ssoLinkGenerator(environment: BackendConfig) -> SSOLinkGeneratorProtocol {
        SSOLinkGenerator(
            authenticationAPI: authenticationAPI,
            baseURL: environment.endpoints.backendURL,
            callbackScheme: dependency.ssoCallbackURLScheme,
            defaults: dependency.userDefaults
        )
    }

    // MARK: - Children
    
    var loginViaSSOComponent: LoginViaSSOComponent {
        LoginViaSSOComponent()
    }

}

extension SwitchBackendConfirmationComponent: SwitchBackendConfirmationView.Factory {
    func loginViaSSOView(ssoURL: URL) -> LoginViaSSOView {
        loginViaSSOComponent.view(ssoURL: ssoURL)
    }

}
