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
            .sheet(item: $viewModel.modalDestination) { sheet in
                switch sheet {
                case .authFlow:
                    NavigationStack(path: $viewModel.path) {
                        factory.determineAuthMethodView
                            .alert(
                                item: $viewModel.alert,
                                title: titleForAlert,
                                message: messageForAlert,
                                actions: { _ in
                                    Button(L10n.Authentication.Error.confirm, action: {})
                                }
                            )
                    }
                case let .noHistory(
                    userID,
                    cookies,
                    accessToken,
                    emailCredentials,
                    didDetectDomainConflict
                ):
                    factory.noHistoryView(
                        userID: userID,
                        cookies: cookies,
                        accessToken: accessToken,
                        emailCredentials: emailCredentials,
                        didDetectDomainConflict: didDetectDomainConflict
                    )
                case let .onPremiseLogin(
                    email,
                    backendConfig,
                    backendMetadata
                ):
                    factory.loginViaEmailOnPremView(
                        email: email,
                        backendConfig: backendConfig,
                        backendMetadata: backendMetadata
                    )
                case let .ssoLogin(
                    ssoURL,
                    backendMetadata
                ):
                    factory.loginViaSSOView(ssoURL: ssoURL)
                }
            }
    }

    private func titleForAlert(_ alert: RootViewModel.Alert) -> Text {
        switch alert {
        case .ssoLoginFailed:
            Text(L10n.Authentication.Error.Title.ssoLoginFailed)
        }
    }

    private func messageForAlert(_ alert: RootViewModel.Alert) -> Text {
        switch alert {
        case .ssoLoginFailed:
            Text(L10n.Authentication.Error.Message.ssoLoginFailed)
        }
    }

    package enum ModalDestination: Identifiable, Hashable {
        public var id: Self { self }

        case authFlow
        case noHistory(
            userID: UUID,
            cookies: [HTTPCookie],
            accessToken: AccessToken?,
            emailCredentials: EmailCredentials?,
            didDetectDomainConflict: Bool
        )
        case onPremiseLogin(
            email: String,
            environment: BackendConfig,
            backendMetadata: BackendMetadata?
        )
        case ssoLogin(
            url: URL,
            BackendMetadata: BackendMetadata
        )
    }

}

#Preview {
    MockDependencies().rootView
}
