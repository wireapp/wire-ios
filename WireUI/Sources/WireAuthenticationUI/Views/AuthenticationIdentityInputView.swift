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
import WireDesign
import WireFoundation
import WireReusableUIComponents

package struct AuthenticationIdentityInputView: View {
    @State private var identity: String = ""
    private let termsURL: URL

    package init(termsURL: URL) {
        self.termsURL = termsURL
    }

    package var body: some View {
        VStack(alignment: .center, spacing: 16) {
            HStack {
                Spacer()
                    .frame(maxWidth: .infinity)
                Logo()
                    .frame(width: 164, height: 95)
                Spacer()
                    .frame(maxWidth: .infinity)
            }
            Text("Simply enter you email adress to start!")
                .wireTextStyle(.body1)
            LabeledTextField(
                mandatory: true,
                placeholder: "Email or SSO code",
                title: "Email or SSO code",
                string: $identity
            )
            Button(action: {

            }, label: {
                Text("Next")
            })
            .wireButtonStyle(.primary)
            Text(AttributedString.markdown(from: String(format: "By pressing on “Next”, you accept Wire’s [Terms and Conditions](%@)", termsURL.absoluteString)))
                .multilineTextAlignment(.center)
                .wireTextStyle(.subline1)
        }
    }
}

#Preview {
    AuthenticationIdentityInputView(termsURL: URL(string: "https://example.com")!)
        .environment(\.wireTextStyleMapping, WireTextStyleMapping())
        .padding(32)
}
