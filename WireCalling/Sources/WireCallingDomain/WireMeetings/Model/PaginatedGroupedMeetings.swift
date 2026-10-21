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

package struct PaginatedMeetings {

    package let occurrences: [MeetingOccurrence]
    package let hasMore: Bool
    package let nextOffset: Int

    package var meetings: [Meeting] {
        occurrences.map(\.meeting)
    }

    package init(occurrences: [MeetingOccurrence], hasMore: Bool, nextOffset: Int) {
        self.occurrences = occurrences
        self.hasMore = hasMore
        self.nextOffset = nextOffset
    }

    package init(meetings: [Meeting], hasMore: Bool, nextOffset: Int) {
        self.init(
            occurrences: meetings.map { MeetingOccurrence(meeting: $0) },
            hasMore: hasMore,
            nextOffset: nextOffset
        )
    }

}
