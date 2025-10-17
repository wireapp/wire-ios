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

package import SwiftUI
import WireCallingDomain
import WireDesign
package import WireFoundation

package struct MeetingsListView: View {

    private typealias Strings = L10n.Localizable.WireMeetings.List

    @ObservedObject private var viewModel: MeetingsListViewModel
    let mapping: WireAccentColorMapping
    let color: WireAccentColor

    package init(viewModel: MeetingsListViewModel, mapping: WireAccentColorMapping, color: WireAccentColor) {
        self.viewModel = viewModel
        self.mapping = mapping
        self.color = color
    }

    package var body: some View {
        VStack {
            Picker("", selection: $viewModel.selectedTab) {
                ForEach(MeetingsListViewModel.Tab.allCases, id: \.self) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .accessibilityIdentifier("meetingsListPicker")

            content.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(ColorTheme.Backgrounds.surface.color)
        .environment(\.wireAccentColorMapping, mapping)
        .environment(\.wireAccentColor, color)
    }

    @ViewBuilder private var content: some View {
        List {
            if viewModel.selectedTab == .next {
                if !viewModel.ongoingMeetings.isEmpty {
                    Section {
                        ForEach(viewModel.groupedOngoing.first?.timeSlots.first?.meetings ?? [], id: \.id) { meeting in
                            MeetingRow(
                                state: MeetingState(
                                    meeting: meeting,
                                    currentDate: viewModel.currentDate
                                )
                            )
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .listRowBackground(color.primary)
//                            .listRowBackground(
//                                RoundedRectangle(cornerRadius: 12, style: .continuous)
//                                    .fill(Color.blue.opacity(0.12))
//                                    .overlay(
//                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
//                                            .stroke(Color.blue.opacity(0.35), lineWidth: 1)
//                                    )
//                            )
                        }
                    } header: {
                        SectionTitle(Strings.Header.ongoing)
                    }
                }
                GroupedSections(
                    groups: viewModel.groupedNext,
                    formatDay: viewModel.formatDay(_:),
                    formatTime: viewModel.formatTime(_:)
                )

                if viewModel.hasMoreNext {
                    Button {
                        viewModel.showAllNext = true
                    } label: {
                        Text(Strings.Actions.showAll)
                            .font(.textStyle(.buttonBig))
                    }
                    .wireButtonStyle(.secondary)
                    .listRowBackground(Color.clear)
                }
            } else {
                GroupedSections(
                    groups: viewModel.groupedPast,
                    formatDay: viewModel.formatDay(_:),
                    formatTime: viewModel.formatTime(_:)
                )
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(ColorTheme.Backgrounds.surface.color)
    }
}

private func SectionTitle(_ text: String) -> some View {
    Text(text)
        .font(.textStyle(.body2))
        .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
        .textCase(nil)
}

private func TimeHeader(_ text: String) -> some View {
    Text(text)
        .font(.textStyle(.subline1))
        .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
}

private struct GroupedSections: View {
    let groups: [(day: Date, timeSlots: [(time: Date, meetings: [Meeting])])]
    let formatDay: (Date) -> String
    let formatTime: (Date) -> String

    var body: some View {
        ForEach(groups, id: \.day) { dayGroup in
            Section {
                ForEach(dayGroup.timeSlots, id: \.time) { slot in
                    Section {
                        ForEach(slot.meetings, id: \.id) { meeting in
                            MeetingRow(
                                state: MeetingState(
                                    meeting: meeting,
                                    currentDate: Date()
                                )
                            )
                        }
                    } header: {
                        TimeHeader(formatTime(slot.time))
                    }
                }
            } header: {
                SectionTitle(formatDay(dayGroup.day))
            }
        }
    }
}

// MARK: - Row

private struct MeetingRow: View {
    private typealias Strings = L10n.Localizable.WireMeetings.MeetingDetails

    @Environment(\.wireAccentColor) private var accentColor

    let state: MeetingState
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(ColorTheme.Backgrounds.surface.color)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(ColorTheme.Strokes.outline.color, lineWidth: 1)
                        )
                        .frame(width: 31, height: 31)

                    Image(systemName: "video.fill").font(.system(size: 15))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(state.meeting.title)
                        .font(.textStyle(.body2))
                        .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
                        .lineLimit(2)
                    Text(state.dateText)
                        .font(.textStyle(.subline1))
                        .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
                    if !state.meeting.participants.isEmpty {
                        HStack(spacing: -8) {
                            let maxAvatars = min(5, state.meeting.participants.count)
                            let displayed = Array(state.meeting.participants.prefix(maxAvatars))
                            ForEach(displayed) { participant in
                                ZStack {
                                    Circle()
                                        .fill(participant.color)
                                        .frame(width: 30, height: 30)
                                    Text(participant.initials)
                                        .foregroundColor(.white)
                                        .font(.caption)
                                }
                            }
                            if state.meeting.participants.count > 5 {
                                let remaining = state.meeting.participants.count - 5
                                Text("+\(remaining)")
                                    .padding(.leading, 12)
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                        }
                    }
                    Group {
                        if state.isStartingSoon {
                            Text("\(Strings.startingIn) \(state.startingInText)")
                                .font(.textStyle(.body2))
                                .foregroundColor(Color(accentColor))
                        } else if state.isOngoing {
                            if state.meeting.isNew {
                                Button {
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(.videoCall)
                                                .renderingMode(.template)
                                            Text(Strings.join)
                                                .font(.textStyle(.h4))
                                        }
                                        .foregroundStyle(ColorTheme.Base.onPrimary.color)
                                        .padding(.horizontal, 16)
                                        .frame(height: 36)
                                        .background(Color(accentColor))
                                        .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                            } else {
                                HStack(spacing: 4) {
                                    Image(.videoCall)
                                        .renderingMode(.template)
                                    Text(Strings.attending)
                                        .font(.textStyle(.body2))
                                }
                                .foregroundStyle(Color(accentColor))
                            }
                        }
                    }
                    .padding(.top, 8)
                }

                Spacer()

                Image(systemName: "ellipsis")
                    .rotationEffect(.degrees(90))
                    .foregroundStyle(ColorTheme.Buttons.Secondary.onEnabled.color)
                    .padding(.top, 12)

            }

        }
        .padding(.vertical, 4)
    }

}

