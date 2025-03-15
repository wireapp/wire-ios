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

protocol LoginViaEmailOnPremComponentDependency: Dependency {

    // FIXME: Adjust as necessary
//    @MainActor var router: any Router { get }
//    @MainActor var bridge: WireAuthenticationBridge { get }
//    var preferredAPIVersion: APIVersion? { get }
//    var minTLSVersion: TLSVersion { get }
//    var passwordValidator: any PasswordValidator { get }

}

class LoginViaEmailOnPremComponent: Component<LoginViaEmailOnPremComponentDependency> {

    private let email: String
    private let environmentType: BackendEnvironmentType
    private let backendConfig: BackendConfig
    private let backendMetadata: WireAuthenticationAPI.BackendMetadata?
    private let router: any Router
    private let configurableNetworkService: ConfigurableNetworkService
    private let passwordValidator: any PasswordValidator
    private let bridge: WireAuthenticationBridge
    private let preferredAPIVersion: APIVersion?

    init(
        parent: any Scope,
        email: String,
        environmentType: BackendEnvironmentType,
        backendConfig: BackendConfig,
        backendMetadata: WireAuthenticationAPI.BackendMetadata?,
        router: any Router,
        minTLSVersion: TLSVersion,
        passwordValidator: any PasswordValidator,
        bridge: WireAuthenticationBridge,
        preferredAPIVersion: APIVersion?
    ) {
        self.email = email
        self.environmentType = environmentType
        self.backendConfig = backendConfig
        self.backendMetadata = backendMetadata
        self.router = router
        self.configurableNetworkService = ConfigurableNetworkService(minTLSVersion: minTLSVersion)
        self.passwordValidator = passwordValidator
        self.bridge = bridge
        self.preferredAPIVersion = preferredAPIVersion

        super.init(parent: parent)
    }

    // MARK: - View

    @MainActor var view: LoginViaEmailOnPremView {
        LoginViaEmailOnPremView(viewModel: viewModel, factory: self)
    }

    @MainActor private var viewModel: LoginViaEmailViewModel {
        LoginViaEmailViewModel(
            router: router,
            factory: self,
            environmentType: environmentType,
            email: email,
            backendConfig: backendConfig,
            backendMetadata: backendMetadata,
            passwordValidator: passwordValidator,
            canCreateAccount: false,
            didDetectDomainConflict: false,
            onCreateAccount: { [weak bridge] in
                bridge?.registerAccount()
            },
            applyProxyCredentials: { [configurableNetworkService, backendConfig] username, password in
                configurableNetworkService.configure(
                    with: ResolvedBackendConfig(
                        title: backendConfig.title,
                        endpoints: backendConfig.endpoints,
                        proxySettings: backendConfig.proxySettings.map {
                            .authenticated(host: $0.host, port: $0.port, username: username, password: password)
                        },
                        pinnedKeys: backendConfig.pinnedKeys
                    )
                )
            }
        )
    }

    // MARK: - Children

    func verificationCodeComponent(
        backendEnvironment: WireAuthenticationBackendEnvironment
    ) -> VerificationCodeComponent {
        VerificationCodeComponent(
            parent: self,
            router: router,
            authenticationAPI: AuthenticationAPIBuilder(
                networkService: configurableNetworkService
            ).makeAPI(for: APIVersion(backendEnvironment.metadata.apiVersion)),
            backendEnvironment: backendEnvironment
        )
    }

}

extension LoginViaEmailOnPremComponent: LoginViaEmailViewModel.Factory {

    func resolveBackendMetadataUseCase() -> any ResolveBackendMetadataUseCaseProtocol {
        let api = BackendMetadataAPIBuilder(networkService: configurableNetworkService).makeAPI()
        return ResolveBackendMetadataUseCase(
            backendMetadataAPI: api,
            clientProductionVersions: APIVersion.productionVersions,
            preferredAPIVersion: preferredAPIVersion
        )
    }

    func loginViaEmailUseCase(
        apiVersion: WireAuthenticationAPI.BackendMetadata.APIVersion
    ) -> any LoginViaEmailUseCaseProtocol {
        let api = AuthenticationAPIBuilder(networkService: configurableNetworkService).makeAPI(
            for: .init(apiVersion)
        )
        return LoginViaEmailUseCase(authenticationAPI: api)
    }

}

extension LoginViaEmailOnPremComponent: LoginViaEmailView.Factory {

    @MainActor
    func verificationCodeView(
        email: String,
        password: String,
        didDetectDomainConflict: Bool,
        backendEnvironment: WireAuthenticationBackendEnvironment
    ) -> VerificationCodeView {
        verificationCodeComponent(backendEnvironment: backendEnvironment).view(
            email: email,
            password: password,
            didDetectDomainConflict: didDetectDomainConflict
        )
    }

}
