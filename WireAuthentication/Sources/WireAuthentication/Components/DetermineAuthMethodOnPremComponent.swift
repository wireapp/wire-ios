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
            environmentType: environmentType,
            backendConfig: backendConfig,
            backendMetadata: backendMetadata,
            bridge: dependency.bridge
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
        environmentType: BackendEnvironmentType,
        backendConfig: BackendConfig,
        backendMetadata: BackendMetadata
    ) -> LoginViaEmailComponent {
        LoginViaEmailComponent(
            parent: self,
            environmentType: environmentType,
            backendConfig: backendConfig,
            backendMetadata: backendMetadata
        )
    }

    func loginViaSSOComponent(
        ssoURL: URL,
        backendEnvironment: WireAuthenticationBackendEnvironment
    ) -> LoginViaSSOComponent {
        LoginViaSSOComponent(
            parent: self,
            ssoURL: ssoURL,
            backendEnvironment: backendEnvironment
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

}

extension DetermineAuthMethodOnPremComponent: DetermineAuthMethodViewModel.Factory {

    func validateEmailOrSSOCodeUseCase() -> any ValidateEmailOrSSOCodeUseCaseProtocol {
        ValidateEmailOrSSOCodeUseCase()
    }

    func determineAuthMethodUseCase(
        apiVersion: WireAuthenticationAPI.BackendMetadata.APIVersion
    ) -> any DetermineAuthMethodUseCaseProtocol {
        let authenticationAPI = AuthenticationAPIBuilder(networkService: networkService).makeAPI(
            for: .init(apiVersion)
        )
        return DetermineAuthMethodUseCase(
            validateEmailOrSSOCode: validateEmailOrSSOCodeUseCase(),
            authenticationAPI: authenticationAPI
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

    func openAppStoreUseCase() -> any OpenAppStoreUseCaseProtocol {
        OpenAppStoreUseCase(url: dependency.appStoreURL)
    }

}

extension DetermineAuthMethodOnPremComponent: DetermineAuthMethodView.Factory {

    @MainActor
    func loginViaEmailView(
        email: String,
        canCreateAccount: Bool,
        didDetectDomainConflict: Bool,
        environmentType: BackendEnvironmentType,
        backendConfig: BackendConfig,
        backendMetadata: BackendMetadata
    ) -> LoginViaEmailView {
        loginViaEmailComponent(
            environmentType: environmentType,
            backendConfig: backendConfig,
            backendMetadata: backendMetadata
        ).view(
            email: email,
            canCreateAccount: canCreateAccount,
            didDetectDomainConflict: didDetectDomainConflict
        )
    }

    func loginViaSSOView(
        ssoURL: URL,
        backendEnvironment: WireAuthenticationBackendEnvironment
    ) -> LoginViaSSOView {
        loginViaSSOComponent(
            ssoURL: ssoURL,
            backendEnvironment: backendEnvironment
        ).view
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

}
