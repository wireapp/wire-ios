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

import Foundation
import WireAuthenticationAPI

extension MockDependencies: LoginViaSSOUseCaseFactory {

    @MainActor
<<<<<<< HEAD:WireAuthentication/Sources/WireAuthenticationUI/Views/Login/LoginViaSSO/LoginViaSSOView.swift
    func loginViaSSOView(
        ssoURL: URL,
        backendEnvironment: WireAuthenticationBackendEnvironment
    ) -> LoginViaSSOView

}

package struct LoginViaSSOView: View {

    @ObservedObject var viewModel: LoginViaSSOViewModel

    package init(
        viewModel: LoginViaSSOViewModel
    ) {
        self.viewModel = viewModel
=======
    func loginViaSSOUseCase(backendInfo: BackendInfo?) async throws -> any LoginViaSSOUseCaseProtocol {
        MockLoginViaSSOUseCase(backendEnvironment: backendEnvironment)
>>>>>>> c679b9d42e (fix: cached SSO authentication - WPB-16767 (#2778)):WireAuthentication/Sources/WireAuthenticationUI/Mocks/MockDependencies+LoginViaSSOUseCaseFactory.swift
    }

}

<<<<<<< HEAD:WireAuthentication/Sources/WireAuthenticationUI/Views/Login/LoginViaSSO/LoginViaSSOView.swift
#Preview {
    let url = URL(string: "https://www.wire.com")!
    MockDependencies().loginViaSSOView(
        ssoURL: url,
        backendEnvironment: MockDependencies().backendEnvironment
    )
=======
struct MockLoginViaSSOUseCase: LoginViaSSOUseCaseProtocol {

    let backendEnvironment: WireAuthenticationBackendEnvironment

    func invoke(code: UUID?) async throws -> AuthenticationResult {
        AuthenticationResult(
            userID: UUID(),
            cookies: [],
            accessToken: nil,
            emailCredentials: nil,
            backendEnvironment: backendEnvironment
        )
    }

>>>>>>> c679b9d42e (fix: cached SSO authentication - WPB-16767 (#2778)):WireAuthentication/Sources/WireAuthenticationUI/Mocks/MockDependencies+LoginViaSSOUseCaseFactory.swift
}
