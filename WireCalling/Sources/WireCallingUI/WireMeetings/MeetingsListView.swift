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

package struct MeetingsListView: View {

    private typealias Strings = L10n.Localizable.WireMeetings.List

    @ObservedObject private var viewModel: MeetingsListViewModel

    package init(viewModel: MeetingsListViewModel) {
        self.viewModel = viewModel
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
    }

    @ViewBuilder private var content: some View {
        List {
            if viewModel.selectedTab == .next {
                if !viewModel.ongoingMeetings.isEmpty {
                    Section {
                        ForEach(viewModel.groupedOngoing.first?.timeSlots.first?.meetings ?? [], id: \.id) { meeting in
                            MeetingRow(meeting: meeting)
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
                            MeetingRow(meeting: meeting)
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
    let meeting: Meeting
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

                Image(systemName: "video.fill").font(.system(size: 15))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(meeting.title)
                    .font(.textStyle(.body2))
                    .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
                    .lineLimit(2)

                Text(
                    "\(DateFormatter.timeHeader.string(from: meeting.start)) – \(DateFormatter.timeHeader.string(from: meeting.end))"
                )
                .font(.textStyle(.subline1))
                .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)

                HStack(spacing: 6) {
                    Label("Design", systemImage: "person.3.fill")
                        .font(.textStyle(.subline1))
                        .foregroundStyle(ColorTheme.Base.secondaryText.color)
                }
                .padding(.top, 2)
            }

            Spacer()

            Image(systemName: "ellipsis")
                .rotationEffect(.degrees(90))
                .foregroundStyle(ColorTheme.Buttons.Secondary.onEnabled.color)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 6)
    }
}

#Preview {
    MeetingsListView(viewModel: MeetingsListViewModel(meetings: []))
}



//struct MeetingsView: View {
//    @StateObject private var viewModel: MeetingsListViewModel
//    init(meetings: [Meeting]) {
//        _viewModel = StateObject(wrappedValue: MeetingsListViewModel(meetings: meetings))
//    }
//
//    var body: some View {
//        NavigationStack {
//            VStack {
//                Picker("Tab", selection: $viewModel.selectedTab) {
//                    Text("Next").tag(MeetingsViewModel.Tab.next)
//                    Text("Past").tag(MeetingsViewModel.Tab.past)
//                }
//                .pickerStyle(.segmented)
//                .padding()
//
//                List {
//                    if viewModel.selectedTab == .next {
//                        if !viewModel.ongoingMeetings.isEmpty {
//                            Section(header: Text("Ongoing")) {
//                                ForEach(viewModel.groupedOngoing.first?.timeSlots.first?.meetings ?? [], id: \.id) { meeting in
//                                    MeetingRow(meeting: meeting, currentDate: viewModel.currentDate)
//                                }
//                            }
//                        }
//
//                        ForEach(viewModel.groupedNext, id: \.day) { dayGroup in
//                            Section(header: Text(viewModel.formatDay(dayGroup.day))) {
//                                ForEach(dayGroup.timeSlots, id: \.time) { timeSlot in
//                                    Section(header: Text(viewModel.formatTime(timeSlot.time))) {
//                                        ForEach(timeSlot.meetings, id: \.id) { meeting in
//                                            MeetingRow(meeting: meeting, currentDate: viewModel.currentDate)
//                                        }
//                                    }
//                                }
//                            }
//                        }
//
//                        if viewModel.hasMoreNext {
//                            Button("Show more") {
//                                viewModel.showAllNext = true
//                            }
//                            .frame(maxWidth: .infinity)
//                            .listRowBackground(Color.clear)
//                        }
//                    } else {
//                        ForEach(viewModel.groupedPast, id: \.day) { dayGroup in
//                            Section(header: Text(viewModel.formatDay(dayGroup.day))) {
//                                ForEach(dayGroup.timeSlots, id: \.time) { timeSlot in
//                                    Section(header: Text(viewModel.formatTime(timeSlot.time))) {
//                                        ForEach(timeSlot.meetings, id: \.id) { meeting in
//                                            MeetingRow(meeting: meeting, currentDate: viewModel.currentDate)
//                                        }
//                                    }
//                                }
//                            }
//                        }
//                    }
//                }
//                .listStyle(.plain)
//            }
//            .navigationTitle("Meetings")
//        }
//    }
//
//}

//struct MeetingRow1: View {
//    let meeting: Meeting
//    let currentDate: Date
//    private let calendar = Calendar.current
//    private var isOngoing: Bool {
//        meeting.start <= currentDate && meeting.end > currentDate
//    }
//
//    private var isPast: Bool {
//        meeting.end < currentDate
//    }
//
//    private var isStartingSoon: Bool {
//        let fiveMinutesLater = calendar.date(byAdding: .minute, value: 5, to: currentDate) ?? currentDate
//        return meeting.start > currentDate && meeting.start < fiveMinutesLater
//    }
//
//    private var backgroundColor: Color {
//        if isPast || (!isOngoing && !isStartingSoon) {
//            return .gray
//        } else if isStartingSoon {
//            return .green
//        } else {
//            return .blue
//        }
//    }
//
//    private var startingInText: String? {
//        if isStartingSoon {
//            let timeInterval = meeting.start.timeIntervalSince(currentDate)
//            let minutes = Int(timeInterval / 60)
//            let seconds = Int(timeInterval.truncatingRemainder(dividingBy: 60))
//            return "Starting in \(minutes):\(String(format: "%02d", seconds))"
//        }
//        return nil
//    }
//
//    private var pastText: String {
//        let dayFormatter = DateFormatter()
//        dayFormatter.dateFormat = "EEEE, MMMM d"
//        let dayString = calendar.isDate(meeting.start, inSameDayAs: currentDate) ? "" : "\(dayFormatter.string(from: meeting.start)) - "
//        return "\(dayString)Started \(timeRange(for: meeting))"
//    }
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            HStack {
//                ZStack {
//                    Circle()
//                        .fill(backgroundColor.opacity(0.2))
//                        .frame(width: 40, height: 40)
//                    Image(systemName: "phone.fill")
//                        .foregroundColor(.black)
//                }
//
//                VStack(alignment: .leading) {
//                    Text(meeting.title)
//                        .font(.headline)
//                    if let startingIn = startingInText {
//                        Text(startingIn)
//                            .font(.subheadline)
//                            .foregroundColor(.green)
//                    } else if isPast {
//                        Text(pastText)
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                    } else {
//                        Text(timeRange(for: meeting))
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                    }
//                }
//
//                Spacer()
//
//                if isOngoing {
//                    if meeting.isNew {
//                        Button("Join Channel") {
//                            // Action to join
//                        }
//                        .buttonStyle(.borderedProminent)
//                        .tint(.blue)
//                    } else {
//                        Text("Attending")
//                            .foregroundColor(.blue)
//                    }
//                }
//            }
//
//            if !meeting.participants.isEmpty {
//                HStack(spacing: -8) { // Overlapping avatars
//                    let displayed = meeting.participants.prefix(3)
//                    ForEach(displayed) { participant in
//                        ZStack {
//                            Circle()
//                                .fill(participant.color)
//                                .frame(width: 30, height: 30)
//                            Text(participant.initials)
//                                .foregroundColor(.white)
//                                .font(.caption)
//                        }
//                    }
//
//                    if meeting.participants.count > 3 {
//                        ZStack {
//                            Circle()
//                                .fill(Color.gray)
//                                .frame(width: 30, height: 30)
//                            Text("+\(meeting.participants.count - 3)")
//                                .foregroundColor(.white)
//                                .font(.caption)
//                        }
//                    }
//                }
//            }
//        }
//        .padding(.vertical, 4)
//    }
//
//    private func timeRange(for meeting: Meeting) -> String {
//        let formatter = DateFormatter()
//        formatter.timeStyle = .short
//        return "\(formatter.string(from: meeting.start)) - \(formatter.string(from: meeting.end))"
//    }
//
//    private func formatDay(_ date: Date) -> String {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "EEEE, MMMM d"
//        return formatter.string(from: date)
//    }
//
//}

struct MeetingRow2: View {
    let meeting: Meeting
    let currentDate: Date
    private let calendar = Calendar.current
    private var isOngoing: Bool {
        meeting.start <= currentDate && meeting.end > currentDate
    }

    private var isPast: Bool {
        meeting.end < currentDate
    }

    private var isStartingSoon: Bool {
        let fiveMinutesLater = calendar.date(byAdding: .minute, value: 5, to: currentDate) ?? currentDate
        return meeting.start > currentDate && meeting.start < fiveMinutesLater
    }

    private var backgroundColor: Color {
        if isPast || (!isOngoing && !isStartingSoon) {
            return .gray
        } else if isStartingSoon {
            return .green
        } else {
            return .blue
        }
    }

    private var startingInText: String? {
        if isStartingSoon {
            let timeInterval = meeting.start.timeIntervalSince(currentDate)
            let minutes = Int(timeInterval / 60)
            let seconds = Int(timeInterval.truncatingRemainder(dividingBy: 60))
            return "\(minutes):\(String(format: "%02d", seconds))"
        }
        return nil
    }

    private var remainingText: String? {
        if isOngoing {
            let timeInterval = meeting.end.timeIntervalSince(currentDate)
            let minutes = Int(timeInterval / 60)
            let seconds = Int(timeInterval.truncatingRemainder(dividingBy: 60))
            return "\(minutes):\(String(format: "%02d", seconds))"
        }
        return nil
    }

    private var pastText: String {
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE, MMMM d"
        let dayString = dayFormatter.string(from: meeting.start)
        let timeString = timeRange(for: meeting)
        return "\(dayString) - Started \(timeString)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .fill(backgroundColor.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: "phone.fill")
                        .foregroundColor(.black)
                }

                VStack(alignment: .leading) {
                    Text(meeting.title)
                        .font(.headline)
                    if let startingIn = startingInText {
                        Text("Starting in \(startingIn)")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    } else if isPast {
                        Text(pastText)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else if isOngoing {
                        let startStr = startTime(for: meeting)
                        if let remaining = remainingText {
                            Text("Started at \(startStr) - \(remaining)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text(timeRange(for: meeting))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text(timeRange(for: meeting))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if isOngoing {
                    if meeting.isNew {
                        Button("Join Channel") {
                            // Action to join
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                    } else {
                        Text("Attending")
                            .foregroundColor(.blue)
                    }
                }
            }

            if !meeting.participants.isEmpty {
                HStack(spacing: -8) { // Overlapping avatars
                    let maxAvatars = min(5, meeting.participants.count)
                    let displayed = Array(meeting.participants.prefix(maxAvatars))
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
                    if meeting.participants.count > 5 {
                        let remaining = meeting.participants.count - 5
                        ZStack {
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 30, height: 30)
                            Text("+\(remaining)")
                                .foregroundColor(.white)
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func timeRange(for meeting: Meeting) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: meeting.start)) - \(formatter.string(from: meeting.end))"
    }

    private func startTime(for meeting: Meeting) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: meeting.start)
    }

}

#Preview("Upcoming") {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm"
    let currentDate = formatter.date(from: "2025-10-14 16:00")!
    let meeting = Meeting(
        id: UUID(),
        title: "Candidate Interview: Charles Royale",
        start: formatter.date(from: "2025-10-14 17:00")!,
        end: formatter.date(from: "2025-10-14 17:15")!,
        participants: [
            Participant(initials: "AF"),
            Participant(initials: "WI"),
            Participant(initials: "JO"),
            Participant(initials: "BN"),
            Participant(initials: "FS"),
            Participant(initials: "GF"),
            Participant(initials: "KO")
        ]
    )
    return MeetingRow2(meeting: meeting, currentDate: currentDate)
}

#Preview("Starting Soon") {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm"
    let currentDate = formatter.date(from: "2025-10-14 16:00")!
    let meeting = Meeting(
        id: UUID(),
        title: "Candidate Interview: Charles Royale",
        start: formatter.date(from: "2025-10-14 16:03")!,
        end: formatter.date(from: "2025-10-14 16:18")!,
        participants: [Participant(initials: "AF"), Participant(initials: "WI")]
    )
    return MeetingRow2(meeting: meeting, currentDate: currentDate)
}

#Preview("Now (New)") {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm"
    let currentDate = formatter.date(from: "2025-10-14 16:00")!
    let meeting = Meeting(
        id: UUID(), title: "Candidate Interview: Charles Royale",
        start: formatter.date(from: "2025-10-14 15:50")!,
        end: formatter.date(from: "2025-10-14 16:15")!,
        isNew: true,
        participants: [Participant(initials: "JO")]
    )
    return MeetingRow2(meeting: meeting, currentDate: currentDate)
}

#Preview("Participating (Ongoing)") {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm"
    let currentDate = formatter.date(from: "2025-10-14 16:00")!
    let meeting = Meeting(
        id: UUID(),
        title: "Candidate Interview: Charles Royale",
        start: formatter.date(from: "2025-10-14 15:50")!,
        end: formatter.date(from: "2025-10-14 16:15")!,
        isNew: false,
        participants: [
            Participant(initials: "AF"),
            Participant(initials: "WI"),
            Participant(initials: "JO")
        ]
    )
    return MeetingRow2(meeting: meeting, currentDate: currentDate)
}

#Preview("Past") {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm"
    let currentDate = formatter.date(from: "2025-10-14 16:00")!
    let meeting = Meeting(
        id: UUID(),
        title: "Candidate Interview: Charles Royale",
        start: formatter.date(from: "2025-10-14 14:00")!,
        end: formatter.date(from: "2025-10-14 14:15")!,
        participants: Array(repeating: Participant(initials: "P"), count: 5))
    return MeetingRow2(meeting: meeting, currentDate: currentDate)
}
