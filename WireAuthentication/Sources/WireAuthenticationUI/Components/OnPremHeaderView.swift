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
import WireAuthenticationAPI
import WireDesign

package struct OnPremHeaderView: View {

    @State private var showCustomBackendAlert = false
    private let backendTitle: String
    private let restAPIURL: URL

    private typealias Strings = L10n.Localizable.OnPremUserLogin

    package init(
        backendTitle: String,
        restAPIURL: URL
    ) {
        self.backendTitle = backendTitle
        self.restAPIURL = restAPIURL
    }

    private var backendInfo: String {
        [
            Strings.Alert.Message.backendName,
            backendTitle,
            "",
            Strings.Alert.Message.backendUrl,
            restAPIURL.absoluteString
        ].joined(separator: "\n")
    }

    package var body: some View {
        Button(action: {
            showCustomBackendAlert.toggle()
        }, label: {
            Text(Strings.title(backendTitle) + " ")
                .foregroundColor(ColorTheme.Buttons.Secondary.onEnabled.color)
                + Text(Image(systemName: "info.circle"))
                .foregroundColor(.gray)
        })
        .multilineTextAlignment(.center)
        .font(.textStyle(.h2))
        .lineLimit(nil)
        .fixedSize(horizontal: false, vertical: true)
        .alert(Strings.Alert.title, isPresented: $showCustomBackendAlert) {
            Button(Strings.Alert.button, role: .cancel) {}
        } message: {
            Text(backendInfo)
        }
    }
}

#Preview {
    OnPremHeaderView(
        backendTitle: "<backend name>",
        restAPIURL: URL(string: "example")!
    )
}
