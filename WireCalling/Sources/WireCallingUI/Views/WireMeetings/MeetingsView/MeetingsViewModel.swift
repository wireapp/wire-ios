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

package final class MeetingsViewModel: ObservableObject {
    private typealias Strings = L10n.Localizable.WireMeetings.List

    @Published var selectedTab: Tab = .next
    @Published var showAllNext: Bool = false

    private let repository: any MeetingsRepositoryProtocol
    private let grouper: MeetingsGrouper
    private let formatter: MeetingsFormatter
    private let currentDate: Date
    private let calendar = Calendar.current

    package init(
        repository: any MeetingsRepositoryProtocol,
        currentDate: Date = Date(),
        grouper: MeetingsGrouper = MeetingsGrouper(),
        formatter: MeetingsFormatter = MeetingsFormatter()
    ) {
        self.repository = repository
        self.currentDate = currentDate
        self.grouper = grouper
        self.formatter = formatter
    }

    package var ongoingMeetings: [Meeting] {
        repository.ongoingMeetings(at: currentDate)
    }

    private var allFutureMeetings: [Meeting] {
        repository.futureMeetings(after: currentDate)
    }

    /// Next meetings to show in the UI: only today + tomorrow
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

    /// Past meetings to show in the UI: only today + yesterday
    package var displayedPastMeetings: [Meeting] {
        let allPast = repository.pastMeetings(until: currentDate)
        let todayStart = calendar.startOfDay(for: currentDate)
        guard let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart) else {
            return []
        }
        return allPast.filter { $0.end >= yesterdayStart }
    }

    package var hasMoreNext: Bool {
        !showAllNext && allFutureMeetings.count > displayedNextMeetings.count
    }

    package var groupedOngoing: [(day: Date, timeSlots: [(time: Date, meetings: [Meeting])])] {
        grouper.group(ongoingMeetings, byHours: false, calendar: calendar, sort: .none)
    }

    package var groupedNext: [(day: Date, timeSlots: [(time: Date, meetings: [Meeting])])] {
        grouper.group(displayedNextMeetings, byHours: true, calendar: calendar, sort: .ascending)
    }

    package var groupedPast: [(day: Date, timeSlots: [(time: Date, meetings: [Meeting])])] {
        grouper.group(displayedPastMeetings, byHours: true, calendar: calendar, sort: .descending)
    }

    package func formatDay(_ date: Date) -> String {
        formatter.dayHeader(for: date, now: currentDate)
    }

    func formatTime(_ date: Date) -> String {
        formatter.timeHeader(for: date)
    }

    func meetNowTapped() {}
    func scheduleMeetingTapped() {}

}

package extension MeetingsViewModel {

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
