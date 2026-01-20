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

    @Test("dayHeader returns 'Tomorrow' for next day")
    func testDayHeaderForTomorrow() {
        let now = Date()
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) else {
            Issue.record("Failed to create tomorrow date")
            return
        }

        let result = formatter.dayHeader(for: tomorrow, now: now)

        #expect(result.contains("Tomorrow"))
    }

    @Test("dayHeader returns 'Yesterday' for previous day")
    func testDayHeaderForYesterday() {
        let now = Date()
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now) else {
            Issue.record("Failed to create yesterday date")
            return
        }

        let result = formatter.dayHeader(for: yesterday, now: now)

        #expect(result.contains("Yesterday"))
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
        #expect(!result.contains("Tomorrow"))
        #expect(!result.contains("Yesterday"))
        #expect(!result.isEmpty)
    }

    // MARK: - Time Header Tests

    @Test("timeHeader returns formatted time")
    func testTimeHeaderFormat() {
        var components = DateComponents()
        components.year = 2025
        components.month = 1
        components.day = 15
        components.hour = 14
        components.minute = 30

        guard let date = calendar.date(from: components) else {
            Issue.record("Failed to create test date")
            return
        }

        let result = formatter.timeHeader(for: date)
        #expect(!result.isEmpty)
        #expect(result.contains(":"))
    }

}
