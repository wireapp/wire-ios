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
    /// Refreshes calendar- and locale-dependent formatting state.
    func refresh()
    func dayHeader(for date: Date, now: Date) -> String
    func date(_ date: Date) -> String
    func time(_ date: Date) -> String
    func timeRange(from start: Date, to end: Date) -> String
}

package final class MeetingsFormatter: MeetingsFormatterProtocol {

    private typealias Strings = L10n.Localizable.WireMeetings.List

    private let calendarProvider: () -> Calendar
    private let localeProvider: () -> Locale
    private var calendar: Calendar
    private var dayHeaderDateFormatter: DateFormatter
    private var dateFormatter: DateFormatter
    private var timeFormatter: DateFormatter

    package convenience init() {
        self.init(
            calendarProvider: { .autoupdatingCurrent },
            localeProvider: { .autoupdatingCurrent }
        )
    }

    package convenience init(calendar: Calendar, locale: Locale) {
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
        let calendar = calendarProvider()
        let locale = localeProvider()
        let formatters = Self.makeFormatters(locale: locale, calendar: calendar)
        self.calendar = calendar
        self.dayHeaderDateFormatter = formatters.dayHeaderDateFormatter
        self.dateFormatter = formatters.dateFormatter
        self.timeFormatter = formatters.timeFormatter
    }

    package func refresh() {
        let calendar = calendarProvider()
        let locale = localeProvider()
        let formatters = Self.makeFormatters(locale: locale, calendar: calendar)
        self.calendar = calendar
        dayHeaderDateFormatter = formatters.dayHeaderDateFormatter
        dateFormatter = formatters.dateFormatter
        timeFormatter = formatters.timeFormatter
    }

    package func dayHeader(for date: Date, now: Date) -> String {
        let formattedDate = dayHeaderDateFormatter.string(from: date)

        if calendar.isDate(date, inSameDayAs: now) {
            return Strings.Header.today + " (\(formattedDate))"
        } else if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
                  calendar.isDate(date, inSameDayAs: tomorrow) {
            return Strings.Header.tomorrow + " (\(formattedDate))"
        }

        return formattedDate
    }

    package func date(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }

    package func time(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }

    package func timeRange(from start: Date, to end: Date) -> String {
        "\(time(start)) - \(time(end))"
    }

    private static func makeFormatters(
        locale: Locale,
        calendar: Calendar
    ) -> (
        dayHeaderDateFormatter: DateFormatter,
        dateFormatter: DateFormatter,
        timeFormatter: DateFormatter
    ) {
        (
            dayHeaderDateFormatter: .meetingDayHeaderDate(locale: locale, calendar: calendar),
            dateFormatter: .meetingDate(locale: locale, calendar: calendar),
            timeFormatter: .meetingTime(locale: locale, calendar: calendar)
        )
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
