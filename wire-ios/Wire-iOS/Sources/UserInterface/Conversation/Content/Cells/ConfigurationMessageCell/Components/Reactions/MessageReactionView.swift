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

struct MessageReactionView: View {

    var reaction: MessageReaction

    var body: some View {

        let text = Text(verbatim: reaction.emojiID + " \(reaction.count)")
            .font(.caption)
            .bold()
            .padding(.vertical, 4)
            .padding(.horizontal, 8)

        if reaction.isSelfUserReacting {
            text
                .foregroundStyle(.tint)
                .background(
                    Capsule()
                        .fill(.blue.opacity(0.5)) // TODO: fix color
                )
                .overlay(
                    Capsule()
                        .stroke(.blue, lineWidth: 1) // TODO: fix color
                )
                .tint(.blue)
        } else {
            text
                .foregroundStyle(.gray)
                .overlay(
                    Capsule()
                        .stroke(.blue, lineWidth: 1) // TODO: fix color
                )
                .tint(.gray)
        }
    }
}

#Preview("self-user-reacting") {
    let reaction = MessageReaction(emojiID: "🧹", count: 1, isSelfUserReacting: true)
    MessageReactionView(reaction: reaction)
}

#Preview("other-users-reacting") {
    let reaction = MessageReaction(emojiID: "🧹", count: 1, isSelfUserReacting: false)
    MessageReactionView(reaction: reaction)
}
