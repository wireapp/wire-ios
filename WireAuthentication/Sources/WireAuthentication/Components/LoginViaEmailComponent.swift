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

protocol LoginViaEmailComponentDependency: Dependency {

    // FIXME: Adjust as necessary
//    @MainActor var router: any Router { get }
//    var preferredAPIVersion: APIVersion? { get }
//    var backendConfig: BackendConfig { get }
//    var accountsURL: URL { get }
//    var passwordValidator: any PasswordValidator { get }
//    var networkService: any NetworkServiceProtocol { get }
//    var environmentType: BackendEnvironmentType { get }
//    @MainActor var bridge: WireAuthenticationBridge { get }

}

class LoginViaEmailComponent: Component<LoginViaEmailComponentDependency> {

    private let email: String
    private let environmentType: BackendEnvironmentType
    private let backendConfig: BackendConfig
    private let backendMetadata: WireAuthenticationAPI.BackendMetadata
    private let router: any Router
    private let passwordValidator: any PasswordValidator
    private let bridge: WireAuthenticationBridge
    private let preferredAPIVersion: APIVersion?
    private let networkService: any NetworkServiceProtocol

    init(
        parent: any Scope,
        email: String,
        environmentType: BackendEnvironmentType,
        backendConfig: BackendConfig,
        backendMetadata: WireAuthenticationAPI.BackendMetadata,
        router: any Router,
        passwordValidator: any PasswordValidator,
        bridge: WireAuthenticationBridge,
        preferredAPIVersion: APIVersion?,
        networkService: any NetworkServiceProtocol
    ) {
        self.email = email
        self.environmentType = environmentType
        self.backendConfig = backendConfig
        self.backendMetadata = backendMetadata
        self.router = router
        self.passwordValidator = passwordValidator
        self.bridge = bridge
        self.preferredAPIVersion = preferredAPIVersion
        self.networkService = networkService

        super.init(parent: parent)
    }

    // MARK: - View

    @MainActor
    func view(
        email: String,
        canCreateAccount: Bool,
        didDetectDomainConflict: Bool
    ) -> LoginViaEmailView {
        LoginViaEmailView(
            viewModel: viewModel(
                email: email,
                canCreateAccount: canCreateAccount,
                didDetectDomainConflict: didDetectDomainConflict
            ),
            factory: self
        )
    }

    @MainActor
    private func viewModel(
        email: String,
        canCreateAccount: Bool,
        didDetectDomainConflict: Bool
    ) -> LoginViaEmailViewModel {
        LoginViaEmailViewModel(
            router: router,
            factory: self,
            environmentType: environmentType,
            email: email,
            backendConfig: backendConfig,
            backendMetadata: backendMetadata,
            passwordValidator: passwordValidator,
            canCreateAccount: canCreateAccount,
            didDetectDomainConflict: didDetectDomainConflict,
            onCreateAccount: { [weak bridge] in
                bridge?.registerAccount()
            },
            applyProxyCredentials: { _, _ in
                // no op in this component
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
                networkService: networkService
            ).makeAPI(for: APIVersion(backendEnvironment.metadata.apiVersion)),
            backendEnvironment: backendEnvironment
        )
    }

}

extension LoginViaEmailComponent: LoginViaEmailViewModel.Factory {

    func resolveBackendMetadataUseCase() -> any ResolveBackendMetadataUseCaseProtocol {
        let api = BackendMetadataAPIBuilder(networkService: networkService).makeAPI()
        return ResolveBackendMetadataUseCase(
            backendMetadataAPI: api,
            clientProductionVersions: APIVersion.productionVersions,
            preferredAPIVersion: preferredAPIVersion
        )
    }

    func loginViaEmailUseCase(
        apiVersion: WireAuthenticationAPI.BackendMetadata.APIVersion
    ) -> any LoginViaEmailUseCaseProtocol {
        let api = AuthenticationAPIBuilder(networkService: networkService).makeAPI(
            for: .init(apiVersion)
        )
        return LoginViaEmailUseCase(authenticationAPI: api)
    }

}

extension LoginViaEmailComponent: LoginViaEmailView.Factory {

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
