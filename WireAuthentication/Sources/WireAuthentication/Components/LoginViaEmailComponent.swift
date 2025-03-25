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
    @MainActor var bridge: WireAuthenticationBridge { get }
    var preferredAPIVersion: APIVersion? { get }
    var environmentType: BackendEnvironmentType { get }
    var backendConfig: BackendConfig { get }
    var minTLSVersion: TLSVersion { get }

}

class LoginViaEmailComponent: Component<LoginViaEmailComponentDependency> {

    public let email: String?
    private let canCreateAccount: Bool
    public let didDetectDomainConflict: Bool
    public let networkStack: NetworkStack

    init(
        parent: any Scope,
        email: String?,
        canCreateAccount: Bool,
        didDetectDomainConflict: Bool,
        networkStack: NetworkStack
    ) {
        self.email = email
        self.canCreateAccount = canCreateAccount
        self.didDetectDomainConflict = didDetectDomainConflict
        self.networkStack = networkStack
        super.init(parent: parent)
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
            email: email,
            environmentType: networkStack.environmentType,
            backendConfig: networkStack.backendConfig,
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
        WireAuthenticationBackendEnvironment(
            environmentType: networkStack.environmentType,
            config: networkStack.backendConfig,
            metadata: .dummy, // TODO: fix
            proxySettings: nil
        )
    }

    // MARK: - Children

    func verificationCodeComponent(
        email: String,
        password: String
    ) -> VerificationCodeComponent {
        VerificationCodeComponent(
            parent: self,
            email: email,
            password: password
        )
    }

    func noHistoryComponent(
        authenticationResult: AuthenticationResult
    ) -> NoHistoryComponent {
        NoHistoryComponent(
            parent: self,
            authenticationResult: authenticationResult,
            didDetectDomainConflict: didDetectDomainConflict
        )
    }

}

extension LoginViaEmailComponent: LoginViaEmailViewModel.Factory {

    func loginViaEmailUseCase() async throws -> any LoginViaEmailUseCaseProtocol {
        let authenticationAPI = try await networkStack.makeAuthenticationAPI()
        return LoginViaEmailUseCase(authenticationAPI: authenticationAPI)
    }

}

extension LoginViaEmailComponent: LoginViaEmailView.Factory {

    @MainActor
    func verificationCodeView(
        email: String,
        password: String
    ) -> VerificationCodeView {
        verificationCodeComponent(
            email: email,
            password: password
        ).view
    }

    @MainActor
    func noHistoryView(authenticationResult: AuthenticationResult) -> NoHistoryView {
        noHistoryComponent(authenticationResult: authenticationResult).view
    }

}
