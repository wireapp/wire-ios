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

public struct DetermineAuthMethodView: View {

    @ObservedObject
    var viewModel: DetermineAuthMethodViewModel

    let builder: LoginViaEmailBuilder

    @State
    private var emailOrSSOCode = ""

    public init(
        viewModel: DetermineAuthMethodViewModel,
        builder: LoginViaEmailBuilder
    ) {
        self.viewModel = viewModel
        self.builder = builder
    }

    public var body: some View {
        VStack(spacing: 20) {
            Text("Wire").font(.largeTitle)
            Text("Enter your email to start")

            TextField("Email or SSO Code", text: $emailOrSSOCode)
                .textFieldStyle(.roundedBorder)

            Button("Next") {
                viewModel.submitEmailOrSSOCode(emailOrSSOCode)
            }
            .disabled(!viewModel.isValidEmailOrSSOCode(emailOrSSOCode))

            Text("By pressing on “Next”, you accept Wire’s Terms and Conditions")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationDestination(for: Destination.self) {
            switch $0 {
            case .login(let email):
                builder.loginViaEmailView(email: email)
            case .loginOrRegister:
                Color.red
            }
        }
    }

    enum Destination: Hashable {

        case login(email: String)
        case loginOrRegister(email: String)

    }

}

#Preview {
    MockDependencies().landingView
}
