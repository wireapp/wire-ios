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

public import SwiftUI

import WireDesign
import WireFoundation

public struct InfoBannerView: View {

    let title: String
    let message: String
    let button: InfoBannerButton?

    @Environment(\.wireAccentColor) private var wireAccentColor

    public init(
        title: String,
        message: String = "",
        button: InfoBannerButton? = nil
    ) {
        self.title = title
        self.message = message
        self.button = button
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle")
                    .accessibilityHidden(true)
                Text(title)
                Spacer()
            }
            .font(for: .h5)
            .fontWeight(.semibold)

            if !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(message)
                    .font(for: .subline1)
            }

            if let button {
                Button(action: button.action) {
                    Text(button.title)
                        .lineLimit(.none)
                }
                .wireButtonStyle(.tertiary)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(ColorTheme.Base.primaryVariant(wireAccentColor)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color(ColorTheme.Base.primary(wireAccentColor)))
        )
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    // MARK: - Nested Components

    public struct InfoBannerButton {
        public var title: String
        public var action: () -> Void
        public init(title: String, action: @escaping () -> Void) {
            self.title = title
            self.action = action
        }
    }

}

#Preview("title only") {
    InfoBannerView(title: "Enjoy benefits of a team")
        .environment(\.wireAccentColor, .purple)
}

#Preview("title and message") {
    InfoBannerView(
        title: "Enjoy benefits of a team",
        message: "Explore extra features for free with the same level of security."
    )
    .environment(\.wireAccentColor, .purple)
}

#Preview("title and button") {
    InfoBannerView(
        title: "Enjoy benefits of a team",
        button: .init(
            title: "Call to action",
            action: {}
        )
    )
    .environment(\.wireAccentColor, .purple)
}

#Preview("title, message and button") {
    InfoBannerView(
        title: "Enjoy benefits of a team",
        message: "Explore extra features for free with the same level of security.",
        button: .init(
            title: "Call to action",
            action: {}
        )
    )
    .environment(\.wireAccentColor, .purple)
}
