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
    private static let maxRecentCount = 5

    let axis: Axis
    var onEmojiTap: (String) -> Void
    var onOpenPicker: () -> Void

    @State private var recentEmojis: [String] = []

    private var allEmojis: [String] {
        let presets = Self.presetEmojis
        let recents = recentEmojis.filter { !presets.contains($0) }.prefix(Self.maxRecentCount)
        return presets + recents
    }

    var body: some View {
        if axis == .vertical {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 8) {
                    ForEach(allEmojis, id: \.self) { emojiTile($0) }
                    moreButton
                }
                .padding(.vertical, 8)
            }
            .onAppear { loadRecentEmojis() }
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(allEmojis, id: \.self) { emojiTile($0) }
                    moreButton
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .onAppear { loadRecentEmojis() }
        }
    }

    private func emojiTile(_ emoji: String) -> some View {
        Button {
            registerRecent(emoji)
            onEmojiTap(emoji)
        } label: {
            Text(emoji)
                .font(.system(size: 32))
                .frame(width: 48, height:48)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(ColorTheme.Buttons.Secondary.enabled.color)
                )
        }
    }

    private var moreButton: some View {
        Button {
            onOpenPicker()
        } label: {
            Image(systemName: "face.smiling")
                .font(.system(size: 32))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
        }
    }

    private func loadRecentEmojis() {
        guard recentEmojis.isEmpty else { return }
        recentEmojis = EmojiRepository().fetchRecentlyUsedEmojis().map(\.value)
    }

    private func registerRecent(_ emoji: String) {
        let repo = EmojiRepository()
        var updated = [emoji] + recentEmojis.filter { $0 != emoji }
        if updated.count > 15 { updated = Array(updated.prefix(15)) }
        repo.registerRecentlyUsedEmojis(updated)
        recentEmojis = updated
    }
}

// MARK: - Preview

#Preview("Horizontal (portrait)") {
    VStack {
        Spacer()
        CallReactionsTray(axis: .horizontal, onEmojiTap: { print("tapped \($0)") }, onOpenPicker: {})
        Spacer()
    }
    .background(Color(.systemGray5))
}

#Preview("Vertical (landscape)") {
    HStack {
        Spacer()
        CallReactionsTray(axis: .vertical, onEmojiTap: { print("tapped \($0)") }, onOpenPicker: {})
            .frame(width: 72)
            .background(Color(.systemBackground))
        Spacer()
    }
    .frame(height: 400)
    .background(Color(.systemGray5))
}
