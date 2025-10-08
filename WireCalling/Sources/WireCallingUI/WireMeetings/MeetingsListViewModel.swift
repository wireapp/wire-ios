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

public final class MeetingsListViewModel: ObservableObject {

    private typealias Strings = L10n.Localizable.WireMeetings.List.Tabs

    enum Tab: Int, CaseIterable {
        case next
        case past

        var title: String {
            switch self {
            case .next: Strings.next
            case .past: Strings.past
            }
        }
    }

    // Inputs
    @Published private var allMeetings: [Meeting] = []
    @Published var account: AccountUIViewModel

    // Outputs
    @Published var selectedTab: Tab = .next
    @Published private(set) var upcomingDaySections: [MeetingDaySection] = []
    @Published private(set) var pastDaySections: [MeetingDaySection] = []
    @Published private(set) var shouldShowAllOnUpcoming: Bool = false

    var onShowAll: (() -> Void)?

    private let calendar: Calendar
    private let nowProvider: () -> Date

    public init(
        account: AccountUIViewModel,
        calendar: Calendar = .current,
        now: @escaping () -> Date = { Date() }
    ) {
        self.account = account
        self.calendar = calendar
        self.nowProvider = now
        recompute()
    }

    public func updateAccount(_ account: AccountUIViewModel) {
        self.account = account
        recompute()
    }

    // Used by your view to show/hide empty state
    var hasMeetingsForSelectedTab: Bool {
            switch selectedTab {
            case .next: return upcomingDaySections.contains { !$0.timeGroups.isEmpty }
            case .past:     return pastDaySections.contains { !$0.timeGroups.isEmpty }
            }
        }

    // MARK: - Compute sections

    private func recompute() {
            let now = nowProvider()
            let startOfToday = calendar.startOfDay(for: now)
            let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
            let startOfDayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: startOfToday)!
            let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday)!

            func isSameDay(_ d1: Date, _ d2: Date) -> Bool { calendar.isDate(d1, inSameDayAs: d2) }
            func dayHeader(for dayStart: Date, label: String) -> String {
                let df = DateFormatter()
                df.locale = .autoupdatingCurrent
                df.dateFormat = "EEEE, MMM d"
                return "\(label) (\(df.string(from: dayStart)))"
            }
            let timeFmt: DateFormatter = {
                let df = DateFormatter()
                df.locale = .autoupdatingCurrent
                df.dateFormat = "h:mm a"
                return df
            }()

            // UPCOMING: only meetings that haven't ended yet, in Today + Tomorrow
            let upcoming = allMeetings
                .filter { $0.end >= now }
                .filter { isSameDay($0.start, startOfToday) || isSameDay($0.start, startOfTomorrow) }
                .sorted { $0.start < $1.start }

            // PAST: yesterday + earlier today that already ended
            let past = allMeetings
                .filter { m in
                    if isSameDay(m.start, startOfYesterday) { return true }
                    if isSameDay(m.start, startOfToday) && m.end < now { return true }
                    return false
                }
                .sorted { $0.start > $1.start } // recent first at top days

            // Group → Day → Time
            func sectionize(_ items: [Meeting], orderAscending: Bool) -> [MeetingDaySection] {
                guard !items.isEmpty else { return [] }

                // 1) group by day (Today/Tomorrow/Yesterday labels)
                let dayGroups = Dictionary(grouping: items) { (m: Meeting) -> String in
                    if isSameDay(m.start, startOfToday)    { return dayHeader(for: startOfToday, label: "Today") }
                    if isSameDay(m.start, startOfTomorrow) { return dayHeader(for: startOfTomorrow, label: "Tomorrow") }
                    return dayHeader(for: startOfYesterday, label: "Yesterday")
                }

                // stable order of days
                let orderedDayKeys = dayGroups.keys.sorted(by: { orderAscending ? $0 < $1 : $0 > $1 })

                // 2) within each day, group by *start time label*
                return orderedDayKeys.map { dayKey in
                    let dayItems = dayGroups[dayKey]!.sorted { $0.start < $1.start }
                    let timeGroupsDict = Dictionary(grouping: dayItems) { (m: Meeting) -> String in
                        timeFmt.string(from: m.start) // "7:00 AM"
                    }
                    // order time ascending in both tabs for readability
                    let orderedTimeKeys = timeGroupsDict.keys.sorted { (lhs, rhs) in
                        // Parse back to dates for correct ordering (keeps locale formats safe)
                        // Create artificial dates on same day:
                        if
                            let d1 = timeFmt.date(from: lhs),
                            let d2 = timeFmt.date(from: rhs)
                        { return d1 < d2 }
                        return lhs < rhs
                    }
                    let groups = orderedTimeKeys.map { tKey -> MeetingTimeGroup in
                        MeetingTimeGroup(timeLabel: tKey, items: timeGroupsDict[tKey]!.sorted { $0.start < $1.start })
                    }
                    return MeetingDaySection(title: dayKey, timeGroups: groups)
                }
            }

            upcomingDaySections = sectionize(upcoming, orderAscending: true)
            pastDaySections     = sectionize(past,     orderAscending: false)

            // "Show all" if anything is after tomorrow
            //shouldShowAllOnUpcoming = allMeetings.contains { $0.start >= startOfDayAfterTomorrow }
        }

    // MARK: - Actions

    func meetNowTapped() {}
    func scheduleMeetingTapped() {}
    func onTapShowAll() { onShowAll?() }

}

