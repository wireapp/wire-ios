//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

    static let tenSeconds: Self = 10
    static let oneMinute: Self = 60
    static let fiveMinutes: Self = 300
    static let oneHour: Self = 3600
    static let oneDay: Self = 86400
    static let oneWeek: Self = 604800
    static let fourWeeks: Self = 2419200

    /// Number of seconds for a whole year (accounting for leap years) from now.

    static var oneYearFromNow: Self {
        let now = Date()
        let oneYearFromNow = Calendar.current.date(byAdding: .year, value: 1, to: now)!
        return oneYearFromNow.timeIntervalSince(now)
    }

}
