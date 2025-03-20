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

protocol DetermineAuthMethodComponentDependency: Dependency {

    @MainActor var router: any Router { get }
    @MainActor var bridge: WireAuthenticationBridge { get }
    var environmentType: BackendEnvironmentType { get }
    var backendConfig: BackendConfig { get }
    var preferredAPIVersion: APIVersion? { get }
    var minTLSVersion: TLSVersion { get }
    var ssoCallbackURLScheme: String { get }
    var userDefaults: UserDefaults { get }
    var appStoreURL: URL { get }
    var existsAnotherAccount: Bool { get }

}

class DetermineAuthMethodComponent: Component<DetermineAuthMethodComponentDependency> {

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

    @MainActor var view: DetermineAuthMethodView {
        DetermineAuthMethodView(
            viewModel: viewModel,
            factory: self
        )
    }

    public var networkService: NetworkService {
        shared {
            NetworkService.make(
                backendEnvironment: .init(dependency.backendConfig),
                minTLSVersion: dependency.minTLSVersion
            )
        }
    }

    // MARK: - Children

    func loginViaEmailComponent(backendMetadata: BackendMetadata) -> LoginViaEmailComponent {
        LoginViaEmailComponent(
            parent: self,
            environmentType: dependency.environmentType,
            backendConfig: dependency.backendConfig,
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

extension DetermineAuthMethodComponent: DetermineAuthMethodViewModel.Factory {

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
            baseURL: dependency.backendConfig.endpoints.backendURL,
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

extension DetermineAuthMethodComponent: DetermineAuthMethodView.Factory {

    @MainActor
    func loginViaEmailView(
        email: String,
        canCreateAccount: Bool,
        didDetectDomainConflict: Bool,
        environmentType: BackendEnvironmentType,
        backendConfig: BackendConfig,
        backendMetadata: BackendMetadata
    ) -> LoginViaEmailView {
        loginViaEmailComponent(backendMetadata: backendMetadata).view(
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
