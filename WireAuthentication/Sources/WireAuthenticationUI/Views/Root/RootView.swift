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
import SwiftUIIntrospect
import WireAuthenticationAPI

package struct RootView: View {

    package typealias Factory =
        DetermineAuthMethodBuilder &
        LoginViaEmailOnPremBuilder &
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
            .universalSheet(item: $viewModel.modalDestination) { item in
                sheetContent(for: item)
            }
    }

    @ViewBuilder
    private func sheetContent(for sheet: RootView.ModalDestination) -> some View {
        switch sheet {
        case .authFlow:
            NavigationStack(path: $viewModel.path) {
                factory.determineAuthMethodView()
            }
            .sheetCornerRadius(10, inNavigationStack: true)

        case let .onPremiseAuthFlow(environmentType, backendConfig, backendMetadata):
            NavigationStack(path: $viewModel.path) {
                factory.determineAuthMethodView(
                    environmentType: environmentType,
                    backendConfig: backendConfig,
                    backendMetadata: backendMetadata
                )
            }
            .sheetCornerRadius(10, inNavigationStack: true)

        case let .noHistory(
            authenticationResult,
            didDetectDomainConflict
        ):
            factory.noHistoryView(
                authenticationResult: authenticationResult,
                didDetectDomainConflict: didDetectDomainConflict
            )
            .sheetCornerRadius(10, inNavigationStack: false)

        case let .onPremiseLogin(
            email,
            environmentType,
            backendConfig,
            backendMetadata
        ):
            factory.loginViaEmailOnPremView(
                email: email,
                environmentType: environmentType,
                backendConfig: backendConfig,
                backendMetadata: backendMetadata
            )
            .sheetCornerRadius(10, inNavigationStack: false)

        case let .ssoLogin(
            ssoURL,
            backendEnvironment
        ):
            factory.loginViaSSOView(
                ssoURL: ssoURL,
                backendEnvironment: backendEnvironment
            )
            .sheetCornerRadius(10, inNavigationStack: false)
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
            backendMetadata: BackendMetadata?
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
