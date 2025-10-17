//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import SwiftUI
package import WireCallingDomain

package struct MeetingState {
    private typealias Strings = L10n.Localizable.WireMeetings.MeetingDetails

    let meeting: Meeting
    let currentDate: Date
    private let calendar = Calendar.current

    package init(meeting: Meeting, currentDate: Date) {
        self.meeting = meeting
        self.currentDate = currentDate
    }

    var isOngoing: Bool {
        meeting.start <= currentDate && meeting.end > currentDate
    }

    var isPast: Bool {
        meeting.end < currentDate
    }

    var isStartingSoon: Bool {
        let fiveMinutesLater = calendar.date(byAdding: .minute, value: 5, to: currentDate) ?? currentDate
        return meeting.start > currentDate && meeting.start < fiveMinutesLater
    }

    var backgroundColor: Color {
        if isPast || (!isOngoing && !isStartingSoon) {
            .gray
        } else if isStartingSoon {
            .green
        } else {
            .blue
        }
    }

        var startingInText: String {
            if isStartingSoon {
                let timeInterval = meeting.start.timeIntervalSince(currentDate)
                let minutes = Int(timeInterval / 60)
                let seconds = Int(timeInterval.truncatingRemainder(dividingBy: 60))
                return "\(minutes):\(String(format: "%02d", seconds))"
            }
            return ""
        }

    //    var remainingText: String? {
    //        if isOngoing {
    //            let timeInterval = meeting.end.timeIntervalSince(currentDate)
    //            let minutes = Int(timeInterval / 60)
    //            let seconds = Int(timeInterval.truncatingRemainder(dividingBy: 60))
    //            return "\(minutes):\(String(format: "%02d", seconds))"
    //        }
    //        return nil
    //    }

    var dateText: String {
        if isStartingSoon {
            timeRangeText
        } else if isPast {
            pastDateText
        } else if isOngoing {
            ongoingDateText
        } else {
            timeRangeText
        }
    }

    private var pastDateText: String {
        let dayString = calendar
            .isDate(meeting.start, inSameDayAs: currentDate) ? "" :
            "\(DateFormatter.dayHeader.string(from: meeting.start)) • "
        return "\(dayString)\(Strings.started) \(startTime) • \(durationString)"
    }

    private var ongoingDateText: String {
        "\(Strings.startedAt) \(startTime) • \(durationString)"
    }

    private var timeRangeText: String {
        "\(startTime) - \(endTime)"
    }

    private var startTime: String {
        DateFormatter.timeHeader.string(from: meeting.start)
    }

    private var endTime: String {
        DateFormatter.timeHeader.string(from: meeting.end)
    }

    private var durationString: String {
        let durationSeconds = max(0, meeting.end.timeIntervalSince(meeting.start))
        let duration = DateComponentsFormatter()
        duration.allowedUnits = [.hour, .minute]
        duration.unitsStyle = .positional
        duration.zeroFormattingBehavior = [.pad]

        return duration.string(from: durationSeconds) ?? "0:00"
    }

}
