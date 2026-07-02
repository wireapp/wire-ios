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

/// Represents a scheduled meeting.
///
/// A `Meeting` captures the essential information about a scheduled meeting,
/// including its unique identifier, title, and time range. Meetings can be
/// categorized as past, ongoing, or upcoming based on their start and end times
/// relative to the current time.

public struct Meeting: Equatable, Sendable {

    public let id: QualifiedID

    public let title: String

    public let start: Date

    public let end: Date

    public let recurrence: MeetingRecurrence?
    public let repeatOption: RepeatOption // TODO: delete

    public let members: [Member]

    public let conversationID: QualifiedID

    public init(
        id: QualifiedID,
        title: String,
        start: Date,
        end: Date,
        recurrence: MeetingRecurrence?,
        repeatOption: RepeatOption,
        members: [Member],
        conversationID: QualifiedID
    ) {
        self.id = id
        self.title = title
        self.start = start
        self.end = end
        self.repeatOption = repeatOption
        self.recurrence = recurrence
        self.members = members
        self.conversationID = conversationID
    }

}
