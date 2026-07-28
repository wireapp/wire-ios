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

package struct MeetingOccurrenceID: Hashable, Sendable {

    package let meetingID: QualifiedID
    package let start: Date

    package init(meetingID: QualifiedID, start: Date) {
        self.meetingID = meetingID
        self.start = start
    }

}

package struct MeetingOccurrence: Hashable, Identifiable, Sendable {

    package let id: MeetingOccurrenceID
    package let meeting: Meeting
    package let start: Date
    package let end: Date

    package init(meeting: Meeting, start: Date, end: Date) {
        self.id = MeetingOccurrenceID(meetingID: meeting.id, start: start)
        self.meeting = meeting
        self.start = start
        self.end = end
    }

    package init(meeting: Meeting) {
        self.init(meeting: meeting, start: meeting.start, end: meeting.end)
    }

    package var title: String {
        meeting.title
    }

    package var conversationID: QualifiedID {
        meeting.conversationID
    }

}
