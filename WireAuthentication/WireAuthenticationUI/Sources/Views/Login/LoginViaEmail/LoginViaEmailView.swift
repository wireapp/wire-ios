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

public protocol LoginViaEmailBuilder {

    @MainActor
    func loginViaEmailView(email: String) -> LoginViaEmailView

}

public struct LoginViaEmailView: View {

    @ObservedObject
    var viewModel: LoginViaEmailViewModel

    @State
    private var password = ""

    public init(
        viewModel: LoginViaEmailViewModel
    ) {
        self.viewModel = viewModel
    }

    public var body: some View {
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

            Spacer()
        }
        .navigationTitle("Enter your password to log in")
        .navigationBarTitleDisplayMode(.inline)
        .padding()
    }

}

#Preview {
    MockDependencies().loginViaEmailView(email: "foo@bar.com")
}
