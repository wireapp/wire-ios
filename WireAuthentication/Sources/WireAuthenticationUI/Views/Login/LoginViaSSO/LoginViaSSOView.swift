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

package protocol LoginViaSSOBuilder {

    @MainActor
    func loginViaSSOView(ssoCode: UUID) -> LoginViaSSOView

}

package struct LoginViaSSOView: View {

    @ObservedObject var viewModel: LoginViaSSOViewModel
    @State private var showAlert = true

    package init(
        viewModel: LoginViaSSOViewModel
    ) {
        self.viewModel = viewModel
    }

    package var body: some View {
        if let ssoURL = viewModel.ssoURL {
            SafariBrowser(url: ssoURL)
        } else {
            Text("SSO URL is not available.")
                .alert("Error", isPresented: $showAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("Please try again later.")
                }
        }
    }
}

#Preview {
    LoginViaSSOView(viewModel: {
        let viewModel = LoginViaSSOViewModel(ssoCode: UUID())
        viewModel.ssoURL = URL(string: "https://www.google.com")!
        return viewModel
    }())
}
