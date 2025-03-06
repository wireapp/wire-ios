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

protocol DetermineAuthMethodComponentDependency: Dependency {

    @MainActor var router: any Router { get }
    var defaultBackendEnvironment: BackendEnvironment { get }
    var defaultAPIVersion: APIVersion { get }
    var minTLSVersion: TLSVersion { get }
    var ssoCallbackURLScheme: String { get }
    var userDefaults: UserDefaults { get }

}

class DetermineAuthMethodComponent: Component<DetermineAuthMethodComponentDependency> {

    private var validateEmailOrSSOCode: ValidateEmailOrSSOCodeUseCase {
        ValidateEmailOrSSOCodeUseCase()
    }

    private var determineAuthMethodUseCase: some DetermineAuthMethodUseCaseProtocol {
        DetermineAuthMethodUseCase(
            validateEmailOrSSOCode: validateEmailOrSSOCode,
            authenticationAPI: authenticationAPI
        )
    }

    private var ssoLinkGenerator: SSOLinkGeneratorProtocol {
        SSOLinkGenerator(
            authenticationAPI: authenticationAPI,
            baseURL: dependency.defaultBackendEnvironment.url,
            callbackScheme: dependency.ssoCallbackURLScheme,
            defaults: dependency.userDefaults
        )
    }

    @MainActor private var viewModel: DetermineAuthMethodViewModel {
        DetermineAuthMethodViewModel(
            router: dependency.router,
            validateEmailOrSSOCode: validateEmailOrSSOCode,
            determineAuthMethod: determineAuthMethodUseCase,
            ssoLinkGenerator: ssoLinkGenerator
        )
    }

    @MainActor var view: DetermineAuthMethodView {
        DetermineAuthMethodView(
            viewModel: viewModel,
            factory: self
        )
    }

    public var authenticationAPI: AuthenticationAPI {
        AuthenticationAPIBuilder(
            networkService: NetworkService.make(
                backendEnvironment: dependency.defaultBackendEnvironment,
                minTLSVersion: dependency.minTLSVersion
            )
        ).makeAPI(for: dependency.defaultAPIVersion)
    }

    // MARK: - Children

    var loginViaEmailComponent: LoginViaEmailComponent {
        LoginViaEmailComponent(parent: self)
    }

    var loginViaSSOComponent: LoginViaSSOComponent {
        LoginViaSSOComponent()
    }

}

extension DetermineAuthMethodComponent: DetermineAuthMethodView.Factory {

    @MainActor
    func loginViaEmailView(
        email: String,
        canCreateAccount: Bool,
        didDetectDomainConflict: Bool
    ) -> LoginViaEmailView {
        loginViaEmailComponent.view(
            email: email,
            canCreateAccount: canCreateAccount,
            didDetectDomainConflict: didDetectDomainConflict
        )
    }

    func loginViaSSOView(ssoURL: URL) -> LoginViaSSOView {
        loginViaSSOComponent.view(ssoURL: ssoURL)
    }

}
