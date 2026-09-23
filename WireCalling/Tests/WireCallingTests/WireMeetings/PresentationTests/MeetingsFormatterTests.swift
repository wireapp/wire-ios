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

    var dayHeaderCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? calendar.timeZone
        return calendar
    }

    var timeRangeCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? calendar.timeZone
        return calendar
    }

    var formatter: MeetingsFormatter {
        MeetingsFormatter(
            calendar: dayHeaderCalendar,
            locale: Locale(identifier: "en_US")
        )
    }

    // MARK: - Day Header Tests

    @Test("dayHeader returns 'Today' for current date")
    func testDayHeaderForToday() throws {
        let now = try makeDayHeaderDate(hour: 9, minute: 0)
        let result = formatter.dayHeader(for: now, now: now)

        #expect(result == "Today (Tuesday, September 8)")
    }

    @Test("dayHeader returns 'Tomorrow' for the next date")
    func testDayHeaderForTomorrow() throws {
        let now = try makeDayHeaderDate(hour: 9, minute: 0)
        let tomorrow = try #require(dayHeaderCalendar.date(byAdding: .day, value: 1, to: now))
        let result = formatter.dayHeader(for: tomorrow, now: now)

        #expect(result == "Tomorrow (Wednesday, September 9)")
    }

    @Test("dayHeader uses weekday, month, and day for other days", arguments: [
        (2026, 9, 13, "Sunday, September 13"),
        (2026, 12, 31, "Thursday, December 31")
    ])
    func testDayHeaderForOtherDays(year: Int, month: Int, day: Int, expected: String) throws {
        let now = try makeDayHeaderDate(hour: 9, minute: 0)
        let date = try #require(dayHeaderCalendar.date(from: DateComponents(year: year, month: month, day: day)))

        #expect(formatter.dayHeader(for: date, now: now) == expected)
    }

    // MARK: - Time Range Tests

    @Test("timeRange respects 12-hour time settings")
    func timeRange_respectsTwelveHourTimeSettings() throws {
        let formatter = formatter(localeIdentifier: "en_US@hours=h12")
        let start = try makeTimeRangeDate(hour: 14, minute: 0)
        let end = try makeTimeRangeDate(hour: 15, minute: 15)
        let result = formatter.timeRange(from: start, to: end)

        #expect(result.contains("2:00"))
        #expect(result.contains("3:15"))
        #expect(result.contains("PM"))
        #expect(!result.contains("14:00"))
        #expect(!result.contains("15:15"))
    }

    @Test("timeRange respects 24-hour time settings")
    func timeRange_respectsTwentyFourHourTimeSettings() throws {
        let formatter = formatter(localeIdentifier: "en_GB")
        let start = try makeTimeRangeDate(hour: 7, minute: 5)
        let end = try makeTimeRangeDate(hour: 8, minute: 15)

        #expect(formatter.timeRange(from: start, to: end) == "07:05 - 08:15")
    }

    @Test("time uses localized short time settings")
    func time_usesLocalizedShortTimeSettings() throws {
        let formatter = formatter(localeIdentifier: "en_US@hours=h12")
        let date = try makeTimeRangeDate(hour: 14, minute: 5)
        let result = formatter.time(date)

        #expect(result.contains("2:05"))
        #expect(result.contains("PM"))
    }

    @Test("time pads 24-hour time settings")
    func time_padsTwentyFourHourTimeSettings() throws {
        let formatter = formatter(localeIdentifier: "en_GB")
        let date = try makeTimeRangeDate(hour: 7, minute: 5)

        #expect(formatter.time(date) == "07:05")
    }

    @Test("date uses localized short date settings", arguments: [
        ("en_US", "9/8/26"),
        ("en_GB", "08/09/2026"),
        ("de_DE", "08.09.26")
    ])
    func date_usesLocalizedShortDateSettings(localeIdentifier: String, expected: String) throws {
        let formatter = formatter(localeIdentifier: localeIdentifier)
        let date = try makeTimeRangeDate(hour: 14, minute: 5)

        #expect(formatter.date(date) == expected)
    }

    private func makeDayHeaderDate(hour: Int, minute: Int) throws -> Date {
        try #require(dayHeaderCalendar.date(
            from: DateComponents(year: 2026, month: 9, day: 8, hour: hour, minute: minute)
        ))
    }

    private func makeTimeRangeDate(hour: Int, minute: Int) throws -> Date {
        try #require(timeRangeCalendar.date(
            from: DateComponents(year: 2026, month: 9, day: 8, hour: hour, minute: minute)
        ))
    }

    private func formatter(localeIdentifier: String) -> MeetingsFormatter {
        MeetingsFormatter(
            calendar: timeRangeCalendar,
            locale: Locale(identifier: localeIdentifier)
        )
    }

}
