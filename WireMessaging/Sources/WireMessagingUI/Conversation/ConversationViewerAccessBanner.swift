//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

private typealias Strings = L10n.Localizable.Conversation.WireCells
private typealias Accessibility = L10n.Accessibility.Conversation.WireCells

public struct ConversationViewerAccessBanner: View {
    private let onClose: () -> Void
    private let backgroundColor: UIColor

    public init(backgroundColor: UIColor, onClose: @escaping () -> Void) {
        self.backgroundColor = backgroundColor
        self.onClose = onClose
    }

    public var body: some View {
        HStack(spacing: 12) {
            Text(Strings.Files.ViewerAccess.banner)
                .font(for: .h5)

            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark")
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Accessibility.Files.ViewerAccess.Banner.close)
        }
        .padding(.horizontal, 24)
        .frame(minHeight: 32)
        .background(backgroundColor.color)
    }
}

#Preview {
    ConversationViewerAccessBanner(backgroundColor: ColorTheme.Buttons.Secondary.disabled) {}
}
