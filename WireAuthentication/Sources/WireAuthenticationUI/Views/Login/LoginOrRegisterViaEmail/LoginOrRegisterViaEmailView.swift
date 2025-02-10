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

public protocol LoginOrRegisterViaEmailBuilder {

    @MainActor
    func loginOrRegisterViaEmailView(email: String) -> LoginOrRegisterViaEmailView

}

public struct LoginOrRegisterViaEmailView: View {

    @ObservedObject var viewModel: LoginOrRegisterViaEmailViewModel

    @State var password: String = ""
    @State var isPasswordValid = true

    public init(
        viewModel: LoginOrRegisterViaEmailViewModel
    ) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .center, spacing: 14) {
            LabeledTextField(
                placeholder: nil,
                title: L10n.CloudUserLogin.InputEmail.title,
                string: .constant(viewModel.email)
            )
            .disabled(true)

            PasswordField(
                isPasswordValid: $isPasswordValid,
                password: $password,
                passwordValidator: viewModel.passwordValidator,
                placeholder: L10n.CloudUserLogin.InputPassword.placeholder,
                title: L10n.CloudUserLogin.InputPassword.title
            )

            Button(action: {
                viewModel.submitPassword(password)
            }, label: {
                Text(L10n.CloudUserLogin.submit)
                    .lineLimit(nil)
            })
            .wireButtonStyle(.primary)
            .disabled(!isPasswordValid)

            Button(action: {
                UIApplication.shared.open(viewModel.forgotPasswordURL)
            }, label: {
                Text(L10n.CloudUserLogin.forgotPassword)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            })
            .wireButtonStyle(.link)

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
        .navigationTitle(L10n.CloudUserLogin.title)
        .padding(32)
        .background(ColorTheme.Backgrounds.surface.color)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(ColorTheme.Backgrounds.surface.color, lineWidth: 1)
        )
    }

}

#Preview {
    MockDependencies().loginOrRegisterViaEmailView(email: "foo@bar.com")
}
