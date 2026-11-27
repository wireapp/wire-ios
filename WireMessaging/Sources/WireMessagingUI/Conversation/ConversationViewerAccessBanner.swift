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
    private let isGracePeriod: Bool

    public init(backgroundColor: UIColor, isGracePeriod: Bool = false, onClose: @escaping () -> Void) {
        self.backgroundColor = backgroundColor
        self.isGracePeriod = isGracePeriod
        self.onClose = onClose
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 12) {
            if isGracePeriod {
                Image(systemName: "info.circle")
                    .font(for: .h5)
                    .foregroundStyle(foregroundColor)
                    .accessibilityHidden(true)
            }

            Text(isGracePeriod ? Strings.Files.ViewerAccess.gracePeriodBanner : Strings.Files.ViewerAccess.banner)
                .font(for: .h5)
                .foregroundStyle(foregroundColor)

            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .foregroundStyle(foregroundColor)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Accessibility.Files.ViewerAccess.Banner.close)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, isGracePeriod ? 8 : 0)
        .frame(minHeight: 32)
        .background(isGracePeriod ? ColorTheme.Base.warning.color : backgroundColor.color)
    }

    private var foregroundColor: Color {
        isGracePeriod ? ColorTheme.Base.onWarning.color : Color.primary
    }
}

#Preview {
    ConversationViewerAccessBanner(backgroundColor: ColorTheme.Buttons.Secondary.disabled) {}
}

#Preview("Grace period") {
    ConversationViewerAccessBanner(
        backgroundColor: ColorTheme.Buttons.Secondary.disabled,
        isGracePeriod: true
    ) {}
}
