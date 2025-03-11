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
    var preferredAPIVersion: APIVersion? { get }
    var minTLSVersion: TLSVersion { get }
    var ssoCallbackURLScheme: String { get }
    var userDefaults: UserDefaults { get }

}

class SwitchBackendConfirmationComponent: Component<SwitchBackendConfirmationComponentDependency> {

    private let email: String
    public let backendConfig: BackendConfig

    init(
        parent: any Scope,
        email: String,
        backendConfig: BackendConfig
    ) {
        self.email = email
        self.backendConfig = backendConfig
        super.init(parent: parent)
    }

    // MARK: - View

    @MainActor var view: SwitchBackendConfirmationView {
        SwitchBackendConfirmationView(viewModel: viewModel, factory: self)
    }

    @MainActor private var viewModel: SwitchBackendConfirmationViewModel {
        SwitchBackendConfirmationViewModel(
            router: dependency.router,
            factory: self,
            email: email,
            backendConfig: backendConfig
        )
    }

    // MARK: - Children

    var loginViaSSOComponent: LoginViaSSOComponent {
        LoginViaSSOComponent()
    }

    // MARK: - Private dependencies

    private var backendEnvironment: BackendEnvironment {
        shared {
            BackendEnvironment(backendConfig)
        }
    }

    private var networkService: NetworkService {
        shared {
            NetworkService.make(
                backendEnvironment: backendEnvironment,
                minTLSVersion: dependency.minTLSVersion
            )
        }
    }

}

extension SwitchBackendConfirmationComponent: SwitchBackendConfirmationViewModel.Factory {

    func resolveBackendMetadataUseCase() -> any ResolveBackendMetadataUseCaseProtocol {
        let api = BackendMetadataAPIBuilder(networkService: networkService).makeAPI()
        return ResolveBackendMetadataUseCase(
            backendMetadataAPI: api,
            clientProductionVersions: APIVersion.productionVersions,
            preferredAPIVersion: dependency.preferredAPIVersion
        )
    }

    func fetchSSOURLUseCase(
        apiVersion: WireAuthenticationAPI.BackendMetadata.APIVersion
    ) -> any FetchSSOURLUseCaseProtocol {
        let authenticationAPI = AuthenticationAPIBuilder(networkService: networkService).makeAPI(
            for: .init(apiVersion)
        )
        let linkGenerator = SSOLinkGenerator(
            authenticationAPI: authenticationAPI,
            baseURL: backendEnvironment.url,
            callbackScheme: dependency.ssoCallbackURLScheme,
            defaults: dependency.userDefaults
        )
        return FetchSSOURLUseCase(
            authenticationAPI: authenticationAPI,
            linkGenerator: linkGenerator
        )
    }

}

extension SwitchBackendConfirmationComponent: SwitchBackendConfirmationView.Factory {

    func loginViaSSOView(ssoURL: URL) -> LoginViaSSOView {
        loginViaSSOComponent.view(ssoURL: ssoURL)
    }

}

private extension PinnedKey {

    init(_ trustData: TrustData) throws {
        try self.init(
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
    }

}

private extension WireAPI.ProxySettings {

    init(_ proxySettings: WireAuthenticationAPI.ProxySettings) {

        // TODO: [WPB-16266] add credentials
        if proxySettings.needsAuthentication {
            self = .authenticated(
                host: proxySettings.host,
                port: proxySettings.port,
                username: "",
                password: ""
            )
        } else {
            self = .unauthenticated(
                host: proxySettings.host,
                port: proxySettings.port
            )
        }
    }

}

extension BackendEnvironment {

    init(_ backendConfig: BackendConfig) {
        var pinnedKeys = [PinnedKey]()
        do {
            for trustData in backendConfig.pinnedKeys ?? [] {
                pinnedKeys.append(try PinnedKey(trustData))
            }
        } catch {
            WireLogger.authentication.error("Failed to create PinnedKey: \(error)")
            pinnedKeys.removeAll()
        }

        self.init(
            url: backendConfig.endpoints.backendURL,
            webSocketURL: backendConfig.endpoints.backendWSURL,
            pinnedKeys: pinnedKeys,
            proxySettings: backendConfig.proxySettings.map(WireAPI.ProxySettings.init)
        )
    }

}
