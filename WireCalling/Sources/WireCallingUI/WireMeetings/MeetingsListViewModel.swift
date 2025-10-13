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

public import Foundation

//public final class MeetingsListViewModel: ObservableObject {
//
//    private typealias Strings = L10n.Localizable.WireMeetings.List.Tabs
//
//    @Published var allMeetings: [Meeting] = []
//    @Published var account: AccountUIViewModel
//    @Published var selectedTab: Tab = .next
//    @Published private(set) var ongoingSections: [MeetingDaySection] = []
//    @Published private(set) var upcomingSections: [MeetingDaySection] = []
//    @Published private(set) var pastSections: [MeetingDaySection] = []
//    @Published private(set) var shouldShowAll: Bool = false
//
//    var onShowAll: (() -> Void)?
//
//    private let calendar: Calendar
//    private let nowProvider: () -> Date
//
//    public init(
//        account: AccountUIViewModel,
//        calendar: Calendar = .current,
//        now: @escaping () -> Date = { Date() }
//    ) {
//        self.account = account
//        self.calendar = calendar
//        self.nowProvider = now
//        recompute()
//    }
//
//    public func updateAccount(_ account: AccountUIViewModel) {
//        self.account = account
//        recompute()
//    }
//
//    var hasMeetingsForSelectedTab: Bool {
//        switch selectedTab {
//        case .next: return upcomingSections.contains { !$0.timeGroups.isEmpty }
//        case .past: return pastSections.contains { !$0.timeGroups.isEmpty }
//        }
//    }
//
//    // MARK: - Recompute
//
//    private func recompute() {
//        let result = Self.computeSections(meetings: allMeetings)
//
//        upcomingSections = result.upcoming
//        pastSections = result.past
//        ongoingSections = result.ongoing
//    }
//
//    // MARK: - Actions
//
//    func meetNowTapped() {}
//    func scheduleMeetingTapped() {}
//    func onTapShowAll() { onShowAll?() }
//
//}
//
//extension MeetingsListViewModel {
//
//    typealias Sections = (
//        upcoming: [MeetingDaySection],
//        ongoing: [MeetingDaySection],
//        past: [MeetingDaySection]
//    )
//
//    static func computeSections(meetings: [Meeting]) -> Sections {
//        let now = Date()
//        let calendar = Calendar.current
//        let startOfToday = calendar.startOfDay(for: now)
//        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
//        let startOfDayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: startOfToday)!
//        let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday)!
//
//        func isSameDay(_ d1: Date, _ d2: Date) -> Bool { calendar.isDate(d1, inSameDayAs: d2) }
//
//        func dayHeader(for dayStart: Date, label: String) -> String {
//            "\(label) (\(DateFormatter.dayHeader.string(from: dayStart)))"
//        }
//
//        // Ongoing: meetings happening right now (today)
//        let ongoingItems = meetings
//            .filter { calendar.isDate($0.start, inSameDayAs: now) && $0.start <= now && now < $0.end }
//            .sorted { $0.start < $1.start }
//
//        let ongoingSection: [MeetingDaySection] = ongoingItems.isEmpty
//        ? []
//        : [MeetingDaySection(
//            title: "Ongoing",
//            timeGroups: [MeetingTimeGroup(timeLabel: "", items: ongoingItems)]
//        )]
//
//        // Upcoming: meetings starting later today or tomorrow
//        let upcomingItems = meetings
//            .filter { $0.start > now }
//            .filter { isSameDay($0.start, startOfToday) || isSameDay($0.start, startOfTomorrow) }
//            .sorted { $0.start < $1.start }
//
//        // Past: yesterday, and today’s that already ended
//        let pastItems = meetings
//            .filter { m in
//                if isSameDay(m.start, startOfYesterday) { return true }
//                if isSameDay(m.start, startOfToday) && m.end <= now { return true }
//                return false
//            }
//            .sorted { $0.start > $1.start } // most recent day first
//
//        func sectionizeByDay(_ items: [Meeting], ascendingDays: Bool) -> [MeetingDaySection] {
//            guard !items.isEmpty else { return [] }
//
//            // Group by day start (stable ordering)
//            let groupedByDay = Dictionary(grouping: items) { calendar.startOfDay(for: $0.start) }
//            let orderedDayKeys = groupedByDay.keys.sorted(by: { ascendingDays ? $0 < $1 : $0 > $1 })
//
//            return orderedDayKeys.map { dayStart in
//                let label: String =
//                isSameDay(dayStart, startOfToday) ? "Today" :
//                isSameDay(dayStart, startOfTomorrow) ? "Tomorrow" : "Yesterday"
//
//                let dayItems = (groupedByDay[dayStart] ?? []).sorted { $0.start < $1.start }
//                let groupedByTime = Dictionary(grouping: dayItems) { DateFormatter.timeHeader.string(from: $0.start) }
//
//                let orderedTimeKeys = groupedByTime.keys.sorted { lhs, rhs in
//                    if let d1 = DateFormatter.timeHeader.date(from: lhs),
//                       let d2 = DateFormatter.timeHeader.date(from: rhs) { return d1 < d2 }
//                    return lhs < rhs
//                }
//
//                let timeGroups = orderedTimeKeys.map { key in
//                    MeetingTimeGroup(timeLabel: key,
//                                     items: (groupedByTime[key] ?? []).sorted { $0.start < $1.start })
//                }
//
//                return MeetingDaySection(title: dayHeader(for: dayStart, label: label),
//                                         timeGroups: timeGroups)
//            }
//        }
//
//        let upcomingSections = sectionizeByDay(upcomingItems, ascendingDays: true)
//        let pastSections     = sectionizeByDay(pastItems,     ascendingDays: false)
//
//        let showAll = meetings.contains { $0.start >= startOfDayAfterTomorrow }
//
//        return (upcoming: upcomingSections,
//                ongoing: ongoingSection,
//                past: pastSections
//        )
//    }
//
//}
//
//extension MeetingsListViewModel {
//
//    enum Tab: Int, CaseIterable {
//        case next
//        case past
//
//        var title: String {
//            switch self {
//            case .next: Strings.next
//            case .past: Strings.past
//            }
//        }
//    }
//
//}
//
//// MARK: - Helpers
//
//private extension DateFormatter {
//
//    static let dayHeader: DateFormatter = {
//        let formatter = DateFormatter()
//        formatter.locale = .current
//        formatter.dateFormat = "EEEE, MMMM d"
//        return formatter
//    }()
//
//    static let timeHeader: DateFormatter = {
//        let formatter = DateFormatter()
//        formatter.locale = .current
//        formatter.dateFormat = "h:mm a"
//        return formatter
//    }()
//
//    static let weekdayFormatter: DateFormatter = {
//        let df = DateFormatter()
//        df.locale = .autoupdatingCurrent
//        df.setLocalizedDateFormatFromTemplate("EEEE")
//        return df
//    }()
//
//}


