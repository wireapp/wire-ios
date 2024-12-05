//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

struct LoginView: View {

    @ObservedObject
    var viewModel: LoginViewModel

    @State
    private var password = ""

    var body: some View {
        VStack(spacing: 20) {
            TextField("", text: .constant(viewModel.email))
                .textFieldStyle(.roundedBorder)
                .foregroundStyle(.secondary)
                .disabled(true)


            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)

            Button("Next") {
                viewModel.submitPassword(password)
            }
            .disabled(!viewModel.isValidPassword(password))

            Text("Forgot password?")
                .underline()

            if viewModel.isRegistrationAllowed {
                VStack {
                    Text("Don't have a Wire account?")
                    Text("Create Account").underline()
                }
                .padding()
                .border(.secondary)
            }

            Spacer()

        }
        .navigationTitle("Enter your password to log in")
        .navigationBarTitleDisplayMode(.inline)
        .padding()
    }
}

#Preview {
    NavigationView {
        LoginView(
            viewModel: LoginViewModel(
                router: Router(),
                emailLogIn: EmailLogInUseCaseMock(),
                isRegistrationAllowed: true
            )
        )
    }
}
