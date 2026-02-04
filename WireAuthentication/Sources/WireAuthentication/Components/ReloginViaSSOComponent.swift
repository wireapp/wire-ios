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

import Foundation
import NeedleFoundation
import WireAuthenticationAPI
internal import WireAuthenticationUI
internal import WireAuthenticationLogic
import WireNetwork

protocol ReloginViaSSOComponentDependency: Dependency {

    @MainActor var router: any Router { get }
    @MainActor var bridge: WireAuthenticationBridge { get }
    var preferredAPIVersion: APIVersion? { get }
    var minTLSVersion: TLSVersion { get }
    var ssoCallbackURLScheme: String { get }

}

final class ReloginViaSSOComponent: Component<ReloginViaSSOComponentDependency> {

    private let networkStack: NetworkStack
    public let didReauthenticate: Bool = true
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

    // MARK: - Children

    private func noHistoryFactory(result: AuthenticationResult) -> NoHistoryComponent {
        NoHistoryComponent(
            parent: self,
            authenticationResult: result,
            didDetectDomainConflict: false
        )
    }

}

extension ReloginViaSSOComponent: ReloginViaSSOViewModel.Factory {

    // MARK: - Factory

    var viewModel: ReloginViaSSOViewModel {
        ReloginViaSSOViewModel(
            factory: self,
            router: dependency.router,
            bridge: dependency.bridge,
            environment: networkStack.backendEnvironment,
            existsAnotherAccount: existsAnotherAccount
        )
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
    
    @MainActor
    func validateSSOCodeUseCase() -> any ValidateSSOCodeUseCaseProtocol {
        return ValidataSSOCodeUseCase()
    }

    @MainActor
    func noHistoryView(result: AuthenticationResult) -> NoHistoryView {
        let factory = noHistoryFactory(result: result)
        return NoHistoryView(factory: factory)
    }

}
