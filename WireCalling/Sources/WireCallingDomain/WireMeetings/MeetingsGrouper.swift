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

import Foundation

package struct MeetingsGrouper {

    private let calendar = Calendar.current

    package init() {}

    package func group(
        _ meetings: [Meeting],
        byHours: Bool,
        sort: SortOrder
    ) -> GroupedMeetings {
        let sortMeetings: ([Meeting]) -> [Meeting] = { meetings in
            meetings.sorted {
                if $0.start != $1.start {
                    $0.start < $1.start
                } else {
                    $0.title < $1.title
                }
            }
        }

        let groupedByDay = Dictionary(grouping: meetings) { calendar.startOfDay(for: $0.start) }
            .map { (day: $0.key, meetings: sortMeetings($0.value)) }

        let sortedDays: [(day: Date, meetings: [Meeting])] = switch sort {
        case .ascending:  groupedByDay.sorted { $0.day < $1.day }
        case .descending: groupedByDay.sorted { $0.day > $1.day }
        }

        guard byHours else {
            return sortedDays.map { (day: $0.day, timeSlots: [(time: $0.day, meetings: $0.meetings)]) }
        }

        return sortedDays.map { dayGroup in
            let slots = Dictionary(grouping: dayGroup.meetings) { meeting in
                calendar.date(
                    bySettingHour: calendar.component(.hour, from: meeting.start),
                    minute: 0,
                    second: 0,
                    of: meeting.start
                ) ?? meeting.start
            }
            .map { (time: $0.key, meetings: sortMeetings($0.value)) }
            .sorted { $0.time < $1.time }

            return (day: dayGroup.day, timeSlots: slots)
        }
    }

    package enum SortOrder {
        case ascending
        case descending
    }

}
