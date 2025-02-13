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
import WireDesign
import WireReusableUIComponents

package protocol LoginViaEmailOnPremViewBuilder {

    @MainActor
    func loginViaEmailOnPremView(
        email: String,
        canCreateAccount: Bool
    ) -> LoginViaEmailOnPremView

}

package struct LoginViaEmailOnPremView: View {
    @ObservedObject var viewModel: LoginViaEmailOnPremViewModel

    @State private var password: String = ""
    @State private var proxyPassword: String = ""
    @State private var showPasswordRules: Bool = false
    @State private var showCustomBackendAlert = false

    private let proxyEmail: String = ""

    package init(
        viewModel: LoginViaEmailOnPremViewModel
    ) {
        self.viewModel = viewModel
    }

    package var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 14) {
                if viewModel.hasProxySupport {
                    welcomeMessage
                    emailField
                    passwordField
                    forgotPasswordButton
                    proxyCredentials
                    submitButton
                } else {
                    welcomeMessage
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
        .presentationDetents(viewModel.hasProxySupport ? [.large] : [.medium, .large])
        .interactiveDismissDisabled()
        .presentationDragIndicator(.hidden)
        .onChange(of: password) { newPassword in
            showPasswordRules = !viewModel.isValidPassword(newPassword)
        }
    }

    @ViewBuilder private var welcomeMessage: some View {
        VStack(spacing: 14) {
            Button(action: {
                showCustomBackendAlert.toggle()
            }) {
                Text(L10n.OnPremUserLogin.title(viewModel.backendName))
                    .foregroundColor(ColorTheme.Buttons.Secondary.onEnabled.color)
                + Text(" ")
                + Text(Image(systemName: "info.circle"))
                    .foregroundColor(.gray)
            }
            .multilineTextAlignment(.center)
            .font(.textStyle(.h2))
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .alert(L10n.OnPremUserLogin.Alert.title, isPresented: $showCustomBackendAlert) {
                Button(L10n.OnPremUserLogin.Alert.button, role: .cancel) {}
            } message: {
                Text(viewModel.backendInfo)
            }
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
            string: .constant(viewModel.email)
        )
        .disabled(!viewModel.email.isEmpty)
    }

    @ViewBuilder private var passwordField: some View {
        PasswordField(
            password: $password,
            placeholder: L10n.CloudUserLogin.InputPassword.placeholder,
            title: L10n.CloudUserLogin.InputPassword.title,
            passwordRules: viewModel.localizedPasswordRules,
            arePasswordRulesVisible: $showPasswordRules,
            titleColor: passwordFieldTitleColor,
            borderColor: passwordFieldBorderColor
        )
    }

    @ViewBuilder private var submitButton: some View {
        Button(action: {
            viewModel.submitPassword(password)
        }, label: {
            Text(L10n.CloudUserLogin.submit)
                .lineLimit(nil)
        })
        .wireButtonStyle(.primary)
        .bold()
        .disabled(!viewModel.isValidPassword(password))
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
                passwordRules: viewModel.localizedPasswordRules,
                arePasswordRulesVisible: $showPasswordRules,
                titleColor: passwordFieldTitleColor,
                borderColor: passwordFieldBorderColor
            )
            Spacer()
        }
    }

    // MARK: - Helper

    private var passwordFieldTitleColor: Color {
        switch (password.isEmpty, viewModel.isValidPassword(password)) {
        case (_, false):
            ColorTheme.Base.error.color
        case (true, _):
            ColorTheme.Base.labelTitle.color
        case (false, true):
            ColorTheme.Base.primary.color
        }
    }

    private var passwordFieldBorderColor: Color {
        switch (password.isEmpty, viewModel.isValidPassword(password)) {
        case (_, false):
            ColorTheme.Base.error.color
        case (true, _):
            ColorTheme.Strokes.outline.color
        case (false, true):
            ColorTheme.Base.primary.color
        }
    }

}

#Preview() {
    BackgroundView()
        .sheet(isPresented: .constant(true)) {
            MockDependencies().loginViaEmailOnPremView(
                email: "foo@bar.com",
                canCreateAccount: false
            )
        }
}
