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

protocol DetermineAuthMethodOnPremComponentDependency: Dependency {

    @MainActor var router: any Router { get }
    @MainActor var bridge: WireAuthenticationBridge { get }
    var preferredAPIVersion: APIVersion? { get }
    var minTLSVersion: TLSVersion { get }
    var ssoCallbackURLScheme: String { get }
    var userDefaults: UserDefaults { get }
    var appStoreURL: URL { get }
    var existsAnotherAccount: Bool { get }

}

class DetermineAuthMethodOnPremComponent: Component<DetermineAuthMethodOnPremComponentDependency> {
    private let environmentType: BackendEnvironmentType
    private let backendConfig: BackendConfig
    private let backendMetadata: BackendMetadata?

    init(
        parent: any Scope,
        environmentType: BackendEnvironmentType,
        backendConfig: BackendConfig,
        backendMetadata: BackendMetadata?
    ) {
        self.environmentType = environmentType
        self.backendConfig = backendConfig
        self.backendMetadata = backendMetadata
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
            environmentType: environmentType,
            backendConfig: backendConfig,
            backendMetadata: backendMetadata,
            canExitFlow: dependency.existsAnotherAccount
        )
    }

    public var networkService: NetworkService {
        shared {
            NetworkService.make(
                backendEnvironment: .init(backendConfig),
                minTLSVersion: dependency.minTLSVersion
            )
        }
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
            minTLSVersion: dependency.minTLSVersion
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

    func switchBackendConfirmationComponent(
        email: String?,
        environmentType: BackendEnvironmentType,
        backendConfig: BackendConfig
    ) -> SwitchBackendConfirmationComponent {
        SwitchBackendConfirmationComponent(
            parent: self,
            email: email,
            environmentType: environmentType,
            backendConfig: backendConfig
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

extension DetermineAuthMethodOnPremComponent: DetermineAuthMethodViewModel.Factory {

    func validateEmailOrSSOCodeUseCase() -> any ValidateEmailOrSSOCodeUseCaseProtocol {
        ValidateEmailOrSSOCodeUseCase()
    }

    func determineAuthMethodUseCase() async throws -> any DetermineAuthMethodUseCaseProtocol {
        fatalError()
    }

    func determineAuthMethodUseCase(
        apiVersion: WireAuthenticationAPI.BackendMetadata.APIVersion
    ) -> any DetermineAuthMethodUseCaseProtocol {
        let authenticationAPI = AuthenticationAPIBuilder(networkService: networkService).makeAPI(
            for: .init(apiVersion)
        )
        return DetermineAuthMethodUseCase(
            validateEmailOrSSOCode: validateEmailOrSSOCodeUseCase(),
            authenticationAPI: authenticationAPI,
            urlSession: URLSession.shared
        )
    }

    func resolveBackendMetadataUseCase() -> any ResolveBackendMetadataUseCaseProtocol {
        let api = BackendMetadataAPIBuilder(networkService: networkService).makeAPI()
        return ResolveBackendMetadataUseCase(
            backendMetadataAPI: api,
            clientProductionVersions: APIVersion.productionVersions,
            preferredAPIVersion: dependency.preferredAPIVersion
        )
    }

    func ssoLinkGenerator(
        apiVersion: WireAuthenticationAPI.BackendMetadata.APIVersion
    ) -> any SSOLinkGeneratorProtocol {
        let authenticationAPI = AuthenticationAPIBuilder(networkService: networkService).makeAPI(
            for: .init(apiVersion)
        )
        return SSOLinkGenerator(
            authenticationAPI: authenticationAPI,
            baseURL: backendConfig.endpoints.backendURL,
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
            minTLSVersion: dependency.minTLSVersion
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

    func openAppStoreUseCase() -> any OpenAppStoreUseCaseProtocol {
        OpenAppStoreUseCase(url: dependency.appStoreURL)
    }

}

extension DetermineAuthMethodOnPremComponent: DetermineAuthMethodView.Factory {
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

    func switchBackendView(
        email: String?,
        environmentType: BackendEnvironmentType,
        backendConfig: BackendConfig
    ) -> SwitchBackendConfirmationView {
        switchBackendConfirmationComponent(
            email: email,
            environmentType: environmentType,
            backendConfig: backendConfig
        ).view
    }

    func noHistoryView(authenticationResult: AuthenticationResult) -> NoHistoryView {
        noHistoryComponent(authenticationResult: authenticationResult).view
    }

}
