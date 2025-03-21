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

protocol LoginViaEmailNewComponentDependency: Dependency {

    @MainActor var router: any Router { get }
    @MainActor var bridge: WireAuthenticationBridge { get }
    //var networkService: NetworkService { get }
    var preferredAPIVersion: APIVersion? { get }
    var environmentType: BackendEnvironmentType { get }
    var backendConfig: BackendConfig { get }
    var minTLSVersion: TLSVersion { get }
    var appStoreURL: URL { get }

}

class LoginViaEmailNewComponent: Component<LoginViaEmailNewComponentDependency> {

    private let email: String?
    private let environmentType: BackendEnvironmentType
    private let backendConfig: BackendConfig
    private let backendMetadata: BackendMetadata

    init(
        parent: any Scope,
        email: String?,
        environmentType: BackendEnvironmentType,
        backendConfig: BackendConfig,
        backendMetadata: BackendMetadata
    ) {
        self.email = email
        self.environmentType = environmentType
        self.backendConfig = backendConfig
        self.backendMetadata = backendMetadata
        super.init(parent: parent)
    }

    // MARK: - View

    @MainActor
    func view(
        canCreateAccount: Bool,
        didDetectDomainConflict: Bool
    ) -> LoginViaEmailViewNew {
        LoginViaEmailViewNew(
            viewModel: viewModel(
                email: email,
                canCreateAccount: canCreateAccount,
                didDetectDomainConflict: didDetectDomainConflict
            )
        )
    }

    @MainActor
    private func viewModel(
        email: String?,
        canCreateAccount: Bool,
        didDetectDomainConflict: Bool
    ) -> LoginViaEmailViewModelNew {
        LoginViaEmailViewModelNew(
            router: dependency.router,
            factory: self,
            email: email,
            environmentType: environmentType,
            backendConfig: backendConfig,
            backendMetadata: backendMetadata,
            canCreateAccount: canCreateAccount,
            didDetectDomainConflict: didDetectDomainConflict,
            onCreateAccount: { [dependency, backendEnvironment] in
                guard let dependency else { return }
                dependency.router.dismissSheet()
                dependency.bridge.sendOutboundEvent(
                    .accountRegistrationRequested(
                        email: email ?? "",
                        backendEnvironment
                    )
                )
            }
        )
    }

    private var backendEnvironment: WireAuthenticationBackendEnvironment {
        shared {
            WireAuthenticationBackendEnvironment(
                environmentType: environmentType,
                config: backendConfig,
                metadata: backendMetadata
            )
        }
    }

    // MARK: - Private dependencies

    private var networkService: NetworkService {
        shared {
            NetworkService.make(
                backendEnvironment: BackendEnvironment(backendConfig),
                minTLSVersion: dependency.minTLSVersion
            )
        }
    }

    // MARK: - Children

//    var verificationCodeComponent: VerificationCodeComponent {
//        VerificationCodeComponent(parent: self)
//    }

}

extension LoginViaEmailNewComponent: LoginViaEmailViewModelNew.Factory {

    func loginViaEmailUseCase(apiVersion: BackendMetadata.APIVersion) -> any LoginViaEmailUseCaseProtocol {
        let api = AuthenticationAPIBuilder(networkService: networkService).makeAPI(
            for: .init(apiVersion)
        )
        return LoginViaEmailUseCase(authenticationAPI: api)
    }
    
    func openAppStoreUseCase() -> any OpenAppStoreUseCaseProtocol {
        OpenAppStoreUseCase(url: dependency.appStoreURL)
    }
    
    func resolveBackendMetadataUseCase() -> any ResolveBackendMetadataUseCaseProtocol {
        let api = BackendMetadataAPIBuilder(networkService: networkService).makeAPI()
        return ResolveBackendMetadataUseCase(
            backendMetadataAPI: api,
            clientProductionVersions: APIVersion.productionVersions,
            preferredAPIVersion: dependency.preferredAPIVersion
        )
    }
    
}
