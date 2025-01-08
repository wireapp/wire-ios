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
import WireFoundation
import WireReusableUIComponents

package struct AuthenticationIdentityInputView: View {

    package enum Action {
        case submit(identity: String)
    }

    @State private var identity: String = ""
    private let actionCallback: @Sendable (Action) -> Void
    private let termsURL: URL

    package init(actionCallback: @escaping @Sendable (Action) -> Void, termsURL: URL) {
        self.actionCallback = actionCallback
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
            Text(L10n.Authentication.Identity.Input.body)
                .wireTextStyle(.body1)
            LabeledTextField(
                isMandatory: true,
                placeholder: L10n.Authentication.Identity.Input.Field.placeholder,
                title: L10n.Authentication.Identity.Input.Field.title,
                string: $identity
            )
            Button(action: {
                actionCallback(.submit(identity: identity))
            }, label: {
                Text(L10n.Authentication.Identity.Input.submit)
            })
            .wireButtonStyle(.primary)
            Text(AttributedString.markdown(from: L10n.Authentication.Identity.Input.terms(termsURL.absoluteString)))
                .multilineTextAlignment(.center)
                .wireTextStyle(.subline1)
        }
    }
}

struct AuthenticationIdentityInputPreview: View {
    var body: some View {
        AuthenticationIdentityInputView(
            actionCallback: { _ in },
            termsURL: URL(string: "https://example.com")!
        )
        .environment(\.wireTextStyleMapping, WireTextStyleMapping())
        .padding(32)
    }
}

#Preview {
    AuthenticationIdentityInputPreview()
}
