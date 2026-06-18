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

import SwiftUI
import WireDesign

/// Emoji picker strip shown when the user opens the reaction tray during a call.
/// - `.vertical` axis: stacked column used in landscape alongside the action buttons.
/// - `.horizontal` axis: scrollable row used in portrait above the action buttons.
struct CallReactionsTray: View {

    static let presetEmojis = ["👍", "🎉", "❤️", "👏", "😊"]

    let axis: Axis
    var onEmojiTap: (String) -> Void

    var body: some View {
        if axis == .vertical {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 8) {
                    ForEach(Self.presetEmojis, id: \.self) { emojiTile($0) }
                }
                .padding(.vertical, 8)
            }
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Self.presetEmojis, id: \.self) { emojiTile($0) }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
    }

    private func emojiTile(_ emoji: String) -> some View {
        Button { onEmojiTap(emoji) } label: {
            Text(emoji)
                .font(.system(size: 30))
                .frame(width: 56, height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(ColorTheme.Buttons.Secondary.enabled.color)
                )
        }
    }
}

// MARK: - Preview

#Preview("Horizontal (portrait)") {
    VStack {
        Spacer()
        CallReactionsTray(axis: .horizontal) { print("tapped \($0)") }
        Spacer()
    }
    .background(Color(.systemGray5))
}

#Preview("Vertical (landscape)") {
    HStack {
        Spacer()
        CallReactionsTray(axis: .vertical) { print("tapped \($0)") }
            .frame(width: 72)
            .background(Color(.systemBackground))
        Spacer()
    }
    .frame(height: 400)
    .background(Color(.systemGray5))
}
