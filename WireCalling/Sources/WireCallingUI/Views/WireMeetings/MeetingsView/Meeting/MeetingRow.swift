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
import WireLocators

struct MeetingRow: View {
    private typealias Strings = L10n.Localizable.WireMeetings.List

    let occurrence: MeetingOccurrence
    let formatTime: (MeetingOccurrence) -> String
    var isAttending: Bool = false
    var isLive: Bool = false
    let onEdit: () -> Void
    let onDelete: () -> Void
    var onJoin: () -> Void = {}

    @Environment(\.wireAccentColor) private var wireAccentColor

    @ScaledMetric private var iconBoxSize: CGFloat = 31
    @ScaledMetric private var iconFontSize: CGFloat = 15

    private var meeting: Meeting {
        occurrence.meeting
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "calendar")
                .font(.system(size: iconFontSize, weight: .semibold))
                .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
                .frame(width: iconBoxSize, height: iconBoxSize)
                .background(
                    ColorTheme.Backgrounds.surface.color,
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(ColorTheme.Strokes.outline.color, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .top) {
                    Text(meeting.title)
                        .font(for: .body2)
                        .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
                        .lineLimit(2)

                    Spacer()

                    Menu {
                        Button {
                            onJoin()
                        } label: {
                            Label {
                                Text(Strings.Actions.joinNow)
                            } icon: {
                                Image(.videoCall)
                                    .renderingMode(.template)
                            }
                        }

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
                            .padding(.horizontal, 12)
                            .padding(.vertical, 20)
                            .contentShape(Rectangle())
                    }
                    .menuOrder(.fixed)
                    .padding(.vertical, -12)
                }

                HStack(spacing: 8) {
                    Text(formatTime(occurrence))
                        .font(for: .subline1)
                        .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)

                    if let recurrence = meeting.recurrence {
                        recurrenceBadge(recurrence.title)
                    }
                }

                if let conversation = meeting.conversation, !conversation.participants.isEmpty {
                    MemberAvatarsView(members: Array(conversation.participants))
                        .padding(.top, 2)
                }
                if isAttending {
                    attendingLabel
                        .padding(.top, 10)
                } else if isLive {
                    joinButton
                        .padding(.top, 10)
                }
            }
        }
    }

    private var joinButton: some View {
        Button(action: onJoin) {
            HStack(spacing: 8) {
                Image(.videoCall)
                    .renderingMode(.template)
                    .accessibilityHidden(true)

                Text(Strings.Actions.join)
            }
            .font(for: .buttonSmall)
            .foregroundStyle(ColorTheme.Base.onPrimary.color)
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(ColorTheme.Base.primary(wireAccentColor).color, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(Locators.WireMeetings.MeetingRow.joinButton)
        .accessibilityLabel(Text(L10n.Accessibility.WireMeetings.JoinButton.description))
    }

    private var attendingLabel: some View {
        HStack(spacing: 6) {
            Image(.videoCall)
                .renderingMode(.template)
                .accessibilityHidden(true)

            Text(Strings.attending)
        }
        .font(for: .body2)
        .foregroundStyle(ColorTheme.Base.primary(wireAccentColor).color)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(Locators.WireMeetings.MeetingDetails.attendingLabel)
        .accessibilityLabel(Text(Strings.attending))
    }

    private func recurrenceBadge(_ title: String) -> some View {
        Text(title)
            .font(for: .subline1)
            .foregroundStyle(ColorTheme.Base.secondaryText.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(ColorTheme.Strokes.outline.color, lineWidth: 1)
            )
    }
}

// MARK: - Recurrence label

private extension MeetingRecurrence {

    private typealias Strings = L10n.Localizable.WireMeetings.Schedule.Time

    var title: String {
        switch (frequency, interval) {
        case (.daily, _): Strings.daily
        case (.weekly, 2): Strings.everyTwoWeeks
        case (.weekly, 4): Strings.everyFourWeeks
        case (.weekly, _): Strings.weekly
        case (.monthly, _): Strings.monthly
        case (.yearly, _): Strings.yearly
        }
    }

}

#Preview {
    let meeting = Meeting(
        id: QualifiedID(id: UUID(), domain: ""),
        title: "Meeting1",
        start: Date(),
        end: Date(),
        recurrence: MeetingRecurrence(frequency: .daily, interval: 1),
        conversation: MeetingConversation(
            participants: [
                MeetingMember(
                    qualifiedID: QualifiedID(id: UUID(), domain: ""),
                    name: "Alice Smith",
                    handle: "alice",
                    isSelfUser: true,
                    initials: "AS",
                    accentColor: .default,
                    avatarImageData: nil
                ),
                MeetingMember(
                    qualifiedID: QualifiedID(id: UUID(), domain: ""),
                    name: "Bob Jones",
                    handle: "bob",
                    isSelfUser: false,
                    initials: "BJ",
                    accentColor: .default,
                    avatarImageData: nil
                )
            ]
        ),
        conversationID: QualifiedID(id: UUID(), domain: ""),
        creatorID: QualifiedID(id: UUID(), domain: "")
    )

    let formatter = MeetingsFormatter()

    VStack(alignment: .leading, spacing: 24) {
        MeetingRow(
            occurrence: MeetingOccurrence(meeting: meeting),
            formatTime: { formatter.startedAt($0.start) },
            isLive: true,
            onEdit: {},
            onDelete: {},
            onJoin: {}
        )

        MeetingRow(
            occurrence: MeetingOccurrence(meeting: meeting),
            formatTime: { formatter.startedAt($0.start) },
            isAttending: true,
            isLive: true,
            onEdit: {},
            onDelete: {}
        )

        MeetingRow(
            occurrence: MeetingOccurrence(meeting: meeting),
            formatTime: { formatter.timeRange(from: $0.start, to: $0.end) },
            onEdit: {},
            onDelete: {}
        )
    }
    .padding()
}
