//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import WireAuthenticationAPI
import WireNetwork
internal import WireAuthenticationUI
internal import WireAuthenticationLogic
import WireReusableUIComponents

protocol LoginViaEmailComponentDependency: Dependency {

    @MainActor var router: any Router { get }
    @MainActor var bridge: WireAuthenticationBridge { get }
    var preferredAPIVersion: APIVersion? { get }
    var environment: BackendEnvironment2 { get }
    var minTLSVersion: TLSVersion { get }

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

    private func personalAccountCreationComponent(teamAccountCreationLink: URL?) -> PersonalAccountCreationComponent {
        PersonalAccountCreationComponent(
            parent: self,
            email: email ?? "",
            environment: networkStack.backendEnvironment,
            teamAccountCreationLink: teamAccountCreationLink
        )
    }

}

extension LoginViaEmailComponent: LoginViaEmailViewModel.Factory {

    // MARK: - Factory

    @MainActor
    func verifyLoginView(
        email: String,
        password: String,
        proxyCredentials: ProxyCredentials?
    ) -> VerificationCodeView {
        let factory = verificationCodeFactory(
            email: email,
            password: password,
            proxyCredentials: proxyCredentials
        )
        return VerificationCodeView(factory: factory)
    }

    @MainActor
    func noHistoryView(result: AuthenticationResult) -> NoHistoryView {
        let factory = noHistoryFactory(result: result)
        return NoHistoryView(factory: factory)
    }

    @MainActor
    func personalAccountCreationView(teamAccountCreationLink: URL?) -> PersonalAccountCreationView {
        let factory = personalAccountCreationFactory(
            teamAccountCreationLink: teamAccountCreationLink
        )
        return PersonalAccountCreationView(factory: factory)
    }

    @MainActor var viewModel: LoginViaEmailViewModel {
        LoginViaEmailViewModel(
            factory: self,
            router: dependency.router,
            email: email,
            environment: networkStack.backendEnvironment,
            canCreateAccount: canCreateAccount,
            didDetectDomainConflict: didDetectDomainConflict
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

    // MARK: - private

    private func noHistoryFactory(result: AuthenticationResult) -> NoHistoryComponent {
        NoHistoryComponent(
            parent: self,
            authenticationResult: result,
            didDetectDomainConflict: didDetectDomainConflict
        )
    }

    private func verificationCodeFactory(
        email: String,
        password: String,
        proxyCredentials: ProxyCredentials?
    ) -> any VerificationCodeFactory {
        VerificationCodeComponent(
            parent: self,
            email: email,
            password: password,
            proxyCredentials: proxyCredentials
        )
    }

    private func personalAccountCreationFactory(teamAccountCreationLink: URL?) -> any PersonalAccountCreationFactory {
        personalAccountCreationComponent(
            teamAccountCreationLink: teamAccountCreationLink
        )
    }
}
