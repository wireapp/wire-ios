//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

public extension TimeInterval {

    static let fourWeeks = 4 * oneWeek
    static let oneWeek = 7 * oneDay
    static let oneDay = 24 * oneHour
    static let oneHour = 60 * oneMinute
    static let fiveMinutes = 5 * oneMinute
    static let oneMinute = 60 * oneSecond
    static let tenSeconds = 10 * oneSecond
    static let oneSecond = TimeInterval(1)

    /// Number of seconds for a whole year (accounting for leap years) from now.

    static var oneYearFromNow: Self {
        let now = Date()
        let oneYearFromNow = Calendar.current.date(byAdding: .year, value: 1, to: now)!
        return oneYearFromNow.timeIntervalSince(now)
    }

}
