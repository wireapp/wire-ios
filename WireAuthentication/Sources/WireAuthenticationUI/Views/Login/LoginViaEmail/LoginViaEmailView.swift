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

public protocol LoginViaEmailBuilder {

    @MainActor
    func loginViaEmailView(email: String) -> LoginViaEmailView

}

public struct LoginViaEmailView: View {
    @ObservedObject var viewModel: LoginViaEmailViewModel

    @State var password: String = ""

    public init(
        viewModel: LoginViaEmailViewModel
    ) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 14) {
                LabeledTextField(
                    placeholder: nil,
                    title: L10n.CloudUserLogin.InputEmail.title,
                    string: .constant(viewModel.email)
                )
                .disabled(true)

                PasswordField(
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
                .disabled(!viewModel.isValidPassword(password))

                Button(action: {
                    UIApplication.shared.open(viewModel.forgotPasswordURL)
                }, label: {
                    Text(L10n.CloudUserLogin.forgotPassword)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                })
                .wireButtonStyle(.link)
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
    }
}

#Preview() {
    BackgroundView()
        .sheet(isPresented: .constant(true)) {
            MockDependencies().loginViaEmailView(email: "foo@bar.com")
        }
}
