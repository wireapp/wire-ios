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
import WireFoundation

struct MeetingRow: View {
    private typealias Strings = L10n.Localizable.WireMeetings.List

    let meeting: Meeting
    let formatTimeRange: (Meeting) -> String
    let onEdit: () -> Void
    let onDelete: () -> Void
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(ColorTheme.Backgrounds.surface.color)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(ColorTheme.Strokes.outline.color, lineWidth: 1)
                    )
                    .frame(width: 31, height: 31)

                Image(systemName: "calendar")
                    .font(.system(size: 15))
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline) {
                    Text(meeting.title)
                        .font(for: .body2)
                        .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
                        .lineLimit(2)

                    Spacer()

                    Menu {
                        Button {
                            onEdit()
                        } label: {
                            Label(Strings.Actions.edit, systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Label(Strings.Actions.delete, systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .rotationEffect(.degrees(90))
                            .foregroundStyle(ColorTheme.Buttons.Secondary.onEnabled.color)
                            .contentShape(Rectangle())
                    }
                }

                Text(formatTimeRange(meeting))
                    .font(for: .subline1)
                    .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)

                if !meeting.members.isEmpty {
                    MemberAvatarsView(members: meeting.members)
                        .padding(.top, 2)
                }
            }
        }
    }
}

#Preview {
    MeetingRow(
        meeting: Meeting(
            id: QualifiedID(id: UUID(), domain: ""),
            title: "Meeting1",
            start: Date(),
            end: Date(),
            recurrence: .none,
            repeatOption: .yearly,
            members: [],
            conversationID: QualifiedID(id: UUID(), domain: "")
        ),
        formatTimeRange: { _ in "Today" },
        onEdit: {},
        onDelete: {}
    )
}
