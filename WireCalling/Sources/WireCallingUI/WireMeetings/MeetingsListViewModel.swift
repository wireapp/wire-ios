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

package import Foundation
package import WireCallingDomain

package final class MeetingsListViewModel: ObservableObject {
    private typealias Strings = L10n.Localizable.WireMeetings.List

    @Published var selectedTab: Tab = .next
    @Published package var showAllNext: Bool = false

    private let meetings: [Meeting]
    package let currentDate: Date
    package let calendar = Calendar.current

    package init(meetings: [Meeting], currentDate: Date = Date()) {
        self.meetings = meetings.sorted { $0.start < $1.start }
        self.currentDate = currentDate
    }

    package var ongoingMeetings: [Meeting] {
        meetings.filter { $0.start <= currentDate && $0.end > currentDate }
    }

    private var allFutureMeetings: [Meeting] {
        meetings.filter { $0.start > currentDate }
    }

    package var displayedNextMeetings: [Meeting] {
        if showAllNext {
            return allFutureMeetings
        } else {
            let todayStart = calendar.startOfDay(for: currentDate)
            guard let tomorrowEnd = calendar.date(byAdding: .day, value: 2, to: todayStart) else {
                return []
            }
            return allFutureMeetings.filter { $0.start < tomorrowEnd }
        }
    }

    package var hasMoreNext: Bool {
        !showAllNext && allFutureMeetings.count > displayedNextMeetings.count
    }

    package var displayedPastMeetings: [Meeting] {
        let allPast = meetings.filter { $0.end <= currentDate }
        let todayStart = calendar.startOfDay(for: currentDate)
        guard let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart) else {
            return []
        }
        return allPast.filter { $0.end >= yesterdayStart }
    }

    func groupedMeetings(_ meetings: [Meeting], groupByTime: Bool = true, sortOrder: SortOrder = .none) -> [(
        day: Date,
        timeSlots: [(time: Date, meetings: [Meeting])]
    )] {
        let groupedByDay = Dictionary(grouping: meetings) { calendar.startOfDay(for: $0.start) }
            .map { (day: $0.key, meetings: $0.value.sorted { $0.start < $1.start }) }
        let sortedByDay: [(day: Date, meetings: [Meeting])] = switch sortOrder {
        case .ascending:
            groupedByDay.sorted { $0.day < $1.day }
        case .descending:
            groupedByDay.sorted { $0.day > $1.day }
        case .none:
            groupedByDay
        }

        if !groupByTime {
            return sortedByDay.map { (day: $0.day, timeSlots: [(time: $0.day, meetings: $0.meetings)]) }
        }

        return sortedByDay.map { dayGroup in
            let timeSlots = Dictionary(grouping: dayGroup.meetings) { date in
                calendar.date(
                    bySettingHour: calendar.component(.hour, from: date.start),
                    minute: 0,
                    second: 0,
                    of: date.start
                ) ?? date.start
            }
            .map { (time: $0.key, meetings: $0.value.sorted { $0.start < $1.start }) }
            .sorted { $0.time < $1.time }
            return (day: dayGroup.day, timeSlots: timeSlots)
        }
    }

    package var groupedOngoing: [(day: Date, timeSlots: [(time: Date, meetings: [Meeting])])] {
        groupedMeetings(ongoingMeetings, groupByTime: false, sortOrder: .none)
    }

    package var groupedNext: [(day: Date, timeSlots: [(time: Date, meetings: [Meeting])])] {
        groupedMeetings(displayedNextMeetings, sortOrder: .ascending)
    }

    package var groupedPast: [(day: Date, timeSlots: [(time: Date, meetings: [Meeting])])] {
        groupedMeetings(displayedPastMeetings, sortOrder: .descending)
    }

    package func formatDay(_ date: Date) -> String {
        if calendar.isDate(date, inSameDayAs: currentDate) {
            Strings.Header.today + " (\(DateFormatter.dayHeader.string(from: date)))"
        } else if calendar.isDate(
            date,
            equalTo: calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate,
            toGranularity: .day
        ) {
            Strings.Header.tomorrow + " (\(DateFormatter.dayHeader.string(from: date)))"
        } else if calendar.isDate(
            date,
            equalTo: calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate,
            toGranularity: .day
        ) {
            Strings.Header.yesterday + " (\(DateFormatter.dayHeader.string(from: date)))"
        } else {
            DateFormatter.dayHeader.string(from: date)
        }
    }

    func formatTime(_ date: Date) -> String {
        DateFormatter.timeHeader.string(from: date)
    }

    func meetNowTapped() {}
    func scheduleMeetingTapped() {}

}

// MARK: - Helpers

extension DateFormatter {

    static let dayHeader: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }()

    static let timeHeader: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

//    static let timeNoMeridiem: DateFormatter = {
//        let formatter = DateFormatter()
//        formatter.locale = .current
//        formatter.dateFormat = "h:mm"
//        return formatter
//    }()

}

extension MeetingsListViewModel {

    enum Tab: Int, CaseIterable {
        case next
        case past

        var title: String {
            switch self {
            case .next: Strings.Tabs.next
            case .past: Strings.Tabs.past
            }
        }
    }

    enum SortOrder {
        case none
        case ascending
        case descending
    }

}
