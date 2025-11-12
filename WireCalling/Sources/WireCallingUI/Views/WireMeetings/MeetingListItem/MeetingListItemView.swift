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
import WireCallingDomain
import WireDesign

struct MeetingListItemView: View {

    @ObservedObject private var viewModel: MeetingListItemViewModel

    init(viewModel: MeetingListItemViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            iconView

            VStack(alignment: .leading, spacing: 2) {
                titleWithBadgeView
                dateView
                participantsView
            }

            Spacer()

            trailingView
        }
        .contentShape(Rectangle())
        .padding(.vertical, 6)
        .opacity(contentOpacity)
    }

    // MARK: - Subviews

    private var iconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(iconBackgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(iconBorderColor, lineWidth: iconBorderWidth)
                )
                .frame(width: 31, height: 31)

            Image(systemName: iconSystemName)
                .font(.system(size: 15))
                .foregroundStyle(iconColor)
        }
    }

    private var titleWithBadgeView: some View {
        HStack(spacing: 8) {
            Text(viewModel.meeting.title)
                .font(.textStyle(.body2))
                .foregroundStyle(titleColor)
                .lineLimit(2)

            if let badge = stateBadge {
                badge
            }
        }
    }

    private var dateView: some View {
        Text("Meeting date")
            .font(.textStyle(.subline1))
            .foregroundStyle(secondaryTextColor)
    }

    private var participantsView: some View {
        HStack(spacing: 6) {
            Label(participantCountText, systemImage: "person.3.fill")
                .font(.textStyle(.subline1))
                .foregroundStyle(ColorTheme.Base.secondaryText.color)
        }
        .padding(.top, 2)
    }

    private var participantCountText: String {
        let count = viewModel.meeting.conversation.members.count
        return count == 1 ? "1 participant" : "\(count) participants"
    }

    @ViewBuilder
    private var stateBadge: some View? {
        switch viewModel.state {
        case .startingSoon:
            Badge(text: "Starting Soon", color: .orange)
        case .live:
            Badge(text: "LIVE", color: .blue)
        case .joined:
            Badge(text: "Joined", color: .green)
        default:
            nil
        }
    }

    @ViewBuilder
    private var trailingView: some View {
        switch viewModel.state {
        case .joined:
            // Show active indicator for joined meeting
            VStack(spacing: 4) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                Text("Active")
                    .font(.textStyle(.subline1))
                    .foregroundStyle(Color.green)
            }
        default:
            // Show menu button for other states
            Image(systemName: "ellipsis")
                .rotationEffect(.degrees(90))
                .foregroundStyle(ColorTheme.Buttons.Secondary.onEnabled.color)
        }
    }

    // MARK: - State-based Styling

    private var contentOpacity: Double {
        viewModel.state == .ended ? 0.5 : 1.0
    }

    private var iconBackgroundColor: Color {
        switch viewModel.state {
        case .scheduled:
            return ColorTheme.Backgrounds.surface.color
        case .startingSoon:
            return Color.orange.opacity(0.1)
        case .live:
            return Color.blue.opacity(0.1)
        case .joined:
            return Color.green.opacity(0.1)
        case .ended:
            return ColorTheme.Backgrounds.surface.color
        }
    }

    private var iconBorderColor: Color {
        switch viewModel.state {
        case .scheduled, .ended:
            return ColorTheme.Strokes.outline.color
        case .startingSoon:
            return Color.orange
        case .live:
            return Color.blue
        case .joined:
            return Color.green
        }
    }

    private var iconBorderWidth: CGFloat {
        switch viewModel.state {
        case .scheduled, .ended:
            return 1
        case .startingSoon, .live, .joined:
            return 2
        }
    }

    private var iconSystemName: String {
        switch viewModel.state {
        case .joined:
            return "video.fill"
        default:
            return "video.fill"
        }
    }

    private var iconColor: Color {
        switch viewModel.state {
        case .scheduled, .ended:
            return ColorTheme.Backgrounds.onSurface.color
        case .startingSoon:
            return Color.orange
        case .live:
            return Color.blue
        case .joined:
            return Color.green
        }
    }

    private var titleColor: Color {
        ColorTheme.Backgrounds.onSurface.color
    }

    private var secondaryTextColor: Color {
        ColorTheme.Backgrounds.onSurface.color
    }
}

// MARK: - Badge Component

