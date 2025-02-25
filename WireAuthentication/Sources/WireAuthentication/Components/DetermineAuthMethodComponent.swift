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
    var callbackScheme: String { get }
    var defaults: UserDefaults { get }

}

class DetermineAuthMethodComponent: Component<DetermineAuthMethodComponentDependency>, DetermineAuthMethodBuilder {

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
            callbackScheme: dependency.callbackScheme,
            defaults: dependency.defaults
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

    @MainActor var determineAuthMethodView: DetermineAuthMethodView {
        DetermineAuthMethodView(
            viewModel: viewModel,
            loginViaEmailBuilder: loginViaEmailComponent,
            loginViaSSOBuilder: loginViaSSOComponent
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

    var onPremLoginComponent: OnPremLoginComponent {
        return OnPremLoginComponent(parent: self)
    }

}

protocol OnPremLoginComponentDependency: Dependency {
    var defaultBackendEnvironment: BackendEnvironment { get }
    var authenticationAPI: AuthenticationAPI { get }
    var minTLSVersion: TLSVersion { get }
    var defaultAPIVersion: APIVersion { get }
}

class OnPremLoginComponent: Component<OnPremLoginComponentDependency>, OnPremLoginBuilder {

    private let overriddenBackendEnvironment: BackendEnvironment?

    init(parent: Scope, overriddenBackendEnvironment: BackendEnvironment? = nil) {
        self.overriddenBackendEnvironment = overriddenBackendEnvironment
        super.init(parent: parent)
    }

    var authenticationAPI: AuthenticationAPI {
        AuthenticationAPIBuilder(
            networkService: NetworkService.make(
                backendEnvironment: overriddenBackendEnvironment ?? dependency.defaultBackendEnvironment,
                minTLSVersion: dependency.minTLSVersion
            )
        ).makeAPI(for: dependency.defaultAPIVersion)
    }

    @MainActor
    func someView(overriddenBackendEnvironment: BackendEnvironment?) -> AnyView {
        let effectiveBackendEnvironment = overriddenBackendEnvironment ?? dependency.defaultBackendEnvironment
        let authenticationAPI = AuthenticationAPIBuilder(
            networkService: NetworkService.make(
                backendEnvironment: effectiveBackendEnvironment,
                minTLSVersion: dependency.minTLSVersion
            )
        ).makeAPI(for: dependency.defaultAPIVersion)

        return AnyView(Color.red)
    }

}

package protocol OnPremLoginBuilder {

    @MainActor
    func someView(overriddenBackendEnvironment: BackendEnvironment?) -> AnyView

}
