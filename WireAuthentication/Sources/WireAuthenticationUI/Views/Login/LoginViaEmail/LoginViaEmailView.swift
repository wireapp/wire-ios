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

package protocol LoginViaEmailBuilder {

    @MainActor
    func loginViaEmailView(
        email: String,
        canCreateAccount: Bool
    ) -> LoginViaEmailView

}

package struct LoginViaEmailView: View {

    @StateObject var viewModel: LoginViaEmailViewModel

    let verificationCodeBuilder: any VerificationCodeBuilder

    package init(
        viewModel: LoginViaEmailViewModel,
        verificationCodeBuilder: any VerificationCodeBuilder
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.verificationCodeBuilder = verificationCodeBuilder
    }

    package var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 14) {
                emailField
                passwordField
                submitButton
                forgotPasswordButton
                if viewModel.canCreateAccount {
                    createAccount
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
            title: titleForAlert,
            message: messageForAlert,
            actions: { _ in
                Button(L10n.Authentication.Error.confirm, action: {})
            }
        )
        .navigationDestination(for: Destination.self) { destination in
            switch destination {
            case let .verifyLogin(email, password):
                verificationCodeBuilder.verificationCodeView(email: email, password: password)
            }
        }
        .presentationDetents([.medium, .large])
        .interactiveDismissDisabled()
        .presentationDragIndicator(.hidden)
    }

    @ViewBuilder private var emailField: some View {
        LabeledTextField(
            placeholder: nil,
            title: L10n.CloudUserLogin.InputEmail.title,
            string: .constant(viewModel.email)
        )
        .disabled(true)
    }

    @ViewBuilder private var passwordField: some View {
        PasswordField(
            password: $viewModel.password,
            placeholder: L10n.CloudUserLogin.InputPassword.placeholder,
            title: L10n.CloudUserLogin.InputPassword.title,
            passwordRules: viewModel.localizedPasswordRules,
            isValidPassword: { _ in viewModel.isPasswordValid }
        )
    }

    @ViewBuilder private var submitButton: some View {
        Button(
            action: { Task { await viewModel.submitPassword() } },
            label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                    }

                    Text(L10n.CloudUserLogin.submit)
                        .lineLimit(nil)
                }
            }
        )
        .wireButtonStyle(.primary)
        .bold()
        .disabled(!viewModel.isPasswordValid || viewModel.isLoading)
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

    enum Destination: Hashable {

        case verifyLogin(email: String, password: String)

    }

    private func titleForAlert(_ alert: LoginViaEmailViewModel.Alert) -> Text {
        switch alert {
        case .noInternet:
            Text(L10n.Authentication.Error.Title.noInternet)
        case .unknownError:
            Text(L10n.Authentication.Error.Title.general)
        case .invalidCredentials:
            Text(L10n.Authentication.Error.Title.invalidCredentials)
        case .accountPendingActivation:
            Text(L10n.Authentication.Error.Title.accountPendingActivation)
        case .accountSuspended:
            Text(L10n.Authentication.Error.Title.accountSuspended)
        }
    }

    private func messageForAlert(_ alert: LoginViaEmailViewModel.Alert) -> Text {
        switch alert {
        case .noInternet:
            Text(L10n.Authentication.Error.Message.noInternet)
        case .unknownError:
            Text(L10n.Authentication.Error.Message.general)
        case .invalidCredentials:
            Text(L10n.Authentication.Error.Message.invalidCredentials)
        case .accountPendingActivation:
            Text(L10n.Authentication.Error.Message.accountPendingActivation)
        case .accountSuspended:
            Text(L10n.Authentication.Error.Message.accountSuspended)
        }
    }

}

#Preview() {
    BackgroundView()
        .sheet(isPresented: .constant(true)) {
            MockDependencies().loginViaEmailView(email: "foo@bar.com", canCreateAccount: false)
        }
}
