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
    var backendInfo: BackendInfo { get }
    var minTLSVersion: TLSVersion { get }
    var useLegacyRegistrationFlow: Bool { get }

}

final class LoginViaEmailComponent: Component<LoginViaEmailComponentDependency> {

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

    // MARK: - Children

    func verificationCodeComponent(
        email: String,
        password: String,
        proxyCredentials: ProxyCredentials?
    ) -> VerificationCodeComponent {
        VerificationCodeComponent(
            parent: self,
            email: email,
            password: password,
            proxyCredentials: proxyCredentials
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

    func personalAccountCreationComponent() -> PersonalAccountCreationComponent {
        PersonalAccountCreationComponent(
            parent: self
        )
    }

}

extension LoginViaEmailComponent: LoginViaEmailViewModel.Factory {

    // MARK: - Factory

    @MainActor var viewModel: LoginViaEmailViewModel {
        LoginViaEmailViewModel(
            factory: self,
            router: dependency.router,
            email: email,
            backendInfo: networkStack.backendInfo,
            canCreateAccount: canCreateAccount,
            didDetectDomainConflict: didDetectDomainConflict,
            onCreateAccount: dependency.useLegacyRegistrationFlow ? { [dependency, networkStack, email] in
                guard let dependency else { return }
                Task<Void, Never> { @MainActor in
                    do {
                        let backendEnvironment = try await networkStack.makeBackendEnvironment()
                        dependency.router.dismissSheet()
                        dependency.bridge.sendOutboundEvent(
                            .accountRegistrationRequested(
                                email: email,
                                backendEnvironment
                            )
                        )
                    } catch {
                        dependency.router.presentAlert(for: error)
                    }
                }
            } : nil
        )
    }

    func verificationCodeFactory(
        email: String,
        password: String,
        proxyCredentials: ProxyCredentials?
    ) -> any VerificationCodeFactory {
        verificationCodeComponent(
            email: email,
            password: password,
            proxyCredentials: proxyCredentials
        )
    }

    func noHistoryFactory(
        authenticationResult: AuthenticationResult
    ) -> any NoHistoryFactory {
        noHistoryComponent(
            authenticationResult: authenticationResult
        )
    }

    func personalAccountCreationFactory() -> any PersonalAccountCreationFactory {
        personalAccountCreationComponent(
            todo: ()
        )
    }

    // MARK: - Use cases

    func submitProxyCredentialsUseCase() -> any SubmitProxyCredentialsUseCaseProtocol {
        SubmitProxyCredentialsUseCase(networkStack: networkStack)
    }

    func loginViaEmailUseCase() async throws -> any LoginViaEmailUseCaseProtocol {
        let authenticationAPI = try await networkStack.makeAuthenticationAPI()
        return LoginViaEmailUseCase(authenticationAPI: authenticationAPI)
    }

    func createAuthenticationResultUseCase() -> any CreateAuthenticationResultUseCaseProtocol {
        CreateAuthenticationResultUseCase(networkStack: networkStack)
    }

    func validateEmailUseCase() -> any ValidateEmailUseCaseProtocol {
        ValidateEmailUseCase()
    }

}