// MARK: - Mock data for previews/tests

//public extension MeetingsListViewModel {
//    static func demo1() -> MeetingsListViewModel {
//        let account = AccountUIViewModel(avatarSource: .text("JJ"), availability: .available, action: {})
//        let vm = MeetingsListViewModel(account: account)
//        let cal = Calendar.current
//        let now = Date()
//        func on(_ dayOffset: Int, hour: Int, minute: Int = 0, durationMins: Int = 45, title: String) -> Meeting {
//            let start = cal.date(bySettingHour: hour, minute: minute, second: 0, of: cal.date(byAdding: .day, value: dayOffset, to: cal.startOfDay(for: now))!)!
//            let end = start.addingTimeInterval(TimeInterval(durationMins * 60))
//            return Meeting(
//                id: UUID(),
//                title: title,
//                start: start,
//                end: end,
//                team: "Marketing team"
//            )
//        }
//        vm.allMeetings = [
//            on(0, hour: 7, title: "Candidate interview: Charles Royale"),
//            on(0, hour: 7, title: "Standup"),
//            on(0, hour: 10, title: "Design review"),
//            on(1, hour: 9, title: "Sprint planning"),
//            on(1, hour: 13, title: "Partner sync"),
//            on(3, hour: 11, title: "Quarterly all-hands") // > tomorrow → triggers "Show all"
//        ]
//        return vm
//    }
//}

public extension MeetingsListViewModel {
    static func demo() -> MeetingsListViewModel {
        let cal = Calendar.current
        let now = Date()
        func day(_ offset: Int, hour: Int, min: Int = 0) -> Date {
            cal.date(bySettingHour: hour, minute: min, second: 0,
                     of: cal.date(byAdding: .day, value: offset, to: cal.startOfDay(for: now))!)!
        }
        let meetings: [Meeting] = [
            // TODAY — several at 7:00 AM for time grouping
            Meeting(
                id: UUID(),
                title: "Candidate interview: Charles Royale",
                start: day(0, hour: 7, min: 0),
                end: day(0, hour: 7, min: 15),
                team: "Design"
            ),
            Meeting(
                id: UUID(),
                title: "Standup",
                start: day(0, hour: 7, min: 0),
                end: day(0, hour: 7, min: 30),
                team: "Design"
            ),
            Meeting(
                id: UUID(),
                title: "Marketing team update",
                start: day(0, hour: 7, min: 0),
                end: day(0, hour: 7, min: 20),
                team: "Marketing team"
            ),

            // A later time bucket
            Meeting(
                id: UUID(),
                title: "Design review",
                start: day(0, hour: 10),
                end: day(0, hour: 11),
                team: "Design"
            ),

            // TOMORROW — again two meetings at 7:00 AM to group
            Meeting(
                id: UUID(),
                title: "Sprint planning",
                start: day(1, hour: 7),
                end: day(1, hour: 8),
                team: "Design"
            ),
            Meeting(
                id: UUID(),
                title: "Daily sync",
                start: day(1, hour: 7),
                end: day(1, hour: 7, min: 20),
                team: "Design"
            ),
            Meeting(
                id: UUID(),
                title: "Partner sync",
                start: day(1, hour: 13),
                end: day(1, hour: 14),
                team: "Design"
            ),

            // AFTER TOMORROW — ensures "Show All" appears in the Next tab
            Meeting(
                id: UUID(),
                title: "Quarterly all-hands",
                start: day(3, hour: 11),
                end: day(3, hour: 12),
                team: "Design")
        ]

        let account = AccountUIViewModel(avatarSource: .text("JJ"), availability: .available, action: {})
        let vm = MeetingsListViewModel(account: account)
        vm.allMeetings = meetings
        return vm
    }
}

struct Meeting: Identifiable, Hashable {
    let id: UUID
    let title: String
    let start: Date
    let end: Date
    var team: String
}


// Time bucket within a single day
struct MeetingTimeGroup: Identifiable, Equatable {
    let id = UUID()
    let timeLabel: String     // e.g. "7:00 AM"
    let items: [Meeting]
}

// Day section containing time groups
struct MeetingDaySection: Identifiable, Equatable {
    let id = UUID()
    let title: String         // e.g. "Today (Tuesday, Jun 3)"
    let timeGroups: [MeetingTimeGroup]
}