// #Preview {
//    MeetingsListView(viewModel: MeetingsListViewModel(meetings: []))
// }

// #Preview("Upcoming") {
//    let formatter = DateFormatter()
//    formatter.dateFormat = "yyyy-MM-dd HH:mm"
//    let currentDate = formatter.date(from: "2025-10-14 16:00")!
//    let meeting = Meeting(
//        id: UUID(),
//        title: "Candidate Interview: Charles Royale",
//        start: formatter.date(from: "2025-10-14 17:00")!,
//        end: formatter.date(from: "2025-10-14 17:15")!,
//        participants: [
//            Participant(initials: "AF"),
//            Participant(initials: "WI"),
//            Participant(initials: "JO"),
//            Participant(initials: "BN"),
//            Participant(initials: "FS"),
//            Participant(initials: "GF"),
//            Participant(initials: "KO")
//        ]
//    )
//    return MeetingRow2(meeting: meeting, currentDate: currentDate)
// }
//
// #Preview("Starting Soon") {
//    let formatter = DateFormatter()
//    formatter.dateFormat = "yyyy-MM-dd HH:mm"
//    let currentDate = formatter.date(from: "2025-10-14 16:00")!
//    let meeting = Meeting(
//        id: UUID(),
//        title: "Candidate Interview: Charles Royale",
//        start: formatter.date(from: "2025-10-14 16:03")!,
//        end: formatter.date(from: "2025-10-14 16:18")!,
//        participants: [Participant(initials: "AF"), Participant(initials: "WI")]
//    )
//    return MeetingRow2(meeting: meeting, currentDate: currentDate)
// }
//
// #Preview("Now (New)") {
//    let formatter = DateFormatter()
//    formatter.dateFormat = "yyyy-MM-dd HH:mm"
//    let currentDate = formatter.date(from: "2025-10-14 16:00")!
//    let meeting = Meeting(
//        id: UUID(), title: "Candidate Interview: Charles Royale",
//        start: formatter.date(from: "2025-10-14 15:50")!,
//        end: formatter.date(from: "2025-10-14 16:15")!,
//        isNew: true,
//        participants: [Participant(initials: "JO")]
//    )
//    return MeetingRow2(meeting: meeting, currentDate: currentDate)
// }
//
// #Preview("Participating (Ongoing)") {
//    let formatter = DateFormatter()
//    formatter.dateFormat = "yyyy-MM-dd HH:mm"
//    let currentDate = formatter.date(from: "2025-10-14 16:00")!
//    let meeting = Meeting(
//        id: UUID(),
//        title: "Candidate Interview: Charles Royale",
//        start: formatter.date(from: "2025-10-14 15:50")!,
//        end: formatter.date(from: "2025-10-14 16:15")!,
//        isNew: false,
//        participants: [
//            Participant(initials: "AF"),
//            Participant(initials: "WI"),
//            Participant(initials: "JO")
//        ]
//    )
//    return MeetingRow2(meeting: meeting, currentDate: currentDate)
// }
//
// #Preview("Past") {
//    let formatter = DateFormatter()
//    formatter.dateFormat = "yyyy-MM-dd HH:mm"
//    let currentDate = formatter.date(from: "2025-10-14 16:00")!
//    let meeting = Meeting(
//        id: UUID(),
//        title: "Candidate Interview: Charles Royale",
//        start: formatter.date(from: "2025-10-14 14:00")!,
//        end: formatter.date(from: "2025-10-14 14:15")!,
//        participants: Array(repeating: Participant(initials: "P"), count: 5))
//    return MeetingRow2(meeting: meeting, currentDate: currentDate)
// }

