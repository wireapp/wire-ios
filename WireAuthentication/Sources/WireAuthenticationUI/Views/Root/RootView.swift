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

import SwiftUI
import WireAuthenticationAPI

package struct RootView: View {

    package typealias Factory =
        DetermineAuthMethodBuilder &
        //LoginViaEmailOnPremBuilder &
        LoginViaEmailNewBuilder &
        LoginViaSSOBuilder &
        NoHistoryViewBuilder

    @StateObject var viewModel: RootViewModel
    let factory: any Factory

    package init(
        viewModel: RootViewModel,
        factory: any Factory
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.factory = factory
    }

    package var body: some View {
        BackgroundView()
            .sheet(item: $viewModel.modalDestination) { sheet in
                switch sheet {
                case .authFlow:
                    NavigationStack(path: $viewModel.path) {
                        factory.determineAuthMethodView()
                    }
                case let .onPremiseAuthFlow(environmentType, backendConfig, backendMetadata):
                    NavigationStack(path: $viewModel.path) {
                        factory.determineAuthMethodView(
                            environmentType: environmentType,
                            backendConfig: backendConfig,
                            backendMetadata: backendMetadata
                        )
                    }
                case let .noHistory(
                    authenticationResult,
                    didDetectDomainConflict
                ):
                    factory.noHistoryView(
                        authenticationResult: authenticationResult,
                        didDetectDomainConflict: didDetectDomainConflict
                    )
                case let .onPremiseLogin(
                    email,
                    environmentType,
                    backendConfig,
                    backendMetadata
                ):
                    factory.loginViaEmailViewNew(
                        email: email ?? "",
                        canCreateAccount: true,
                        didDetectDomainConflict: false,
                        environmentType: environmentType,
                        backendConfig: backendConfig,
                        backendMetadata: backendMetadata
                    )
                case let .ssoLogin(
                    ssoURL,
                    backendEnvironment
                ):
                    factory.loginViaSSOView(
                        ssoURL: ssoURL,
                        backendEnvironment: backendEnvironment
                    )
                }
            }
    }

    package enum ModalDestination: Identifiable, Hashable {
        public var id: Self { self }

        case authFlow
        case onPremiseAuthFlow(
            environmentType: BackendEnvironmentType,
            backendConfig: BackendConfig,
            backendMetadata: BackendMetadata
        )
        case noHistory(
            authenticationResult: AuthenticationResult,
            didDetectDomainConflict: Bool
        )
        case onPremiseLogin(
            email: String?,
            environmentType: BackendEnvironmentType,
            environment: BackendConfig,
            backendMetadata: BackendMetadata
        )
        case ssoLogin(
            url: URL,
            backendEnvironment: WireAuthenticationBackendEnvironment
        )
    }

}

#Preview {
    MockDependencies().rootView
}
