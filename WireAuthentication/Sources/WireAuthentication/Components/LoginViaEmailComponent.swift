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
    var accountsURL: URL { get }
    var passwordValidator: any PasswordValidator { get }
    var authenticationAPI: AuthenticationAPI { get }

}

class LoginViaEmailComponent: Component<LoginViaEmailComponentDependency> {

    // MARK: - View

    @MainActor
    func view(email: String, canCreateAccount: Bool) -> LoginViaEmailView {
        LoginViaEmailView(
            viewModel: viewModel(email: email, canCreateAccount: canCreateAccount)
        )
    }

    @MainActor
    private func viewModel(
        email: String,
        canCreateAccount: Bool
    ) -> LoginViaEmailViewModel {
        LoginViaEmailViewModel(
            router: dependency.router,
            loginViaEmailUseCase: loginViaEmailUseCase,
            email: email,
            accountsURL: dependency.accountsURL,
            passwordValidator: dependency.passwordValidator,
            canCreateAccount: canCreateAccount
        )
    }

    // MARK: - Private dependencies

    private var loginViaEmailUseCase: some LoginViaEmailUseCaseProtocol {
        LoginViaEmailUseCase(authenticationAPI: dependency.authenticationAPI)
    }

}
