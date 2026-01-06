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

package protocol MeetingsFormatterProtocol {
    func dayHeader(for date: Date, now: Date) -> String
    func timeHeader(for date: Date) -> String
}

package struct MeetingsFormatter: MeetingsFormatterProtocol {

    private typealias Strings = L10n.Localizable.WireMeetings.List

    package init() {}

    package func dayHeader(for date: Date, now: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDate(date, inSameDayAs: now) {
            return Strings.Header.today + " (\(DateFormatter.dayHeader.string(from: date)))"
        } else if calendar.isDate(
            date,
            equalTo: calendar.date(byAdding: .day, value: 1, to: now) ?? now,
            toGranularity: .day
        ) {
            return Strings.Header.tomorrow + " (\(DateFormatter.dayHeader.string(from: date)))"
        } else if calendar.isDate(
            date,
            equalTo: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
            toGranularity: .day
        ) {
            return Strings.Header.yesterday + " (\(DateFormatter.dayHeader.string(from: date)))"
        } else {
            return DateFormatter.dayHeader.string(from: date)
        }
    }

    package func timeHeader(for date: Date) -> String {
        DateFormatter.timeHeader.string(from: date)
    }

}

// MARK: - Helpers

private extension DateFormatter {

    static let dayHeader: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }()

    static let timeHeader: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

}
