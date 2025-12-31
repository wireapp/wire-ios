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
import WireLocators
import WireNetwork
import WireReusableUIComponents

package protocol LoginViaEmailFactory {

    @MainActor var viewModel: LoginViaEmailViewModel { get }

    @MainActor
    func verifyLoginView(
        email: String,
        password: String,
        proxyCredentials: ProxyCredentials?
    ) -> VerificationCodeView

    @MainActor
    func noHistoryView(result: AuthenticationResult) -> NoHistoryView

    @MainActor
    func personalAccountCreationView(teamAccountCreationLink: URL?) -> PersonalAccountCreationView

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
        .fullScreenCover(item: $viewModel.modalDestination, onDismiss: onSheetDismiss, content: sheetView(for:))
        .navigationDestination(for: LoginViaEmailDestination.self, destination: destinationView)
        .presentationDetents(viewModel.areProxyCredentialsRequired ? [.large] : [.medium, .large])
        .interactiveDismissDisabled()
        .presentationDragIndicator(.hidden)
    }

    @ViewBuilder
    func destinationView(_ destination: LoginViaEmailDestination) -> some View {
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
        case .createPersonalAccount:
            viewModel.factory
                .personalAccountCreationView(
                    teamAccountCreationLink: viewModel.teamAccountCreationLink
                )
        }
    }

    @ViewBuilder private var welcomeMessage: some View {
        OnPremHeaderView(environment: viewModel.environment)
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
        .accessibilityIdentifier(String(describing: Locators.LoginPage.passwordSecureTextField))
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
        .accessibilityIdentifier(String(describing: Locators.LoginPage.nextButton))
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
                .font(for: .body1)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: {
                viewModel.createAccount()
            }, label: {
                Text(Strings.CreateAccount.button)
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
        .accessibilityIdentifier(String(describing: Locators.LoginPage.createAccountLink.rawValue))
    }

    @ViewBuilder private var proxyCredentials: some View {
        Spacer()
        VStack(spacing: 14) {
            Text(Strings.ProxyCredentials.title)
                .multilineTextAlignment(.center)
                .font(for: .h2)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)

            if let proxyServer = viewModel.proxyServer {
                Text(Strings.ProxyCredentials.message(proxyServer))
                    .multilineTextAlignment(.center)
                    .font(for: .body1)
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

    @ViewBuilder
    private func sheetView(for sheet: LoginViaEmailSheet) -> some View {
        switch sheet {
        case let .teamAccountCreation(teamAccountCreationLink):
            SafariBrowserView(url: teamAccountCreationLink)
                .ignoresSafeArea()
        case .accountTypeSelection:
            AccountTypeSelectionView(
                onTeamAccountCreation: viewModel.handleTeamAccountCreation,
                onPersonalAccountCreation: viewModel.handlePersonalAccountCreation
            )
            // TODO: [WPB-18672] The account type selection is presented full-screen, not like the rest of the auth UI
            // try to use .universalSheet(...) if possible
        }
    }

    private func onSheetDismiss() {
        viewModel.onSheetDismissAction?()
    }

}
