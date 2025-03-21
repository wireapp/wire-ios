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

    @MainActor var router: any Router { get }
    var passwordValidator: any PasswordValidator { get }
    var networkService: NetworkService { get }
    var environmentType: BackendEnvironmentType { get }
    var backendConfig: BackendConfig { get }
    var minTLSVersion: TLSVersion { get }
    @MainActor var bridge: WireAuthenticationBridge { get }

}

class LoginViaEmailComponent: Component<LoginViaEmailComponentDependency> {

    private let email: String
    private let canCreateAccount: Bool
    private let didDetectDomainConflict: Bool
    public let networkStack: NetworkStack

    // TODO: delete these
    private let environmentType: BackendEnvironmentType
    private let backendConfig: BackendConfig

    // TODO: delete this temp fix
    private let backendMetadata = BackendMetadata(
        apiVersion: .v8,
        domain: "example.com",
        isFederationEnabled: false
    )

    init(
        parent: any Scope,
        email: String,
        canCreateAccount: Bool,
        didDetectDomainConflict: Bool,
        networkStack: NetworkStack
    ) {
        self.email = email
        self.canCreateAccount = canCreateAccount
        self.didDetectDomainConflict = didDetectDomainConflict
        self.networkStack = networkStack
        self.environmentType = networkStack.environmentType
        self.backendConfig = networkStack.backendConfig
        super.init(parent: parent)
    }

    // TODO: delete
    public var authenticationAPI: any AuthenticationAPI {
        AuthenticationAPIBuilder(networkService: networkService).makeAPI(
            for: .init(backendMetadata.apiVersion)
        )
    }

    // TODO: delete
    public var loginViaEmailUseCase: any LoginViaEmailUseCaseProtocol {
        LoginViaEmailUseCase(authenticationAPI: authenticationAPI)
    }

    // TODO: delete
    private var networkService: NetworkService {
        shared {
            NetworkService.make(
                backendEnvironment: BackendEnvironment(backendConfig),
                minTLSVersion: dependency.minTLSVersion
            )
        }
    }

    // MARK: - View

    @MainActor
    var view: LoginViaEmailView {
        LoginViaEmailView(
            viewModel: viewModel,
            factory: self
        )
    }

    @MainActor
    private var viewModel: LoginViaEmailViewModel {
        LoginViaEmailViewModel(
            router: dependency.router,
            factory: self,
            loginViaEmailUseCase: loginViaEmailUseCase,
            backendEnvironment: backendEnvironment,
            email: email,
            passwordValidator: dependency.passwordValidator,
            canCreateAccount: canCreateAccount,
            didDetectDomainConflict: didDetectDomainConflict,
            onCreateAccount: { [dependency, email, backendEnvironment] in
                guard let dependency else { return }
                dependency.router.dismissSheet()
                dependency.bridge.sendOutboundEvent(
                    .accountRegistrationRequested(
                        email: email,
                        backendEnvironment
                    )
                )
            }
        )
    }

    public var backendEnvironment: WireAuthenticationBackendEnvironment {
        shared {
            WireAuthenticationBackendEnvironment(
                environmentType: environmentType,
                config: backendConfig,
                metadata: backendMetadata
            )
        }
    }

    // MARK: - Children

    var verificationCodeComponent: VerificationCodeComponent {
        VerificationCodeComponent(parent: self)
    }

}

extension LoginViaEmailComponent: LoginViaEmailViewModel.Factory {

    func loginViaEmailUseCase() async throws -> any LoginViaEmailUseCaseProtocol {
        let authenticationAPI = try await networkStack.makeAuthenticationAPI()
        return LoginViaEmailUseCase(authenticationAPI: authenticationAPI)
    }

}

extension LoginViaEmailComponent: LoginViaEmailView.Factory {

    func verificationCodeView(
        email: String,
        password: String,
        didDetectDomainConflict: Bool
    ) -> VerificationCodeView {
        verificationCodeComponent.view(
            email: email,
            password: password,
            didDetectDomainConflict: didDetectDomainConflict
        )
    }

}
