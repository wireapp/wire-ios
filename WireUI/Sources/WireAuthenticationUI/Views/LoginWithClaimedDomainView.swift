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

    @State var password: String = ""

    package init(email: String, forgotPasswordURL: URL) {
        self.email = email
        self.forgotPasswordURL = forgotPasswordURL
    }

    package var body: some View {
        LabeledTextField(
            placeholder: nil,
            title: L10n.CloudUserLogin.emailHeader,
            string: .constant(email)
        )
        .disabled(true)
        LabeledTextField(
            placeholder: "Password",
            title: "Password",
            string: $password
        )
        Button(action: {
            // Login
        }, label: {
            Text(L10n.CloudUserLogin.submit)
        })
        .wireButtonStyle(.primary)
        .disabled(password.count < 4)

        Button(action: {
            UIApplication.shared.open(forgotPasswordURL)
        }, label: {
            Text(L10n.CloudUserLogin.forgotPassword)
        })
        .wireButtonStyle(.link)

        .padding(.top, 8)
        .padding(.bottom, 8)

        .navigationTitle(L10n.CloudUserLogin.title)
    }
}

#Preview {
    LoginWithClaimedDomainView(
        email: "email@wire.com",
        forgotPasswordURL: URL(string: "https://example.com")!)
}