public final class MeetingsListViewModel: ObservableObject {
    enum Tab {
        case next
        case past
    }
    @Published var selectedTab: Tab = .next
    @Published var showAllNext: Bool = false
    @Published var account: AccountUIViewModel

    private let meetings: [Meeting]
    let currentDate: Date
    let calendar = Calendar.current

    init(meetings: [Meeting], account: AccountUIViewModel, currentDate: Date = Date()) {
        self.meetings = meetings.sorted { $0.start < $1.start }
        self.currentDate = currentDate
        self.account = account
    }

    public func updateAccount(_ account: AccountUIViewModel) {
        self.account = account
    }

    var ongoingMeetings: [Meeting] {
        meetings.filter { $0.start <= currentDate && $0.end > currentDate }
    }

    private var allFutureMeetings: [Meeting] {
        meetings.filter { $0.start > currentDate }
    }

    var displayedNextMeetings: [Meeting] {
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

    var hasMoreNext: Bool {
        !showAllNext && allFutureMeetings.count > displayedNextMeetings.count
    }

    var displayedPastMeetings: [Meeting] {
        let allPast = meetings.filter { $0.end <= currentDate }
        let todayStart = calendar.startOfDay(for: currentDate)
        guard let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart) else {
            return []
        }
        return allPast.filter { $0.end >= yesterdayStart }
    }

    func groupedMeetings(_ meetings: [Meeting], groupByTime: Bool = true) -> [(day: Date, timeSlots: [(time: Date, meetings: [Meeting])])] {
        let groupedByDay = Dictionary(grouping: meetings) { calendar.startOfDay(for: $0.start) }
            .map { (day: $0.key, meetings: $0.value.sorted { $0.start < $1.start }) }
            .sorted { $0.day > $1.day }

        if !groupByTime {
            return groupedByDay.map { (day: $0.day, timeSlots: [(time: $0.day, meetings: $0.meetings)]) }
        }

        return groupedByDay.map { dayGroup in
            let timeSlots = Dictionary(grouping: dayGroup.meetings) { date in
                calendar.date(bySettingHour: calendar.component(.hour, from: date.start), minute: 0, second: 0, of: date.start) ?? date.start
            }
                .map { (time: $0.key, meetings: $0.value.sorted { $0.start < $1.start }) }
                .sorted { $0.time < $1.time }
            return (day: dayGroup.day, timeSlots: timeSlots)
        }
    }

    var groupedOngoing: [(day: Date, timeSlots: [(time: Date, meetings: [Meeting])])] {
        groupedMeetings(ongoingMeetings, groupByTime: false)
    }

    var groupedNext: [(day: Date, timeSlots: [(time: Date, meetings: [Meeting])])] {
        groupedMeetings(displayedNextMeetings)
    }

    var groupedPast: [(day: Date, timeSlots: [(time: Date, meetings: [Meeting])])] {
        groupedMeetings(displayedPastMeetings)
    }

    func formatDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"

        if calendar.isDate(date, inSameDayAs: currentDate) {
            return "Today (\(formatter.string(from: date)))"
        } else if calendar.isDate(date, equalTo: calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate, toGranularity: .day) {
            return "Tomorrow (\(formatter.string(from: date)))"
        } else if calendar.isDate(date, equalTo: calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate, toGranularity: .day) {
            return "Yesterday (\(formatter.string(from: date)))"
        } else {
            formatter.dateFormat = "EEEE, MMMM d, yyyy"
            return formatter.string(from: date)
        }
    }

    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    func meetNowTapped() {}
    func scheduleMeetingTapped() {}

}
