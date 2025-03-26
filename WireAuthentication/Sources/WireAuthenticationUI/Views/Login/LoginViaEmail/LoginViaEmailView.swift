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

package protocol LoginViaEmailBuilder {

    @MainActor
    func loginViaEmailView(
        email: String?,
        canCreateAccount: Bool,
        didDetectDomainConflict: Bool,
        backendInfo: BackendInfo
    ) -> LoginViaEmailView

}

package struct LoginViaEmailView: View {

    package typealias Factory =
        NoHistoryViewBuilder &
        VerificationCodeBuilder

    @StateObject var viewModel: LoginViaEmailViewModel
    private let factory: any Factory

    @State private var password: String = ""
    @State private var proxyPassword: String = ""

    private var proxyEmail: String = ""

    package init(
        viewModel: LoginViaEmailViewModel,
        factory: any Factory
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.factory = factory
    }

    package var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 14) {
                if viewModel.hasProxySupport {
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
            .navigationTitle(L10n.CloudUserLogin.title)
            .navigationBarTitleDisplayMode(.inline)
            .padding(32)
            .background(ColorTheme.Backgrounds.surface.color)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(ColorTheme.Backgrounds.surface.color, lineWidth: 1)
            )
        }
        .alert(
            item: $viewModel.alert,
            title: { Text($0.title) },
            message: { Text($0.message) },
            actions: { _ in
                Button(L10n.Authentication.Error.confirm, action: {})
            }
        )
        .navigationDestination(for: Destination.self) { destination in
            switch destination {
            case let .verifyLogin(
                email,
                password
            ):
                factory.verificationCodeView(
                    email: email,
                    password: password
                )
            case let .noHistory(authenticationResult):
                factory.noHistoryView(authenticationResult: authenticationResult)
            }
        }
        .presentationDetents(viewModel.hasProxySupport ? [.large] : [.medium, .large])
        .interactiveDismissDisabled()
        .presentationDragIndicator(.hidden)
    }

    @ViewBuilder private var welcomeMessage: some View {
        VStack(spacing: 14) {
            OnPremHeaderView(backendConfig: viewModel.backendInfo.backendConfig)
            Text(L10n.OnPremUserLogin.message)
                .multilineTextAlignment(.center)
                .wireTextStyle(.body1)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder private var emailField: some View {
        LabeledTextField(
            placeholder: nil,
            title: L10n.CloudUserLogin.InputEmail.title,
            string: .constant(viewModel.email ?? "")
        )
        .autocorrectionDisabled()
        .disabled(viewModel.isValidEmail)
    }

    @ViewBuilder private var passwordField: some View {
        PasswordField(
            password: $password,
            placeholder: L10n.CloudUserLogin.InputPassword.placeholder,
            title: L10n.CloudUserLogin.InputPassword.title,
            passwordRules: "viewModel.localizedPasswordRules",
            isValidPassword: viewModel.isValidPassword
        )
    }

    @ViewBuilder private var submitButton: some View {
        Button(action: {
            Task {
                await viewModel.submit(
                    password: password,
                    proxyCredentials: viewModel.hasProxySupport ? ProxyCredentials(
                        username: proxyEmail,
                        password: proxyPassword
                    ) : nil
                )
            }
        }, label: {
            Text(L10n.CloudUserLogin.submit)
                .lineLimit(nil)
        })
        .wireButtonStyle(.primary)
        .bold()
        .disabled(
            !viewModel.canSubmitPassword(
                password: password,
                proxyCredentials: ProxyCredentials(
                    username: proxyEmail,
                    password: proxyPassword
                )
            )
        )
    }

    @ViewBuilder private var forgotPasswordButton: some View {
        Button(action: {
            viewModel.recoverPassword()
        }, label: {
            Text(L10n.CloudUserLogin.forgotPassword)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        })
        .wireButtonStyle(.link)
    }

    @ViewBuilder private var createAccount: some View {
        VStack(spacing: 4) {
            Text(L10n.CreatePersonalAccount.title)
                .multilineTextAlignment(.center)
                .wireTextStyle(.body1)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: {
                viewModel.createAccount()
            }, label: {
                Text(L10n.CreatePersonalAccount.button)
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
            Text(L10n.ProxyCredentials.title)
                .multilineTextAlignment(.center)
                .font(.textStyle(.h2))
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)

            Text(L10n.ProxyCredentials.message(viewModel.proxyServer))
                .multilineTextAlignment(.center)
                .wireTextStyle(.body1)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)

            LabeledTextField(
                placeholder: "jane@example.com",
                title: L10n.ProxyCredentials.InputEmail.title,
                string: .constant(proxyEmail)
            )

            PasswordField(
                password: $proxyPassword,
                placeholder: L10n.CloudUserLogin.InputPassword.placeholder,
                title: L10n.CloudUserLogin.InputPassword.title,
                passwordRules: "viewModel.localizedPasswordRules",
                isValidPassword: viewModel.isValidPassword
            )
            Spacer()
        }
    }

    enum Destination: Hashable {

        case verifyLogin(
            email: String,
            password: String
        )
        case noHistory(
            authenticationResult: AuthenticationResult
        )

    }

}

#Preview() {
    BackgroundView()
        .sheet(isPresented: .constant(true)) {
            MockDependencies().loginViaEmailView(
                email: "foo@bar.com",
                canCreateAccount: false,
                didDetectDomainConflict: false,
                backendInfo: MockDependencies().backendInfo
            )
        }
}
