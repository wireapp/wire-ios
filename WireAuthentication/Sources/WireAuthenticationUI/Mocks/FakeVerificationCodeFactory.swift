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
import WireAuthenticationAPI
import WireReusableUIComponents

struct FakeVerificationCodeFactory: VerificationCodeFactory,
    CreateAuthenticationResultUseCaseFactory,
    LoginViaEmailUseCaseFactory,
    RequestLoginVerificationCodeUseCaseFactory,
    SubmitProxyCredentialsUseCaseFactory,
    OpenAppStoreUseCaseFactory {

    var mockDependencies: MockDependencies = .init()

    var email: String
    var password: String
    var code: [String] = []

    var viewModel: VerificationCodeViewModel {
        // TODO: [WPB-16840] - use code for previews
        VerificationCodeViewModel(
            factory: self,
            email: email,
            password: password,
            proxyCredentials: nil,
            router: FakeRootFactory().viewModel
        )
    }

    func noHistoryView(result: AuthenticationResult) -> NoHistoryView {
        fatalError()
    }

    // Use cases

    @MainActor
    func createAuthenticationResultUseCase() -> any WireAuthenticationAPI
        .CreateAuthenticationResultUseCaseProtocol {
        mockDependencies.createAuthenticationResultUseCase()
    }

    @MainActor
    func submitProxyCredentialsUseCase() -> any WireAuthenticationAPI.SubmitProxyCredentialsUseCaseProtocol {
        mockDependencies.submitProxyCredentialsUseCase()
    }

    @MainActor
    func requestLoginVerificationCodeUseCase() async throws -> any WireAuthenticationAPI
        .RequestLoginVerificationCodeUseCaseProtocol {
        try await mockDependencies.requestLoginVerificationCodeUseCase()
    }

    @MainActor
    func loginViaEmailUseCase() async throws -> any WireAuthenticationAPI.LoginViaEmailUseCaseProtocol {
        try await mockDependencies.loginViaEmailUseCase()
    }

    @MainActor
    func openAppStoreUseCase() -> any WireAuthenticationAPI.OpenAppStoreUseCaseProtocol {
        mockDependencies.openAppStoreUseCase()
    }

}
