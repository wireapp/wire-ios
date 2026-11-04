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

public import Foundation

// Creating and configuring date formatters is insanely expensive.
// This is why there’s a bunch of statically configured ones here that are reused.
public enum WRDateFormatter {
    public static let NSTimeIntervalOneMinute = 60.0
    public static let NSTimeIntervalOneHour = 3600.0
    public static let DayMonthYearUnits: Set<Calendar.Component> = Set([.day, .month, .year])
    public static let WeekMonthYearUnits: Set<Calendar.Component> = Set([.weekOfMonth, .month, .year])

    /// The locale used by all formatters. Defaults to the current locale; only override it in tests.
    public private(set) nonisolated(unsafe) static var locale = Locale.current
    /// The calendar used by all formatters. Defaults to the current calendar; only override it in tests.
    public private(set) nonisolated(unsafe) static var calendar = Calendar.current
    /// The time zone used by all formatters. Defaults to the current time zone; only override it in tests.
    public private(set) nonisolated(unsafe) static var timeZone = TimeZone.current

    /// Makes every formatter use the given locale, calendar and time zone, e.g. to get reproducible output in tests.
    /// Call ``resetOverrides()`` to restore the defaults.
    public static func override(locale: Locale, calendar: Calendar, timeZone: TimeZone) {
        var calendar = calendar
        calendar.timeZone = timeZone
        self.locale = locale
        self.calendar = calendar
        self.timeZone = timeZone
        applyConfiguration()
    }

    /// Restores the current locale, calendar and time zone.
    public static func resetOverrides() {
        override(locale: .current, calendar: .current, timeZone: .current)
    }

    private static func applyConfiguration() {
        for formatter in [
            clockTimeFormatter,
            todayYesterdayFormatter,
            thisWeekFormatter,
            thisYearFormatter,
            otherYearFormatter
        ] {
            formatter.locale = locale
            formatter.calendar = calendar
            formatter.timeZone = timeZone
        }
        timeIntervalFormatter.locale = locale
        timeIntervalFormatter.calendar = calendar
        thisWeekFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "EEEE", options: 0, locale: locale) ?? ""
        thisYearFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "EEEEdMMMM", options: 0, locale: locale)
    }

    /// use this to format clock times, so they are correctly formatted to 12/24 hours according to locale
    public nonisolated(unsafe) static var clockTimeFormatter: DateFormatter = {
        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short

        return timeFormatter
    }()

    public nonisolated(unsafe) static var timeIntervalFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.dateTimeStyle = .named
        formatter.formattingContext = .beginningOfSentence
        return formatter
    }()

    public nonisolated(unsafe) static var todayYesterdayFormatter: DateFormatter = {
        let locale = Locale.current
        let timeFormatter = DateFormatter()
        timeFormatter.locale = locale
        timeFormatter.timeStyle = .short
        timeFormatter.doesRelativeDateFormatting = true

        return timeFormatter
    }()

    public nonisolated(unsafe) static var thisWeekFormatter: DateFormatter = {
        let locale = Locale.current
        let timeFormatter = DateFormatter()
        let formatString: String? = DateFormatter.dateFormat(fromTemplate: "EEEE", options: 0, locale: locale)
        timeFormatter.dateFormat = formatString ?? ""

        return timeFormatter
    }()

    public nonisolated(unsafe) static var thisYearFormatter: DateFormatter = {
        let locale = Locale.current
        let formatString = DateFormatter.dateFormat(fromTemplate: "EEEEdMMMM", options: 0, locale: locale)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = formatString

        return dateFormatter
    }()

    public nonisolated(unsafe) static var otherYearFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full

        return dateFormatter
    }()
}

public extension Date {
    var olderThanOneWeekdateFormatter: DateFormatter {
        olderThanOneWeekdateFormatter(now: Date())
    }

    private func olderThanOneWeekdateFormatter(now: Date) -> DateFormatter {
        let isThisYear = WRDateFormatter.calendar.isDate(self, equalTo: now, toGranularity: .year)

        if isThisYear {
            return WRDateFormatter.thisYearFormatter
        } else {
            return WRDateFormatter.otherYearFormatter
        }
    }

    /// Formats the date relative to now, e.g. "Just now", "Yesterday 10:30" or "Monday 10:30".
    /// - Parameters:
    ///   - justNowText: The localized text to use for dates less than a minute old.
    ///   - now: The reference date the receiver is compared against.
    func formattedDate(justNowText: String, now: Date = Date()) -> String {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = WRDateFormatter.timeZone
        // Today's date
        let today = now
        let todayDateComponents: DateComponents? = gregorian.dateComponents(
            WRDateFormatter.DayMonthYearUnits,
            from: today
        )
        // Yesterday
        var componentsToSubtract = DateComponents()
        componentsToSubtract.day = -1

        let yesterday = gregorian.date(byAdding: componentsToSubtract, to: today)
        let yesterdayComponents: DateComponents? = gregorian.dateComponents(
            WRDateFormatter.DayMonthYearUnits,
            from: yesterday!
        )
        // This week
        let thisWeekComponents: DateComponents? = gregorian.dateComponents(
            WRDateFormatter.WeekMonthYearUnits,
            from: today
        )
        // Received date
        let dateComponents: DateComponents? = gregorian.dateComponents(WRDateFormatter.DayMonthYearUnits, from: self)
        let weekComponents: DateComponents? = gregorian.dateComponents(WRDateFormatter.WeekMonthYearUnits, from: self)

        let intervalSinceDate: TimeInterval = now.timeIntervalSince(self)
        let isToday: Bool = todayDateComponents == dateComponents
        let isYesterday: Bool = yesterdayComponents == dateComponents
        let isThisWeek: Bool = thisWeekComponents == weekComponents
        var dateString = String()

        if intervalSinceDate < WRDateFormatter.NSTimeIntervalOneMinute {
            dateString = justNowText
        } else if intervalSinceDate < WRDateFormatter.NSTimeIntervalOneHour {
            // Date is within the last hour
            dateString = WRDateFormatter.timeIntervalFormatter.localizedString(for: self, relativeTo: now)
        } else if isToday || isYesterday {
            // Date is from today or yesterday
            let dateStyle: DateFormatter.Style = isToday ? .none : .medium
            WRDateFormatter.todayYesterdayFormatter.dateStyle = dateStyle
            dateString = WRDateFormatter.todayYesterdayFormatter.string(from: self)
        } else if isThisWeek {
            dateString =
                "\(WRDateFormatter.thisWeekFormatter.string(from: self)) \(WRDateFormatter.clockTimeFormatter.string(from: self))"
        } else {
            let dateFormatter = olderThanOneWeekdateFormatter(now: now)
            dateString = "\(dateFormatter.string(from: self)) \(WRDateFormatter.clockTimeFormatter.string(from: self))"
        }

        return dateString
    }
}
