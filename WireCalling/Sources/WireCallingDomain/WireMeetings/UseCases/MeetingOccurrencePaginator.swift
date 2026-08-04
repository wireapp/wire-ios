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

package import Foundation

import WireFoundation

package struct MeetingOccurrencePaginator {

    private let calendar: Calendar

    package init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    package func occurrences(
        for meetings: [Meeting],
        startingAt lowerBound: Date,
        offset: Int,
        limit: Int
    ) -> [MeetingOccurrence] {
        guard limit > 0 else { return [] }

        var cursors = meetings.compactMap {
            makeCursor(for: $0, startingAt: lowerBound)
        }
        let offset = max(offset, 0)
        var skippedCount = 0
        var occurrences = [MeetingOccurrence]()

        while !cursors.isEmpty, occurrences.count < limit {
            cursors.sort(by: sort)

            var cursor = cursors.removeFirst()
            if skippedCount < offset {
                skippedCount += 1
            } else {
                occurrences.append(cursor.occurrence)
            }

            if cursor.advance(using: calendar) {
                cursors.append(cursor)
            }
        }

        return occurrences
    }

    private func makeCursor(for meeting: Meeting, startingAt lowerBound: Date) -> OccurrenceCursor? {
        guard let recurrence = meeting.recurrence else {
            guard meeting.start >= lowerBound else { return nil }
            return OccurrenceCursor(meeting: meeting, occurrenceStart: meeting.start)
        }

        guard recurrence.until.map({ $0 >= lowerBound }) ?? true else {
            return nil
        }

        var occurrenceStart = fastForwardOccurrenceStart(
            from: meeting.start,
            recurrence: recurrence,
            lowerBound: lowerBound
        )
        while occurrenceStart < lowerBound {
            guard let nextStart = nextOccurrenceStart(after: occurrenceStart, recurrence: recurrence),
                  nextStart > occurrenceStart else {
                return nil
            }

            guard recurrence.until.map({ nextStart <= $0 }) ?? true else {
                return nil
            }

            occurrenceStart = nextStart
        }

        guard recurrence.until.map({ occurrenceStart <= $0 }) ?? true else {
            return nil
        }

        return OccurrenceCursor(meeting: meeting, occurrenceStart: occurrenceStart)
    }

    private func fastForwardOccurrenceStart(
        from start: Date,
        recurrence: MeetingRecurrence,
        lowerBound: Date
    ) -> Date {
        guard start < lowerBound else { return start }

        // Daily and weekly recurrences can jump close to the requested lower bound by whole
        // intervals. `makeCursor` still performs the final one-by-one advancement so edge
        // cases around time-of-day and DST keep matching repeated Calendar additions.
        //
        // Monthly and yearly recurrences intentionally stay on the step-by-step path because
        // adding several months or years at once can differ from repeated additions for
        // end-of-month and leap-day start dates.
        let interval = max(recurrence.interval, 1)
        let elapsedDays = max(calendar.dateComponents([.day], from: start, to: lowerBound).day ?? 0, 0)
        let intervalsToSkip: Int
        let component: Calendar.Component

        switch recurrence.frequency {
        case .daily:
            intervalsToSkip = elapsedDays / interval
            component = .day
        case .weekly:
            intervalsToSkip = (elapsedDays / 7) / interval
            component = .weekOfYear
        case .monthly, .yearly:
            return start
        }

        guard intervalsToSkip > 0 else { return start }

        return calendar.date(
            byAdding: component,
            value: intervalsToSkip * interval,
            to: start
        ) ?? start
    }

    private func sort(_ lhs: OccurrenceCursor, _ rhs: OccurrenceCursor) -> Bool {
        if lhs.occurrenceStart != rhs.occurrenceStart {
            lhs.occurrenceStart < rhs.occurrenceStart
        } else if lhs.meeting.title != rhs.meeting.title {
            lhs.meeting.title < rhs.meeting.title
        } else if lhs.meeting.id.domain != rhs.meeting.id.domain {
            lhs.meeting.id.domain < rhs.meeting.id.domain
        } else {
            lhs.meeting.id.id.uuidString < rhs.meeting.id.id.uuidString
        }
    }

    private func nextOccurrenceStart(after date: Date, recurrence: MeetingRecurrence) -> Date? {
        let interval = max(recurrence.interval, 1)
        let component: Calendar.Component = switch recurrence.frequency {
        case .daily: .day
        case .weekly: .weekOfYear
        case .monthly: .month
        case .yearly: .year
        }

        return calendar.date(byAdding: component, value: interval, to: date)
    }

}

private struct OccurrenceCursor {

    let meeting: Meeting
    var occurrenceStart: Date

    var occurrence: MeetingOccurrence {
        MeetingOccurrence(
            meeting: meeting,
            start: occurrenceStart,
            end: occurrenceStart.addingTimeInterval(meeting.end.timeIntervalSince(meeting.start))
        )
    }

    mutating func advance(using calendar: Calendar) -> Bool {
        guard let recurrence = meeting.recurrence else { return false }

        let interval = max(recurrence.interval, 1)
        let component: Calendar.Component = switch recurrence.frequency {
        case .daily: .day
        case .weekly: .weekOfYear
        case .monthly: .month
        case .yearly: .year
        }

        guard let nextStart = calendar.date(byAdding: component, value: interval, to: occurrenceStart),
              nextStart > occurrenceStart else {
            return false
        }

        guard recurrence.until.map({ nextStart <= $0 }) ?? true else {
            return false
        }

        occurrenceStart = nextStart
        return true
    }

}
