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

import SwiftUI
import WireAuthenticationAPI
import WireDesign
import WireReusableUIComponents

package protocol ReloginViaSSOFactory {

    @MainActor var viewModel: ReloginViaSSOViewModel { get }

    @MainActor
    func noHistoryView(result: AuthenticationResult) -> NoHistoryView

}

package struct ReloginViaSSOView: View {

    private typealias Strings = L10n.Localizable.Login.Sso

    @StateObject private var viewModel: ReloginViaSSOViewModel

    package init(
        factory: @autoclosure @escaping () -> any ReloginViaSSOFactory
    ) {
        self._viewModel = StateObject(wrappedValue: factory().viewModel)
    }

    package var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 14) {
                if viewModel.isOnPremiseBackend {
                    welcomeMessage
                }
                expirationMessage
                if viewModel.isSSOCodeRequired {
                    ssoCodeField
                }
                submitButton
            }
            .navigationTitle(Strings.title)
            .navigationBarTitleDisplayMode(.inline)
            .padding(32)
            .setPreferredSize(navigationBarHidden: false)
            .background(ColorTheme.Backgrounds.surface.color)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                logoutButton
            }
            if viewModel.existsAnotherAccount {
                ToolbarItem(placement: .topBarTrailing) {
                    dismissButton
                }
            }
        }
        .navigationDestination(for: ReloginViaSSODestination.self, destination: destinationView)
        .presentationDetents([.medium, .large])
        .interactiveDismissDisabled()
        .presentationDragIndicator(.hidden)
    }

    @ViewBuilder
    func destinationView(_ destination: ReloginViaSSODestination) -> some View {
        switch destination {
        case let .noHistory(authenticationResult):
            viewModel.factory.noHistoryView(result: authenticationResult)
        }
    }

    @ViewBuilder private var welcomeMessage: some View {
        OnPremHeaderView(environment: viewModel.environment)
    }

    @ViewBuilder private var expirationMessage: some View {
        Text(Strings.expirationMessage)
            .font(for: .body1)
            .multilineTextAlignment(.center)
            .foregroundStyle(Color.primaryText)
    }

    @ViewBuilder private var ssoCodeField: some View {
        LabeledTextField(
            placeholder: Strings.InputCode.placeholder,
            title: Strings.InputCode.title,
            string: $viewModel.rawSSOCode
        )
        .autocapitalization(.none)
        .autocorrectionDisabled()
        .textContentType(.username)
    }

    @ViewBuilder private var submitButton: some View {
        Button(action: {
            Task {
                await viewModel.login()
            }
        }, label: {
            Text(Strings.submit)
                .lineLimit(nil)
        })
        .wireButtonStyle(.primary)
        .bold()
    }

    @ViewBuilder private var logoutButton: some View {
        Button {
            viewModel.logout()
        } label: {
            Text(L10n.Localizable.Logout.Button.title)
        }
    }

    @ViewBuilder private var dismissButton: some View {
        Button {
            viewModel.exitFlow()
        } label: {
            Image(systemName: "xmark")
        }
    }

}
