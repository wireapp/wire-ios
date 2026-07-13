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

}
