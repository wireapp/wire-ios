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
    func timeRange(from start: Date, to end: Date) -> String
}

package struct MeetingsFormatter: MeetingsFormatterProtocol {

    private typealias Strings = L10n.Localizable.WireMeetings.List

    package init() {}

    package func dayHeader(for date: Date, now: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDate(date, inSameDayAs: now) {
            return Strings.Header.today + " (\(DateFormatter.dayHeader.string(from: date)))"
        } else {
            return DateFormatter.dayHeader.string(from: date)
        }
    }

    package func timeRange(from start: Date, to end: Date) -> String {
        let calendar = Calendar.current
        let startPeriod = calendar.component(.hour, from: start) / 12
        let endPeriod = calendar.component(.hour, from: end) / 12
        let isSamePeriod = startPeriod == endPeriod
        let startFormatter = isSamePeriod ? DateFormatter.meetingTimeWithoutPeriod : DateFormatter.meetingTime
        let startString = startFormatter.string(from: start)
        let endString = DateFormatter.meetingTime.string(from: end)
        return "\(startString) - \(endString)"
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

}

private extension DateFormatter {

    static let meetingTimeWithoutPeriod: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "hh:mm"
        return formatter
    }()

    static let meetingTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "hh:mm a"
        return formatter
    }()

}
