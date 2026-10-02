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

import Foundation
import Testing
import WireFoundation

@testable import WireCallingDomain

@Suite("MeetingReminderOccurrenceCalculator Tests")
struct MeetingReminderOccurrenceCalculatorTests {

    @Test("keeps the local start time across daylight-saving time")
    func dailyRecurrenceAcrossDaylightSavingTime() {
        let first = date("2026-03-28T08:00:00Z") // 09:00 in Berlin
        let meeting = makeMeeting(
            start: first,
            recurrence: MeetingRecurrence(frequency: .daily, interval: 1)
        )

        let starts = MeetingReminderOccurrenceCalculator().starts(
            for: meeting,
            after: date("2026-03-28T07:00:00Z"),
            limit: 3
        )

        #expect(starts == [
            first,
            date("2026-03-29T07:00:00Z"), // 09:00 after the clock change
            date("2026-03-30T07:00:00Z")
        ])
    }

    @Test("skips an occurrence whose one-minute fire time has passed and keeps the limit")
    func skipsShortNoticeOccurrence() {
        let meeting = makeMeeting(
            start: date("2026-03-28T08:00:00Z"),
            recurrence: MeetingRecurrence(frequency: .daily, interval: 1)
        )

        let starts = MeetingReminderOccurrenceCalculator().starts(
            for: meeting,
            after: date("2026-03-28T07:59:30Z"),
            limit: 1
        )

        #expect(starts == [date("2026-03-29T07:00:00Z")]) // next day, 09:00 after the clock change
    }

    @Test("respects the recurrence end date")
    func stopsAtUntilDate() {
        let lastStart = date("2026-03-29T07:00:00Z")
        let meeting = makeMeeting(
            start: date("2026-03-28T08:00:00Z"),
            recurrence: MeetingRecurrence(frequency: .daily, interval: 1, until: lastStart)
        )

        let starts = MeetingReminderOccurrenceCalculator().starts(
            for: meeting,
            after: date("2026-03-28T07:00:00Z"),
            limit: 5
        )

        #expect(starts == [date("2026-03-28T08:00:00Z"), lastStart])
    }

    @Test("returns at most the requested number of future occurrences")
    func limitsRecurringOccurrences() {
        let meeting = makeMeeting(
            start: date("2026-03-28T08:00:00Z"),
            recurrence: MeetingRecurrence(frequency: .daily, interval: 1)
        )

        let starts = MeetingReminderOccurrenceCalculator().starts(
            for: meeting,
            after: date("2026-03-28T07:00:00Z"),
            limit: 5
        )

        #expect(starts.count == 5)
        #expect(starts.first == date("2026-03-28T08:00:00Z"))
        #expect(starts.last == date("2026-04-01T07:00:00Z"))
    }

    @Test("excludes a one-time meeting less than one minute away")
    func excludesShortNoticeMeeting() {
        let meeting = makeMeeting(start: date("2026-03-28T08:00:00Z"), recurrence: nil)

        let starts = MeetingReminderOccurrenceCalculator().starts(
            for: meeting,
            after: date("2026-03-28T07:59:30Z"),
            limit: 1
        )

        #expect(starts.isEmpty)
    }

    private func makeMeeting(start: Date, recurrence: MeetingRecurrence?) -> Meeting {
        Meeting(
            id: QualifiedID(id: UUID(), domain: "example.com"),
            title: "Team meeting",
            start: start,
            end: start.addingTimeInterval(3600),
            recurrence: recurrence,
            timeZoneIdentifier: "Europe/Berlin",
            conversationID: QualifiedID(id: UUID(), domain: "example.com"),
            creatorID: QualifiedID(id: UUID(), domain: "example.com")
        )
    }

    private func date(_ string: String) -> Date {
        ISO8601DateFormatter().date(from: string)!
    }

}
