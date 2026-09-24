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
    func date(_ date: Date) -> String
    func time(_ date: Date) -> String
    func timeRange(from start: Date, to end: Date) -> String
}

package struct MeetingsFormatter: MeetingsFormatterProtocol {

    private typealias Strings = L10n.Localizable.WireMeetings.List

    private let calendarProvider: () -> Calendar
    private let localeProvider: () -> Locale

    package init() {
        self.init(
            calendarProvider: { .autoupdatingCurrent },
            localeProvider: { .autoupdatingCurrent }
        )
    }

    package init(calendar: Calendar, locale: Locale) {
        self.init(
            calendarProvider: { calendar },
            localeProvider: { locale }
        )
    }

    package init(
        calendarProvider: @escaping () -> Calendar,
        localeProvider: @escaping () -> Locale
    ) {
        self.calendarProvider = calendarProvider
        self.localeProvider = localeProvider
    }

    package func dayHeader(for date: Date, now: Date) -> String {
        let calendar = calendarProvider()
        let formattedDate = DateFormatter
            .meetingDayHeaderDate(locale: localeProvider(), calendar: calendar)
            .string(from: date)

        if calendar.isDate(date, inSameDayAs: now) {
            return Strings.Header.today + " (\(formattedDate))"
        } else if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
                  calendar.isDate(date, inSameDayAs: tomorrow) {
            return Strings.Header.tomorrow + " (\(formattedDate))"
        }

        return formattedDate
    }

    package func date(_ date: Date) -> String {
        DateFormatter
            .meetingDate(locale: localeProvider(), calendar: calendarProvider())
            .string(from: date)
    }

    package func time(_ date: Date) -> String {
        DateFormatter
            .meetingTime(locale: localeProvider(), calendar: calendarProvider())
            .string(from: date)
    }

    package func timeRange(from start: Date, to end: Date) -> String {
        "\(time(start)) - \(time(end))"
    }

}

// MARK: - Helpers

package extension DateFormatter {

    fileprivate static func meetingDayHeaderDate(locale: Locale, calendar: Calendar) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.setLocalizedDateFormatFromTemplate("EEEE MMMM d")
        return formatter
    }

    static func meetingDate(
        locale: Locale = .autoupdatingCurrent,
        calendar: Calendar = .autoupdatingCurrent
    ) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }

    static func meetingTime(
        locale: Locale = .autoupdatingCurrent,
        calendar: Calendar = .autoupdatingCurrent
    ) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }

}
