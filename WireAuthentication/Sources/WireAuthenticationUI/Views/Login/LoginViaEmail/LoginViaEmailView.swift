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
    func loginViaEmailView(email: String) -> LoginViaEmailView

}

package struct LoginViaEmailView: View {
    @ObservedObject var viewModel: LoginViaEmailViewModel

    @State private var password: String = ""
    @State private var showPasswordRules: Bool = false

    package init(
        viewModel: LoginViaEmailViewModel
    ) {
        self.viewModel = viewModel
    }

    package var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 14) {
                emailField
                passwordField
                submitButton
                forgotPasswordButton
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
        .presentationDetents([.medium, .large])
        .interactiveDismissDisabled()
        .presentationDragIndicator(.hidden)
        .onChange(of: password) { newPassword in
            showPasswordRules = !viewModel.isValidPassword(newPassword)
        }
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
            password: $password,
            passwordRules: viewModel.localizedPasswordRules,
            arePasswordRulesVisible: $showPasswordRules,
            placeholder: L10n.CloudUserLogin.InputPassword.placeholder,
            title: L10n.CloudUserLogin.InputPassword.title,
            titleColor: titleColor,
            borderColor: borderColor
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

    // MARK: - Helper

    private var titleColor: Color {
        switch (password.isEmpty, viewModel.isValidPassword(password)) {
        case (_, false):
            ColorTheme.Base.error.color
        case (true, _):
            ColorTheme.Base.labelTitle.color
        case (false, true):
            ColorTheme.Base.primary.color
        }
    }

    private var borderColor: Color {
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
            MockDependencies().loginViaEmailView(email: "foo@bar.com")
        }
}
