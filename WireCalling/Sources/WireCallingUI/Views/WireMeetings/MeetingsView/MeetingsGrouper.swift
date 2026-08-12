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
package import WireCallingDomain

package typealias GroupedMeetings = [(day: Date, meetings: [MeetingOccurrence])]

package struct MeetingsGrouper {

    private let calendar = Calendar.current

    package init() {}

    package func group(
        _ meetings: [MeetingOccurrence]
    ) -> GroupedMeetings {
        let sortMeetings: ([MeetingOccurrence]) -> [MeetingOccurrence] = { meetings in
            meetings.sorted {
                if $0.start != $1.start {
                    $0.start < $1.start
                } else {
                    $0.title < $1.title
                }
            }
        }

        return Dictionary(grouping: meetings) { calendar.startOfDay(for: $0.start) }
            .map { (day: $0.key, meetings: sortMeetings($0.value)) }
            .sorted { $0.day < $1.day }
    }

}
