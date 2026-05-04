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

protocol VerificationCodeComponentDependency: Dependency {

    @MainActor var router: any Router { get }
    var networkStack: NetworkStack { get }
    var didDetectDomainConflict: Bool { get }

}

final class VerificationCodeComponent: Component<VerificationCodeComponentDependency> {

    private let email: String
    private let password: String
    private let proxyCredentials: ProxyCredentials?

    init(
        parent: any Scope,
        email: String,
        password: String,
        proxyCredentials: ProxyCredentials?
    ) {
        self.email = email
        self.password = password
        self.proxyCredentials = proxyCredentials
        super.init(parent: parent)
    }

}

extension VerificationCodeComponent: VerificationCodeViewModel.Factory {

    // MARK: - Factory

    @MainActor var viewModel: VerificationCodeViewModel {
        VerificationCodeViewModel(
            factory: self,
            email: email,
            password: password,
            proxyCredentials: proxyCredentials,
            router: dependency.router
        )
    }

    func noHistoryView(result: AuthenticationResult) -> NoHistoryView {
        let factory = noHistoryFactory(result: result)
        return NoHistoryView(factory: factory)
    }

    // MARK: - Use cases

    func submitProxyCredentialsUseCase() -> any SubmitProxyCredentialsUseCaseProtocol {
        SubmitProxyCredentialsUseCase(networkStack: dependency.networkStack)
    }

    func loginViaEmailUseCase() async throws -> any LoginViaEmailUseCaseProtocol {
        let authenticationAPI = try await dependency.networkStack.makeAuthenticationAPI()
        return LoginViaEmailUseCase(authenticationAPI: authenticationAPI)
    }

    func requestLoginVerificationCodeUseCase() async throws -> any RequestLoginVerificationCodeUseCaseProtocol {
        let authenticationAPI = try await dependency.networkStack.makeAuthenticationAPI()
        return RequestLoginVerificationCodeUseCase(authenticationAPI: authenticationAPI)
    }

    func createAuthenticationResultUseCase() -> any CreateAuthenticationResultUseCaseProtocol {
        CreateAuthenticationResultUseCase(networkStack: dependency.networkStack)
    }

    // MARK: - Private

    private func noHistoryFactory(result: AuthenticationResult) -> NoHistoryComponent {
        NoHistoryComponent(
            parent: self,
            authenticationResult: result,
            didDetectDomainConflict: dependency.didDetectDomainConflict
        )
    }
}
