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
import WireCallingDomain
import WireDesign

struct MemberAvatarsView: View {
    let members: [MeetingMember]

    private let maxVisible = 5
    private let circleSize: CGFloat = 24
    private let overlap: CGFloat = 8

    var body: some View {
        // Show up to `maxVisible` overlapping avatars; any remaining participants
        // are represented by a trailing "+N" count.
        let overflow = members.count - maxVisible

        HStack(spacing: 6) {
            HStack(spacing: -overlap) {
                ForEach(Array(members.prefix(maxVisible).enumerated()), id: \.offset) { index, member in
                    avatar(for: member)
                        .zIndex(Double(maxVisible - index))
                }
            }

            if overflow > 0 {
                Text("+\(overflow)")
                    .font(for: .subline1)
                    .foregroundStyle(ColorTheme.Base.secondaryText.color)
            }
        }
    }

    /// Renders a member's avatar: their profile image when available, otherwise their
    /// initials on an accent-colored background — the same image-or-initials fallback
    /// that `UserCell.avatarImageView` (`UserImageView`) performs in UIKit.
    private func avatar(for member: MeetingMember) -> some View {
        Group {
            if let image = member.avatarImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Text(member.initials)
                    .font(for: .subline1)
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(member.accentColor))
            }
        }
        .frame(width: circleSize, height: circleSize)
        .clipShape(Circle())
        .overlay(
            Circle().strokeBorder(ColorTheme.Backgrounds.surface.color, lineWidth: 2)
        )
    }
}

#Preview {
    MemberAvatarsView(members: [])
}
