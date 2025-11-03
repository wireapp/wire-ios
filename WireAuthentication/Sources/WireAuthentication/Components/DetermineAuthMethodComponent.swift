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
import WireAuthenticationAPI
import WireLegacyLogging
import WireNetwork
internal import WireAuthenticationUI
internal import WireAuthenticationLogic

protocol DetermineAuthMethodComponentDependency: Dependency {

    @MainActor var router: any Router { get }
    @MainActor var bridge: WireAuthenticationBridge { get }
    var preferredAPIVersion: APIVersion? { get }
    var minTLSVersion: TLSVersion { get }
    var ssoCallbackURLScheme: String { get }
    var isMultibackendEnabled: Bool { get }

}

final class DetermineAuthMethodComponent: Component<DetermineAuthMethodComponentDependency> {

    public let networkStack: NetworkStack
    public let didReauthenticate: Bool = false
    private let existsAnotherAccount: Bool

    init(
        parent: any Scope,
        networkStack: NetworkStack,
        existsAnotherAccount: Bool
    ) {
        self.networkStack = networkStack
        self.existsAnotherAccount = existsAnotherAccount
        super.init(parent: parent)
    }

}

extension DetermineAuthMethodComponent: DetermineAuthMethodViewModel.Factory {

    @MainActor
    func loginView(
        email: String?,
        didDetectDomainConflict: Bool,
        environment: BackendEnvironment2
    ) -> LoginViaEmailView {
        let factory = loginViaEmailFactory(
            email: email,
            canCreateAccount: false,
            didDetectDomainConflict: didDetectDomainConflict,
            environment: environment
        )
        return LoginViaEmailView(factory: factory)
    }

    @MainActor
    func loginOrRegisterView(
        email: String?,
        didDetectDomainConflict: Bool,
        environment: BackendEnvironment2
    ) -> LoginViaEmailView {
        let factory = loginViaEmailFactory(
            email: email,
            canCreateAccount: true,
            didDetectDomainConflict: didDetectDomainConflict,
            environment: environment
        )
        return LoginViaEmailView(factory: factory)
    }

    @MainActor
    func noHistoryView(result: AuthenticationResult) -> NoHistoryView {
        let factory = noHistoryFactory(authenticationResult: result)
        return NoHistoryView(factory: factory)
    }

    @MainActor var viewModel: DetermineAuthMethodViewModel {
        DetermineAuthMethodViewModel(
            factory: self,
            router: dependency.router,
            bridge: dependency.bridge,
            environment: networkStack.backendEnvironment,
            existsAnotherAccount: existsAnotherAccount,
            isMultibackendEnabled: dependency.isMultibackendEnabled
        )
    }

    private func loginViaEmailFactory(
        email: String?,
        canCreateAccount: Bool,
        didDetectDomainConflict: Bool,
        environment: BackendEnvironment2
    ) -> any WireAuthenticationUI.LoginViaEmailFactory {
        let networkStack = NetworkStack(
            backendEnvironment: environment,
            minTLSVersion: dependency.minTLSVersion,
            preferredAPIVersion: dependency.preferredAPIVersion,
            proxyCredentials: nil
        )
        return LoginViaEmailComponent(
            parent: self,
            email: email,
            canCreateAccount: canCreateAccount,
            didDetectDomainConflict: didDetectDomainConflict,
            networkStack: networkStack
        )
    }

    private func noHistoryFactory(authenticationResult: AuthenticationResult) -> any NoHistoryFactory {
        NoHistoryComponent(
            parent: self,
            authenticationResult: authenticationResult,
            didDetectDomainConflict: false
        )
    }

    // MARK: Use cases

    func validateEmailOrSSOCodeUseCase() -> any ValidateEmailOrSSOCodeUseCaseProtocol {
        ValidateEmailOrSSOCodeUseCase()
    }

    func determineAuthMethodUseCase() async throws -> any DetermineAuthMethodUseCaseProtocol {
        let authenticationAPI = try await networkStack.makeAuthenticationAPI()
        return DetermineAuthMethodUseCase(
            validateEmailOrSSOCode: validateEmailOrSSOCodeUseCase(),
            authenticationAPI: authenticationAPI,
            urlSession: URLSession.shared
        )
    }

    func fetchBackendConfigUseCase() -> any FetchBackendConfigUseCaseProtocol {
        FetchBackendConfigUseCase()
    }

    @MainActor
    func loginViaSSOUseCase(environment: BackendEnvironment2?) async throws -> any LoginViaSSOUseCaseProtocol {
        let networkStack: NetworkStack = if let environment {
            NetworkStack(
                backendEnvironment: environment,
                minTLSVersion: dependency.minTLSVersion,
                preferredAPIVersion: dependency.preferredAPIVersion,
                proxyCredentials: nil
            )
        } else {
            self.networkStack
        }

        let authenticationAPI = try await networkStack.makeAuthenticationAPI()

        return LoginViaSSOUseCase(
            authenticationAPI: authenticationAPI,
            baseURL: networkStack.backendEnvironment.config.endpoints.restAPIURL,
            ssoCallbackURLScheme: dependency.ssoCallbackURLScheme,
            verificationTokenGenerator: SSOLoginVerificationTokenGenerator(),
            webAuthenticator: WebAuthenticator(ssoCallbackURLScheme: dependency.ssoCallbackURLScheme),
            createAuthResultUseCase: CreateAuthenticationResultUseCase(networkStack: networkStack)
        )
    }

}
