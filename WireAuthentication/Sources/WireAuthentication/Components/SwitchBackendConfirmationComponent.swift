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

    // FIXME: Adjust as necessary
//    @MainActor var router: any Router { get }
//    var preferredAPIVersion: APIVersion? { get }
//    var productionVersions: Set<APIVersion> { get }
//    var minTLSVersion: TLSVersion { get }
//    var ssoCallbackURLScheme: String { get }
//    var userDefaults: UserDefaults { get }

}

class SwitchBackendConfirmationComponent: Component<SwitchBackendConfirmationComponentDependency> {

    private let email: String
    private let environmentType: BackendEnvironmentType
    public let backendConfig: BackendConfig
    private let router: any Router
    private let preferredAPIVersion: APIVersion?
    private let productionVersions: Set<APIVersion>
    private let minTLSVersion: TLSVersion
    private let ssoCallbackURLScheme: String
    private let userDefaults: UserDefaults

    init(
        parent: any Scope,
        email: String,
        environmentType: BackendEnvironmentType,
        backendConfig: BackendConfig,
        router: any Router,
        preferredAPIVersion: APIVersion?,
        productionVersions: Set<APIVersion>,
        minTLSVersion: TLSVersion,
        ssoCallbackURLScheme: String,
        userDefaults: UserDefaults
    ) {
        self.email = email
        self.environmentType = environmentType
        self.backendConfig = backendConfig
        self.router = router
        self.preferredAPIVersion = preferredAPIVersion
        self.productionVersions = productionVersions
        self.minTLSVersion = minTLSVersion
        self.ssoCallbackURLScheme = ssoCallbackURLScheme
        self.userDefaults = userDefaults

        super.init(parent: parent)
    }

    // MARK: - View

    @MainActor var view: SwitchBackendConfirmationView {
        SwitchBackendConfirmationView(viewModel: viewModel)
    }

    @MainActor private var viewModel: SwitchBackendConfirmationViewModel {
        SwitchBackendConfirmationViewModel(
            router: router,
            factory: self,
            email: email,
            environmentType: environmentType,
            backendConfig: backendConfig
        )
    }

    // MARK: - Private dependencies

    private var backendEnvironment: BackendEnvironment {
        BackendEnvironment.makeWithoutProxyAuthentication(backendConfig)
    }

    private var networkService: any NetworkServiceProtocol {
        shared {
            NetworkService.make(
                backendEnvironment: backendEnvironment,
                minTLSVersion: minTLSVersion
            )
        }
    }

}

extension SwitchBackendConfirmationComponent: SwitchBackendConfirmationViewModel.Factory {

    func resolveBackendMetadataUseCase() -> any ResolveBackendMetadataUseCaseProtocol {
        let api = BackendMetadataAPIBuilder(networkService: networkService).makeAPI()
        return ResolveBackendMetadataUseCase(
            backendMetadataAPI: api,
            clientProductionVersions: productionVersions,
            preferredAPIVersion: preferredAPIVersion
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
            callbackScheme: ssoCallbackURLScheme,
            defaults: userDefaults
        )
        return FetchSSOURLUseCase(
            authenticationAPI: authenticationAPI,
            linkGenerator: linkGenerator
        )
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

extension BackendEnvironment {

    static func makeWithoutProxyAuthentication(_ backendConfig: BackendConfig) -> BackendEnvironment {
        var pinnedKeys = [PinnedKey]()
        do {
            for trustData in backendConfig.pinnedKeys ?? [] {
                pinnedKeys.append(try PinnedKey(trustData))
            }
        } catch {
            WireLogger.authentication.error("Failed to create PinnedKey: \(error)")
            pinnedKeys.removeAll()
        }

        return BackendEnvironment(
            url: backendConfig.endpoints.backendURL,
            webSocketURL: backendConfig.endpoints.backendWSURL,
            pinnedKeys: pinnedKeys,
            proxySettings: backendConfig.proxySettings.map { .unauthenticated(host: $0.host, port: $0.port) }
        )
    }

}
