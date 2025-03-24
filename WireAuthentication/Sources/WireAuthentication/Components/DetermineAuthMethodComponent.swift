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
import WireLogging
internal import WireAuthenticationUI
internal import WireAuthenticationLogic

protocol DetermineAuthMethodComponentDependency: Dependency {

    @MainActor var router: any Router { get }
    @MainActor var bridge: WireAuthenticationBridge { get }
    var environmentType: BackendEnvironmentType { get }
    var backendConfig: BackendConfig { get }
    var preferredAPIVersion: APIVersion? { get }
    var minTLSVersion: TLSVersion { get }
    var ssoCallbackURLScheme: String { get }
    var userDefaults: UserDefaults { get }
    var existsAnotherAccount: Bool { get }

}

class DetermineAuthMethodComponent: Component<DetermineAuthMethodComponentDependency> {

    public let networkStack: NetworkStack

    init(
        parent: any Scope,
        networkStack: NetworkStack
    ) {
        self.networkStack = networkStack
        super.init(parent: parent)
    }

    @MainActor var view: DetermineAuthMethodView {
        DetermineAuthMethodView(
            viewModel: viewModel,
            factory: self
        )
    }

    @MainActor private var viewModel: DetermineAuthMethodViewModel {
        DetermineAuthMethodViewModel(
            router: dependency.router,
            factory: self,
            bridge: dependency.bridge,
            environmentType: dependency.environmentType,
            backendConfig: dependency.backendConfig,
            backendMetadata: nil,
            canExitFlow: dependency.existsAnotherAccount
        )
    }

    // MARK: - Children

    func loginViaEmailComponent(
        email: String?,
        canCreateAccount: Bool,
        didDetectDomainConflict: Bool,
        environmentType: BackendEnvironmentType,
        backendConfig: BackendConfig
    ) -> LoginViaEmailComponent {
        let networkStack = NetworkStack(
            environmentType: environmentType,
            backendConfig: backendConfig,
            minTLSVersion: dependency.minTLSVersion,
            preferredAPIVersion: dependency.preferredAPIVersion
        )
        return LoginViaEmailComponent(
            parent: self,
            email: email,
            canCreateAccount: canCreateAccount,
            didDetectDomainConflict: didDetectDomainConflict,
            networkStack: networkStack
        )
    }

    func loginViaSSOComponent(ssoURL: URL) -> LoginViaSSOComponent {
        LoginViaSSOComponent(
            parent: self,
            ssoURL: ssoURL
        )
    }

    func noHistoryComponent(authenticationResult: AuthenticationResult) -> NoHistoryComponent {
        NoHistoryComponent(
            parent: self,
            authenticationResult: authenticationResult,
            didDetectDomainConflict: false
        )
    }

}

extension DetermineAuthMethodComponent: DetermineAuthMethodViewModel.Factory {

    func validateEmailOrSSOCodeUseCase() -> any ValidateEmailOrSSOCodeUseCaseProtocol {
        ValidateEmailOrSSOCodeUseCase()
    }

    func determineAuthMethodUseCase() async throws -> any DetermineAuthMethodUseCaseProtocol {
        let authenticationAPI = try await networkStack.makeAuthenticationAPI()
        return DetermineAuthMethodUseCase(
            validateEmailOrSSOCode: validateEmailOrSSOCodeUseCase(),
            authenticationAPI: authenticationAPI,
            urlSession: URLSession.shared
        )
    }

    func ssoLinkGenerator() async throws -> any SSOLinkGeneratorProtocol {
        let authenticationAPI = try await networkStack.makeAuthenticationAPI()
        return SSOLinkGenerator(
            authenticationAPI: authenticationAPI,
            baseURL: dependency.backendConfig.endpoints.backendURL,
            callbackScheme: dependency.ssoCallbackURLScheme,
            defaults: dependency.userDefaults
        )
    }

    func fetchBackendConfigUseCase() -> any FetchBackendConfigUseCaseProtocol {
        FetchBackendConfigUseCase()
    }

    func fetchSSOURLUseCase(
        environmentType: BackendEnvironmentType,
        backendConfig: BackendConfig
    ) async throws -> any FetchSSOURLUseCaseProtocol {
        let networkStack = NetworkStack(
            environmentType: environmentType,
            backendConfig: backendConfig,
            minTLSVersion: dependency.minTLSVersion,
            preferredAPIVersion: dependency.preferredAPIVersion
        )
        let authenticationAPI = try await networkStack.makeAuthenticationAPI()
        let linkGenerator = SSOLinkGenerator(
            authenticationAPI: authenticationAPI,
            baseURL: backendConfig.endpoints.backendURL,
            callbackScheme: dependency.ssoCallbackURLScheme,
            defaults: dependency.userDefaults
        )
        return FetchSSOURLUseCase(
            authenticationAPI: authenticationAPI,
            linkGenerator: linkGenerator
        )
    }

}

extension DetermineAuthMethodComponent: DetermineAuthMethodView.Factory {

    @MainActor
    func loginViaEmailView(
        email: String?,
        canCreateAccount: Bool,
        didDetectDomainConflict: Bool,
        environmentType: BackendEnvironmentType,
        backendConfig: BackendConfig
    ) -> LoginViaEmailView {
        loginViaEmailComponent(
            email: email,
            canCreateAccount: canCreateAccount,
            didDetectDomainConflict: didDetectDomainConflict,
            environmentType: environmentType,
            backendConfig: backendConfig
        ).view
    }

    func loginViaSSOView(ssoURL: URL) -> LoginViaSSOView {
        loginViaSSOComponent(ssoURL: ssoURL).view
    }

    func noHistoryView(authenticationResult: AuthenticationResult) -> NoHistoryView {
        noHistoryComponent(authenticationResult: authenticationResult).view
    }

}

// TODO: [WPB-16272] remove when API version is deduplicated.
extension WireAPI.APIVersion {

    init(_ apiVersion: WireAuthenticationAPI.BackendMetadata.APIVersion) {
        switch apiVersion {
        case .v0:
            self = .v0
        case .v1:
            self = .v1
        case .v2:
            self = .v2
        case .v3:
            self = .v3
        case .v4:
            self = .v4
        case .v5:
            self = .v5
        case .v6:
            self = .v6
        case .v7:
            self = .v7
        case .v8:
            self = .v8
        }
    }

}

// TODO: move this somewhere else
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
