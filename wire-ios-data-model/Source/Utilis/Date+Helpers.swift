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

public extension Date {

    private static var customCalendar: Calendar = {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    /// The number of days from this date til now.
    ///
    /// If this date is in the future, the return value will be 0.

    var ageInDays: Int {
        let now = Date()
        return Self.customCalendar.dateComponents([.day], from: self, to: now).day!
    }

    /// Whether the date is after the current instant.

    var isInTheFuture: Bool {
        !isInThePast
    }

    /// Whether the date is before the current instant.

    var isInThePast: Bool {
        compare(Date()) != .orderedDescending
    }

}
