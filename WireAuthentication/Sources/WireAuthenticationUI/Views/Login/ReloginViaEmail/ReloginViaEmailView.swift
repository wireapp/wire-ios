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
import WireDesign
import WireNetwork
import WireReusableUIComponents

package protocol ReloginViaEmailFactory {

    @MainActor var viewModel: ReloginViaEmailViewModel { get }

    @MainActor
    func verifyLoginView(
        email: String,
        password: String,
        proxyCredentials: ProxyCredentials?
    ) -> VerificationCodeView

    @MainActor
    func noHistoryView(result: AuthenticationResult) -> NoHistoryView

}

// TODO: [WPB-19938] Minimize duplication here and LoginViaEmailView
package struct ReloginViaEmailView: View {

    @StateObject private var viewModel: ReloginViaEmailViewModel

    private typealias Strings = L10n.Localizable

    package init(
        factory: @autoclosure @escaping () -> any ReloginViaEmailFactory
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
                emailField
                passwordField
                if viewModel.areProxyCredentialsRequired {
                    forgotPasswordButton
                    proxyCredentials
                    submitButton
                } else {
                    submitButton
                    forgotPasswordButton
                }
            }
            .navigationTitle(Strings.CloudUserLogin.title)
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
        .alert(
            item: $viewModel.alert,
            title: { Text($0.title) },
            message: { Text($0.message) },
            actions: { _ in
                Button(Strings.Authentication.Error.confirm, action: {})
            }
        )
        .navigationDestination(for: ReloginViaEmailDestination.self, destination: destinationView)
        .presentationDetents(viewModel.areProxyCredentialsRequired ? [.large] : [.medium, .large])
        .interactiveDismissDisabled()
        .presentationDragIndicator(.hidden)
    }

    @ViewBuilder
    func destinationView(_ destination: ReloginViaEmailDestination) -> some View {
        switch destination {
        case let .verifyLogin(email, password, proxyCredentials):
            viewModel.factory
                .verifyLoginView(
                    email: email,
                    password: password,
                    proxyCredentials: proxyCredentials
                )
        case let .noHistory(authenticationResult):
            viewModel.factory.noHistoryView(result: authenticationResult)
        }
    }

    @ViewBuilder private var welcomeMessage: some View {
        OnPremHeaderView(environment: viewModel.environment)
    }

    @ViewBuilder private var expirationMessage: some View {
        Text(Strings.CloudUserLogin.expirationMessage)
            .wireTextStyle(.body1)
            .multilineTextAlignment(.center)
            .foregroundStyle(Color.primaryText)
    }

    @ViewBuilder private var emailField: some View {
        LabeledTextField(
            placeholder: Strings.CloudUserLogin.InputEmail.placeholder,
            title: Strings.CloudUserLogin.InputEmail.title,
            string: .constant(viewModel.email)
        )
        .autocapitalization(.none)
        .autocorrectionDisabled()
        .textContentType(.username)
        .keyboardType(.emailAddress)
        .disabled(true)
    }

    @ViewBuilder private var passwordField: some View {
        PasswordField(
            password: $viewModel.password,
            placeholder: Strings.CloudUserLogin.InputPassword.placeholder,
            title: Strings.CloudUserLogin.InputPassword.title,
            passwordRules: "",
            isValidPassword: viewModel.isPasswordValid
        )
    }

    @ViewBuilder private var submitButton: some View {
        Button(action: {
            Task {
                await viewModel.submitCredentials()
            }
        }, label: {
            Text(Strings.CloudUserLogin.submit)
                .lineLimit(nil)
        })
        .wireButtonStyle(.primary)
        .bold()
        .disabled(!viewModel.canSubmitCredentials)
    }

    @ViewBuilder private var forgotPasswordButton: some View {
        Button(action: {
            viewModel.recoverPassword()
        }, label: {
            Text(Strings.CloudUserLogin.forgotPassword)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        })
        .wireButtonStyle(.link)
    }

    @ViewBuilder private var proxyCredentials: some View {
        Spacer()
        VStack(spacing: 14) {
            Text(Strings.ProxyCredentials.title)
                .multilineTextAlignment(.center)
                .font(.textStyle(.h2))
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)

            if let proxyServer = viewModel.proxyServer {
                Text(Strings.ProxyCredentials.message(proxyServer))
                    .multilineTextAlignment(.center)
                    .wireTextStyle(.body1)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }

            LabeledTextField(
                placeholder: "jane@example.com",
                title: Strings.ProxyCredentials.InputEmail.title,
                string: $viewModel.proxyUsername
            )
            .autocapitalization(.none)
            .autocorrectionDisabled()
            .textContentType(.username)
            .keyboardType(.emailAddress)

            PasswordField(
                password: $viewModel.proxyPassword,
                placeholder: Strings.CloudUserLogin.InputPassword.placeholder,
                title: Strings.CloudUserLogin.InputPassword.title,
                passwordRules: "",
                isValidPassword: viewModel.isPasswordValid
            )
            Spacer()
        }
    }

    @ViewBuilder private var logoutButton: some View {
        Button {
            viewModel.logout()
        } label: {
            Text(Strings.Logout.Button.title)
        }
    }

    @ViewBuilder private var dismissButton: some View {
        Button {
            viewModel.exitFlow()
        } label: {
            Image(systemName: "xmark")
        }
    }

    private func onSheetDismiss() {
        viewModel.onSheetDismissAction?()
    }

}
