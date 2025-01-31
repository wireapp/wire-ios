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

package struct LoginWithClaimedDomainView: View {
    private let email: String
    private let forgotPasswordURL: URL
    private let passwordValidator: any PasswordValidator

    @State var password: String = ""
    @State var isPasswordValid = true

    package init(
        email: String,
        forgotPasswordURL: URL,
        passwordValidator: any PasswordValidator) {
        self.email = email
        self.forgotPasswordURL = forgotPasswordURL
        self.passwordValidator = passwordValidator
    }

    package var body: some View {
        VStack(alignment: .center, spacing: 16) {
            LabeledTextField(
                placeholder: nil,
                title: L10n.CloudUserLogin.InputEmail.title,
                string: .constant(email)
            )
            .disabled(true)
            .fixedSize(horizontal: false, vertical: true)

            PasswordField(
                isPasswordValid: $isPasswordValid,
                password: $password,
                passwordValidator: passwordValidator,
                placeholder: L10n.CloudUserLogin.InputPassword.placeholder,
                title: L10n.CloudUserLogin.InputPassword.title)


            Button(action: {
            }, label: {
                Text(L10n.CloudUserLogin.submit)
                    .lineLimit(nil)
            })
            .wireButtonStyle(.primary)
                        .disabled(!isPasswordValid)
            Button(action: {
                UIApplication.shared.open(forgotPasswordURL)
            }, label: {
                Text(L10n.CloudUserLogin.forgotPassword)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            })
            .wireButtonStyle(.link)
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
    BackgroundView()
        .overlay {
            VStack(spacing: 0) {
                Spacer()
                    .frame(maxHeight: .infinity)
                LoginWithClaimedDomainPreview()
            }
        }
}
