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
import WireReusableUIComponents

package protocol LoginViaEmailFactory {

    @MainActor var viewModel: LoginViaEmailViewModel { get }

    @MainActor
    func verificationCodeFactory(
        email: String,
        password: String,
        proxyCredentials: ProxyCredentials?
    ) -> any VerificationCodeFactory

    @MainActor
    func noHistoryFactory(authenticationResult: AuthenticationResult) -> any NoHistoryFactory

    @MainActor
    func personalAccountCreationFactory() -> any PersonalAccountCreationFactory

}

package struct LoginViaEmailView: View {

    @StateObject private var viewModel: LoginViaEmailViewModel

    private typealias Strings = L10n.Localizable

    package init(
        factory: @autoclosure @escaping () -> any LoginViaEmailFactory
    ) {
        self._viewModel = StateObject(wrappedValue: factory().viewModel)
    }

    package var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 14) {
                if viewModel.areProxyCredentialsRequired {
                    if viewModel.isOnPremiseBackend {
                        welcomeMessage
                    }
                    emailField
                    passwordField
                    forgotPasswordButton
                    proxyCredentials
                    submitButton
                } else {
                    if viewModel.isOnPremiseBackend {
                        welcomeMessage
                    }
                    emailField
                    passwordField
                    submitButton
                    forgotPasswordButton
                    if viewModel.canCreateAccount {
                        createAccount
                    }
                }
            }
            .navigationTitle(Strings.CloudUserLogin.title)
            .navigationBarTitleDisplayMode(.inline)
            .padding(32)
            .setPreferredSize(navigationBarHidden: false)
            .customBackButton()
            .background(ColorTheme.Backgrounds.surface.color)
        }
        .alert(
            item: $viewModel.alert,
            title: { Text($0.title) },
            message: { Text($0.message) },
            actions: { _ in
                Button(Strings.Authentication.Error.confirm, action: {})
            }
        )
        .sheet(isPresented: $viewModel.isCreateAccountPresented) {
            //AccountTypeSelectionView(factory: viewModel.factory.accountTypeSelectionFactory()) TODO: fix
            Text(verbatim: "todo: show AccountTypeSelectionView")
        }
        .navigationDestination(for: LoginViaEmailDestination.self) { destination in
            destinationView(destination)
        }
        .presentationDetents(viewModel.areProxyCredentialsRequired ? [.large] : [.medium, .large])
        .interactiveDismissDisabled()
        .presentationDragIndicator(.hidden)
    }

    @ViewBuilder
    func destinationView(_ destination: LoginViaEmailDestination) -> some View {
        switch destination {
        case let .verifyLogin(
            email,
            password,
            proxyCredentials
        ):
            VerificationCodeView(
                factory: viewModel.factory.verificationCodeFactory(
                    email: email,
                    password: password,
                    proxyCredentials: proxyCredentials
                )
            )
        case let .noHistory(authenticationResult):
            NoHistoryView(
                factory: viewModel.factory.noHistoryFactory(
                    authenticationResult: authenticationResult
                )
            )
        }
    }

    @ViewBuilder private var welcomeMessage: some View {
        OnPremHeaderView(backendConfig: viewModel.backendInfo.backendConfig)
    }

    @ViewBuilder private var emailField: some View {
        LabeledTextField(
            placeholder: Strings.CloudUserLogin.InputEmail.placeholder,
            title: Strings.CloudUserLogin.InputEmail.title,
            string: $viewModel.email
        )
        .autocapitalization(.none)
        .autocorrectionDisabled()
        .textContentType(.username)
        .keyboardType(.emailAddress)
        .disabled(viewModel.isEmailPrefilled)
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

    @ViewBuilder private var createAccount: some View {
        VStack(spacing: 4) {
            Text(Strings.CreateAccountOrTeam.title)
                .multilineTextAlignment(.center)
                .wireTextStyle(.body1)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: {
                viewModel.createAccount()
            }, label: {
                Text(Strings.CreateAccountOrTeam.button)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .minimumScaleFactor(0.5)
                    .fixedSize(horizontal: false, vertical: true)
            })
            .wireButtonStyle(.link)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background {
            if #available(iOS 17.0, *) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(ColorTheme.Backgrounds.backgroundVariant.color)
                    .stroke(ColorTheme.Strokes.outline.color, lineWidth: 1)
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(ColorTheme.Strokes.outline.color, lineWidth: 1)
                    .background(ColorTheme.Backgrounds.backgroundVariant.color)
                    .cornerRadius(12)
            }
        }
    }

    @ViewBuilder private var proxyCredentials: some View {
        Spacer()
        VStack(spacing: 14) {
            Text(Strings.ProxyCredentials.title)
                .multilineTextAlignment(.center)
                .font(.textStyle(.h2))
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)

            Text(Strings.ProxyCredentials.message(viewModel.proxyServer))
                .multilineTextAlignment(.center)
                .wireTextStyle(.body1)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)

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

}
