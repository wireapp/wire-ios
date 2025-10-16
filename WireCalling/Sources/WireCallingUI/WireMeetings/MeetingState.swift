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
package import WireCallingDomain
import SwiftUI

package struct MeetingState {

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
            return .gray
        } else if isStartingSoon {
            return .green
        } else {
            return .blue
        }
    }

    var startingInText: String? {
        if isStartingSoon {
            let timeInterval = meeting.start.timeIntervalSince(currentDate)
            let minutes = Int(timeInterval / 60)
            let seconds = Int(timeInterval.truncatingRemainder(dividingBy: 60))
            return "\(minutes):\(String(format: "%02d", seconds))"
        }
        return nil
    }

    var remainingText: String? {
        if isOngoing {
            let timeInterval = meeting.end.timeIntervalSince(currentDate)
            let minutes = Int(timeInterval / 60)
            let seconds = Int(timeInterval.truncatingRemainder(dividingBy: 60))
            return "\(minutes):\(String(format: "%02d", seconds))"
        }
        return nil
    }

    var pastText: String {
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE, MMMM d"
        let dayString = calendar.isDate(meeting.start, inSameDayAs: currentDate) ? "" : "\(dayFormatter.string(from: meeting.start)) - "
        let timeString = timeRange(for: meeting)
        return "\(dayString)Started \(timeString)"
    }

    func timeRange(for meeting: Meeting) -> String {
        return "\(DateFormatter.timeHeader.string(from: meeting.start))  -  \(DateFormatter.timeHeader.string(from: meeting.end))"
    }

    func startTime(for meeting: Meeting) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: meeting.start)
    }

}
