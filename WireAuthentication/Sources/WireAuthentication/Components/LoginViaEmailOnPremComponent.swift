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

    @MainActor var router: any Router { get }
    var preferredAPIVersion: APIVersion? { get }
    var minTLSVersion: TLSVersion { get }
    var passwordValidator: any PasswordValidator { get }

}

class LoginViaEmailOnPremComponent: Component<LoginViaEmailOnPremComponentDependency> {

    private let email: String
    private let backendConfig: BackendConfig
    private let backendMetadata: WireAuthenticationAPI.BackendMetadata?

    init(
        parent: any Scope,
        email: String,
        backendConfig: BackendConfig,
        backendMetadata: WireAuthenticationAPI.BackendMetadata?
    ) {
        self.email = email
        self.backendConfig = backendConfig
        self.backendMetadata = backendMetadata
        super.init(parent: parent)
    }

    // MARK: - View

    @MainActor
    var view: LoginViaEmailOnPremView {
        LoginViaEmailOnPremView(viewModel: viewModel)
    }

    @MainActor
    private var viewModel: LoginViaEmailOnPremViewModel {
        LoginViaEmailOnPremViewModel(
            router: dependency.router,
            factory: self,
            email: email,
            backendConfig: backendConfig,
            backendMetadata: backendMetadata,
            passwordValidator: dependency.passwordValidator,
            canCreateAccount: false
        )
    }

    // MARK: - Private dependencies

    private var backendEnvironment: BackendEnvironment {
        shared {
            BackendEnvironment(backendConfig)
        }
    }

    private var networkService: NetworkService {
        shared {
            NetworkService.make(
                backendEnvironment: backendEnvironment,
                minTLSVersion: dependency.minTLSVersion
            )
        }
    }

}

extension LoginViaEmailOnPremComponent: LoginViaEmailOnPremViewModel.Factory {

    func resolveBackendMetadataUseCase() -> any ResolveBackendMetadataUseCaseProtocol {
        let api = BackendMetadataAPIBuilder(networkService: networkService).makeAPI()
        return ResolveBackendMetadataUseCase(
            backendMetadataAPI: api,
            clientProductionVersions: APIVersion.productionVersions,
            preferredAPIVersion: dependency.preferredAPIVersion
        )
    }

    func loginViaEmailUseCase(apiVersion: WireAuthenticationAPI.BackendMetadata.APIVersion) -> any LoginViaEmailUseCaseProtocol {
        let api = AuthenticationAPIBuilder(networkService: networkService).makeAPI(
            for: .init(apiVersion)
        )
        return LoginViaEmailUseCase(authenticationAPI: api)
    }

}
