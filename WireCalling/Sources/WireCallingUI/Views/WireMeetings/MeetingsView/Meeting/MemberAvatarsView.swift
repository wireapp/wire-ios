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
    let members: [Member]

    private let maxVisible = 5
    private let circleSize: CGFloat = 24
    private let overlap: CGFloat = 8

    var body: some View {
        if members.count == 1 {
            HStack(spacing: 6) {
                circle()

                if !members[0].name.isEmpty {
                    Text(members[0].name)
                        .font(for: .subline1)
                        .foregroundStyle(ColorTheme.Base.secondaryText.color)
                        .lineLimit(1)
                }
            }
        } else {
            let overflow = members.count - maxVisible

            HStack(spacing: 6) {
                HStack(spacing: -overlap) {
                    ForEach(Array(members.prefix(maxVisible).enumerated()), id: \.offset) { index, _ in
                        circle()
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
    }

    private func circle() -> some View {
        Circle()
            .fill(Color.gray.opacity(0.35))
            .frame(width: circleSize, height: circleSize)
            .overlay(
                Circle().strokeBorder(ColorTheme.Backgrounds.surface.color, lineWidth: 2)
            )
    }
}

#Preview {
    MemberAvatarsView(members: [])
}