private struct Badge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.textStyle(.subline1))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(color.opacity(0.15))
            )
            .overlay(
                Capsule()
                    .strokeBorder(color, lineWidth: 1)
            )
    }
}

#Preview("Scheduled") {
    let conversation = Conversation(
        id: UUID(),
        name: "Team Standup",
        members: Conversation.Members(
            others: [
                Conversation.Member(id: UUID(), name: "Alice"),
                Conversation.Member(id: UUID(), name: "Bob")
            ],
            selfMember: Conversation.Member(id: UUID(), name: "You")
        )
    )
    let meeting = Meeting(
        id: UUID(),
        title: "Team Standup",
        start: Date().addingTimeInterval(3600), // 1 hour from now
        end: Date().addingTimeInterval(5400), // 1.5 hours from now
        conversation: conversation
    )
    let viewModel = MeetingListItemViewModel(
        meeting: meeting,
        currentDate: Date()
    )
    return MeetingListItemView(viewModel: viewModel)
        .padding()
}

#Preview("Starting Soon") {
    let conversation = Conversation(
        id: UUID(),
        name: "Design Review",
        members: Conversation.Members(
            others: [
                Conversation.Member(id: UUID(), name: "Designer Team")
            ],
            selfMember: Conversation.Member(id: UUID(), name: "You")
        )
    )
    let meeting = Meeting(
        id: UUID(),
        title: "Design Review",
        start: Date().addingTimeInterval(240), // 4 minutes from now
        end: Date().addingTimeInterval(1800), // 30 minutes from now
        conversation: conversation
    )
    let viewModel = MeetingListItemViewModel(
        meeting: meeting,
        currentDate: Date()
    )
    return MeetingListItemView(viewModel: viewModel)
        .padding()
}

#Preview("Live") {
    let conversation = Conversation(
        id: UUID(),
        name: "Product Planning",
        members: Conversation.Members(
            others: [
                Conversation.Member(id: UUID(), name: "Product Manager"),
                Conversation.Member(id: UUID(), name: "Engineer Lead")
            ],
            selfMember: Conversation.Member(id: UUID(), name: "You")
        )
    )
    let meeting = Meeting(
        id: UUID(),
        title: "Product Planning",
        start: Date().addingTimeInterval(-600), // Started 10 minutes ago
        end: Date().addingTimeInterval(1800), // Ends in 30 minutes
        conversation: conversation
    )
    let viewModel = MeetingListItemViewModel(
        meeting: meeting,
        currentDate: Date()
    )
    return MeetingListItemView(viewModel: viewModel)
        .padding()
}

#Preview("Joined") {
    let meetingId = UUID()
    let conversation = Conversation(
        id: UUID(),
        name: "Client Call",
        members: Conversation.Members(
            others: [
                Conversation.Member(id: UUID(), name: "Client"),
                Conversation.Member(id: UUID(), name: "Sales Rep")
            ],
            selfMember: Conversation.Member(id: UUID(), name: "You")
        )
    )
    let meeting = Meeting(
        id: meetingId,
        title: "Client Call",
        start: Date().addingTimeInterval(-300), // Started 5 minutes ago
        end: Date().addingTimeInterval(2700), // Ends in 45 minutes
        conversation: conversation
    )
    let viewModel = MeetingListItemViewModel(
        meeting: meeting,
        currentDate: Date(),
        participatingMeetingId: meetingId
    )
    return MeetingListItemView(viewModel: viewModel)
        .padding()
}

#Preview("Ended") {
    let conversation = Conversation(
        id: UUID(),
        name: "Sprint Retrospective",
        members: Conversation.Members(
            others: [
                Conversation.Member(id: UUID(), name: "Team Member 1"),
                Conversation.Member(id: UUID(), name: "Team Member 2"),
                Conversation.Member(id: UUID(), name: "Scrum Master")
            ],
            selfMember: Conversation.Member(id: UUID(), name: "You")
        )
    )
    let meeting = Meeting(
        id: UUID(),
        title: "Sprint Retrospective",
        start: Date().addingTimeInterval(-7200), // Started 2 hours ago
        end: Date().addingTimeInterval(-3600), // Ended 1 hour ago
        conversation: conversation
    )
    let viewModel = MeetingListItemViewModel(
        meeting: meeting,
        currentDate: Date()
    )
    return MeetingListItemView(viewModel: viewModel)
        .padding()
}
