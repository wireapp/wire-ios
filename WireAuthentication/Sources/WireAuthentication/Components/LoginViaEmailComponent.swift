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
    @MainActor var bridge: WireAuthenticationBridge { get }

}

class LoginViaEmailComponent: Component<LoginViaEmailComponentDependency> {

    // MARK: - View

    @MainActor
    func view(email: String, canCreateAccount: Bool) -> LoginViaEmailView {
        LoginViaEmailView(
            viewModel: viewModel(email: email, canCreateAccount: canCreateAccount),
            factory: self
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
            canCreateAccount: canCreateAccount,
            onCreateAccount: { [weak dependency] in
                dependency?.bridge.registerAccount()
            }
        )
    }

    // MARK: - Private dependencies

    private var loginViaEmailUseCase: some LoginViaEmailUseCaseProtocol {
        LoginViaEmailUseCase(authenticationAPI: dependency.authenticationAPI)
    }

    // MARK: - Children

    var verificationCodeComponent: VerificationCodeComponent {
        VerificationCodeComponent(parent: self)
    }

}

extension LoginViaEmailComponent: LoginViaEmailView.Factory {

    func verificationCodeView(email: String, password: String) -> VerificationCodeView {
        verificationCodeComponent.view(email: email, password: password)
    }

}

 
//protocol SwitchBackendConfirmationComponentDependency: Dependency {
//
//    @MainActor var router: any Router { get }
//}

class SwitchBackendConfirmationComponent{//: Component<SwitchBackendConfirmationComponentDependency> {

    // MARK: - View

    @MainActor
    func view(environment: BackendEnvironmentResponse) -> SwitchBackendConfirmationView {
        SwitchBackendConfirmationView(viewModel: viewModel(environment: environment))
    }

    @MainActor
    private func viewModel(environment: BackendEnvironmentResponse) -> SwitchBackendConfirmationViewModel {
        SwitchBackendConfirmationViewModel(
            backendName: environment.title,
            backendURL: environment.endpoints.backendURL.absoluteString,
            backendWSURL: environment.endpoints.backendWSURL.absoluteString,
            blacklistURL: environment.endpoints.blackListURL.absoluteString,
            teamsURL: environment.endpoints.teamsURL.absoluteString,
            accountsURL: environment.endpoints.accountsURL.absoluteString,
            websiteURL: environment.endpoints.websiteURL.absoluteString,
            action: { _ in }
        )
    }

}
