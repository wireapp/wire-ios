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
    let calendar = Calendar(identifier: .gregorian)

    // MARK: - Day Header Tests

    @Test("dayHeader returns 'Today' for current date")
    func testDayHeaderForToday() throws {
        let now = try makeDate(hour: 9, minute: 0)
        let result = formatter.dayHeader(for: now, now: now)

        #expect(result == "Today (08.09.2026)")
    }

    @Test("dayHeader uses a numeric calendar date", arguments: [
        (2026, 9, 13, "13.09.2026"),
        (2026, 12, 31, "31.12.2026")
    ])
    func testDayHeaderForOtherDays(year: Int, month: Int, day: Int, expected: String) throws {
        let now = try makeDate(hour: 9, minute: 0)
        let date = try #require(calendar.date(from: DateComponents(year: year, month: month, day: day)))

        #expect(formatter.dayHeader(for: date, now: now) == expected)
    }

    // MARK: - Time Range Tests

    @Test("timeRange zero-pads morning hours without a period")
    func timeRange_sameMorningPeriod() throws {
        let start = try makeDate(hour: 7, minute: 30)
        let end = try makeDate(hour: 7, minute: 40)

        #expect(formatter.timeRange(from: start, to: end) == "07:30 - 07:40")
    }

    @Test("timeRange uses 24-hour afternoon hours")
    func timeRange_sameAfternoonPeriod() throws {
        let start = try makeDate(hour: 14, minute: 0)
        let end = try makeDate(hour: 15, minute: 15)

        #expect(formatter.timeRange(from: start, to: end) == "14:00 - 15:15")
    }

    @Test("timeRange uses the same format across noon")
    func timeRange_crossesPeriod() throws {
        let start = try makeDate(hour: 11, minute: 30)
        let end = try makeDate(hour: 13, minute: 15)

        #expect(formatter.timeRange(from: start, to: end) == "11:30 - 13:15")
    }

    @Test("timeRange formats midnight as zero and noon as twelve")
    func timeRange_midnightAndNoon() throws {
        let start = try makeDate(hour: 0, minute: 0)
        let end = try makeDate(hour: 12, minute: 0)

        #expect(formatter.timeRange(from: start, to: end) == "00:00 - 12:00")
    }

    private func makeDate(hour: Int, minute: Int) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: 2026, month: 9, day: 8, hour: hour, minute: minute)))
    }

}
