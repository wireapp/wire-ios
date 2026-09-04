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
import WireCallingUI

@Suite("MeetingsFormatter Tests")
struct MeetingsFormatterTests {

    let formatter = MeetingsFormatter()
    let calendar = Calendar.current

    // MARK: - Day Header Tests

    @Test("dayHeader returns 'Today' for current date")
    func testDayHeaderForToday() {
        let now = Date()
        let result = formatter.dayHeader(for: now, now: now)

        #expect(result.contains("Today"))
    }

    @Test("dayHeader returns formatted date for other days")
    func testDayHeaderForOtherDays() {
        let now = Date()
        guard let futureDate = calendar.date(byAdding: .day, value: 5, to: now) else {
            Issue.record("Failed to create future date")
            return
        }

        let result = formatter.dayHeader(for: futureDate, now: now)

        #expect(!result.contains("Today"))
        #expect(!result.isEmpty)
    }

    // MARK: - Time Range Tests

    @Test("timeRange places the period once for a morning range")
    func timeRange_sameMorningPeriod() throws {
        let start = try makeDate(hour: 7, minute: 30)
        let end = try makeDate(hour: 7, minute: 40)

        #expect(formatter.timeRange(from: start, to: end) == "07:30 - 07:40 AM")
    }

    @Test("timeRange places the period once for an afternoon range")
    func timeRange_sameAfternoonPeriod() throws {
        let start = try makeDate(hour: 14, minute: 0)
        let end = try makeDate(hour: 15, minute: 15)

        #expect(formatter.timeRange(from: start, to: end) == "02:00 - 03:15 PM")
    }

    @Test("timeRange places the period on both times when crossing from morning to afternoon")
    func timeRange_crossesPeriod() throws {
        let start = try makeDate(hour: 11, minute: 30)
        let end = try makeDate(hour: 13, minute: 15)

        #expect(formatter.timeRange(from: start, to: end) == "11:30 AM - 01:15 PM")
    }

    private func makeDate(hour: Int, minute: Int) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 15, hour: hour, minute: minute)))
    }

}
