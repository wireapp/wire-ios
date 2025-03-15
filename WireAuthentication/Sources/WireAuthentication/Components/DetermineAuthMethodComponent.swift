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

protocol DetermineAuthMethodComponentDependency: Dependency {

    // FIXME: Adjust as necessary
//    @MainActor var router: any Router { get }
//    var environmentType: BackendEnvironmentType { get }
//    var backendConfig: BackendConfig { get }
//    var preferredAPIVersion: APIVersion? { get }
//    var minTLSVersion: TLSVersion { get }
//    var ssoCallbackURLScheme: String { get }
//    var userDefaults: UserDefaults { get }

}

class DetermineAuthMethodComponent: Component<DetermineAuthMethodComponentDependency> {

    private let router: any Router
    private let environmentType: BackendEnvironmentType
    private let backendConfig: BackendConfig
    private let preferredAPIVersion: APIVersion?
    private let productionVersions: Set<APIVersion>
    private let minTLSVersion: TLSVersion
    private let ssoCallbackURLScheme: String
    private let userDefaults: UserDefaults
    private let bridge: WireAuthenticationBridge
    private let passwordValidator: any PasswordValidator

    init(
        parent: any Scope,
        router: any Router,
        environmentType: BackendEnvironmentType,
        backendConfig: BackendConfig,
        preferredAPIVersion: APIVersion?,
        productionVersions: Set<APIVersion>,
        minTLSVersion: TLSVersion,
        ssoCallbackURLScheme: String,
        userDefaults: UserDefaults,
        bridge: WireAuthenticationBridge,
        passwordValidator: any PasswordValidator
    ) {
        self.router = router
        self.environmentType = environmentType
        self.backendConfig = backendConfig
        self.preferredAPIVersion = preferredAPIVersion
        self.productionVersions = productionVersions
        self.minTLSVersion = minTLSVersion
        self.ssoCallbackURLScheme = ssoCallbackURLScheme
        self.userDefaults = userDefaults
        self.bridge = bridge
        self.passwordValidator = passwordValidator

        super.init(parent: parent)
    }

    @MainActor private var viewModel: DetermineAuthMethodViewModel {
        DetermineAuthMethodViewModel(
            router: router,
            factory: self,
            environmentType: environmentType,
            backendConfig: backendConfig
        )
    }

    @MainActor var view: DetermineAuthMethodView {
        DetermineAuthMethodView(
            viewModel: viewModel,
            factory: self
        )
    }


    // MARK: - Children

    func loginViaEmailComponent(
        email: String,
        backendMetadata: WireAuthenticationAPI.BackendMetadata
    ) -> LoginViaEmailComponent {
        LoginViaEmailComponent(
            parent: self,
            email: email,
            environmentType: environmentType,
            backendConfig: backendConfig,
            backendMetadata: backendMetadata,
            router: router,
            passwordValidator: passwordValidator,
            bridge: bridge,
            preferredAPIVersion: preferredAPIVersion,
            networkService: networkService
        )
    }

    func loginViaSSOComponent(
        ssoURL: URL,
        backendEnvironment: WireAuthenticationBackendEnvironment
    ) -> LoginViaSSOComponent {
        LoginViaSSOComponent(
            parent: self,
            ssoURL: ssoURL,
            backendEnvironment: backendEnvironment,
            router: router,
            bridge: bridge
        )
    }

    func switchBackendConfirmationComponent(
        email: String,
        environmentType: BackendEnvironmentType,
        backendConfig: BackendConfig
    ) -> SwitchBackendConfirmationComponent {
        SwitchBackendConfirmationComponent(
            parent: self,
            email: email,
            environmentType: environmentType,
            backendConfig: backendConfig,
            router: router,
            preferredAPIVersion: preferredAPIVersion,
            productionVersions: productionVersions,
            minTLSVersion: minTLSVersion,
            ssoCallbackURLScheme: ssoCallbackURLScheme,
            userDefaults: userDefaults
        )
    }

    // MARK: Private helpers

    public var networkService: any NetworkServiceProtocol {
        assert(backendConfig.proxySettings?.needsAuthentication != true, "Proxy auth isn't supported from here")

        return shared {
            NetworkService.make(
                backendEnvironment: .makeWithoutProxyAuthentication(backendConfig),
                minTLSVersion: minTLSVersion
            )
        }
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
            preferredAPIVersion: preferredAPIVersion
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
            callbackScheme: ssoCallbackURLScheme,
            defaults: userDefaults
        )
    }

    func fetchBackendConfigUseCase() -> any FetchBackendConfigUseCaseProtocol {
        FetchBackendConfigUseCase()
    }

}

extension DetermineAuthMethodComponent: DetermineAuthMethodView.Factory {

    @MainActor
    func loginViaEmailView(
        email: String,
        canCreateAccount: Bool,
        didDetectDomainConflict: Bool,
        backendMetadata: WireAuthenticationAPI.BackendMetadata
    ) -> LoginViaEmailView {
        loginViaEmailComponent(email: email, backendMetadata: backendMetadata).view(
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
        email: String,
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
