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

import Foundation

/// Parameters for creating a new meeting via `POST /meetings`.
public struct CreateMeetingParameters: Encodable, Sendable {

    public let title: String
    public let startTime: Date
    public let endTime: Date
    public let invitedEmails: [String]?
    public let recurrence: MeetingRecurrence?

    public init(
        title: String,
        startTime: Date,
        endTime: Date,
        invitedEmails: [String]? = nil,
        recurrence: MeetingRecurrence? = nil
    ) {
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.invitedEmails = invitedEmails
        self.recurrence = recurrence
    }

    enum CodingKeys: String, CodingKey {
        case title
        case startTime = "start_time"
        case endTime = "end_time"
        case invitedEmails = "invited_emails"
        case recurrence
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(ISO8601DateFormatter.internetDateTime.string(from: startTime), forKey: .startTime)
        try container.encode(ISO8601DateFormatter.internetDateTime.string(from: endTime), forKey: .endTime)
        try container.encodeIfPresent(invitedEmails, forKey: .invitedEmails)
        try container.encodeIfPresent(recurrence, forKey: .recurrence)
    }
}
