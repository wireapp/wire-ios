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
import WireAuthenticationDomain
import WireLogging
internal import WireAuthenticationUI
internal import WireAuthenticationData

protocol DetermineAuthMethodComponentDependency: Dependency {

    @MainActor var router: any Router { get }
    @MainActor var bridge: WireAuthenticationBridge { get }
    var preferredAPIVersion: APIVersion? { get }
    var minTLSVersion: TLSVersion { get }
    var ssoCallbackURLScheme: String { get }
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

    // MARK: - Children

    func loginViaEmailComponent(
        email: String?,
        canCreateAccount: Bool,
        didDetectDomainConflict: Bool,
        backendInfo: BackendInfo
    ) -> LoginViaEmailComponent {
        let networkStack = NetworkStack(
            backendInfo: backendInfo,
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

    func noHistoryComponent(authenticationResult: AuthenticationResult) -> NoHistoryComponent {
        NoHistoryComponent(
            parent: self,
            authenticationResult: authenticationResult,
            didDetectDomainConflict: false
        )
    }

}

extension DetermineAuthMethodComponent: DetermineAuthMethodViewModel.Factory {

    // MARK: Factory

    @MainActor var viewModel: DetermineAuthMethodViewModel {
        DetermineAuthMethodViewModel(
            factory: self,
            router: dependency.router,
            bridge: dependency.bridge,
            backendInfo: networkStack.backendInfo,
            existsAnotherAccount: dependency.existsAnotherAccount
        )
    }

    func loginViaEmailFactory(
        email: String?,
        canCreateAccount: Bool,
        didDetectDomainConflict: Bool,
        backendInfo: BackendInfo
    ) -> any WireAuthenticationUI.LoginViaEmailFactory {
        loginViaEmailComponent(
            email: email,
            canCreateAccount: canCreateAccount,
            didDetectDomainConflict: didDetectDomainConflict,
            backendInfo: backendInfo
        )
    }

    func noHistoryFactory(authenticationResult: AuthenticationResult) -> any NoHistoryFactory {
        noHistoryComponent(authenticationResult: authenticationResult)
    }

    // MARK: Use cases

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

    func fetchBackendConfigUseCase() -> any FetchBackendConfigUseCaseProtocol {
        FetchBackendConfigUseCase()
    }

    @MainActor
    func loginViaSSOUseCase(backendInfo: BackendInfo?) async throws -> any LoginViaSSOUseCaseProtocol {
        let networkStack: NetworkStack = if let backendInfo {
            NetworkStack(
                backendInfo: backendInfo,
                minTLSVersion: dependency.minTLSVersion,
                preferredAPIVersion: dependency.preferredAPIVersion
            )
        } else {
            self.networkStack
        }

        let authenticationAPI = try await networkStack.makeAuthenticationAPI()

        return LoginViaSSOUseCase(
            authenticationAPI: authenticationAPI,
            baseURL: networkStack.backendInfo.backendConfig.endpoints.backendURL,
            ssoCallbackURLScheme: dependency.ssoCallbackURLScheme,
            verificationTokenGenerator: SSOLoginVerificationTokenGenerator(),
            webAuthenticator: WebAuthenticator(ssoCallbackURLScheme: dependency.ssoCallbackURLScheme),
            createAuthResultUseCase: CreateAuthenticationResultUseCase(
                backendEnvironmentProvider: { [networkStack] in
                    try await networkStack.makeBackendEnvironment()
                }
            )
        )
    }

}

import WireAPI

extension NetworkStack {
    
    private var networkService: NetworkService {
        get throws {
            switch state {
            case .awaitingProxyCredentials:
                throw ProxyModeError.proxyCredentialsRequired
            case let .ready(networkService):
                networkService
            }
        }
    }

    package func makeAuthenticationAPI() async throws -> some AuthenticationAPIRepository {
        let apiVersion = try await resolvedAPIVersion()
        return AuthenticationAPIRepositoryAdapter(api: AuthenticationAPIBuilder(
            networkService: try networkService
        )
        .makeAPI(for: apiVersion))
    }
    
    private func resolvedAPIVersion() async throws -> APIVersion {
        let backendMetadata = try await resolvedBackendMetadata()
        return APIVersion(backendMetadata.apiVersion)
    }

    private func resolvedBackendMetadata() async throws -> WireAuthenticationDomain.BackendMetadata {
        if let backendMetadata {
            return backendMetadata
        }

        let api = BackendMetadataAPIBuilder(networkService: try networkService).makeAPI()

        let useCase = ResolveBackendMetadataUseCase(
            backendMetadataAPI: api,
            clientProductionVersions: APIVersion.productionVersions,
            preferredAPIVersion: preferredAPIVersion
        )

        let backendMetadata = try await useCase.invoke()
        self.backendMetadata = backendMetadata
        return backendMetadata
    }

    package func makeBackendEnvironment() async throws -> WireAuthenticationBackendEnvironment {
        let backendMetadata = try await resolvedBackendMetadata()

        var resolvedProxySettings: ResolvedProxySettings?
        if let proxySettings = backendInfo.backendConfig.proxySettings {
            if proxySettings.needsAuthentication {
                guard let proxyCredentials else {
                    throw ProxyModeError.proxyCredentialsRequired
                }

                resolvedProxySettings = .authenticated(
                    host: proxySettings.host,
                    port: proxySettings.port,
                    username: proxyCredentials.username,
                    password: proxyCredentials.password
                )
            } else {
                resolvedProxySettings = .unauthenticated(
                    host: proxySettings.host,
                    port: proxySettings.port
                )
            }
        }

        return WireAuthenticationBackendEnvironment(
            environmentType: backendInfo.environmentType,
            config: backendInfo.backendConfig,
            metadata: backendMetadata,
            proxySettings: resolvedProxySettings
        )
    }

}

private extension APIVersion {

    init(_ apiVersion: WireAuthenticationDomain.BackendMetadata.APIVersion) {
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
