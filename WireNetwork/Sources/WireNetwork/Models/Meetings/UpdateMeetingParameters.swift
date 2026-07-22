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

/// Parameters for updating a meeting via `PUT /meetings/{domain}/{id}`.
public struct UpdateMeetingParameters: Encodable, Sendable {

    public let title: String?
    public let startTime: Date?
    public let endTime: Date?
    public let recurrence: MeetingRecurrence?

    public init(
        title: String? = nil,
        startTime: Date? = nil,
        endTime: Date? = nil,
        recurrence: MeetingRecurrence? = nil
    ) {
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.recurrence = recurrence
    }

    enum CodingKeys: String, CodingKey {
        case title
        case startTime = "start_time"
        case endTime = "end_time"
        case recurrence
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(title, forKey: .title)
        if let startTime {
            try container.encode(ISO8601DateFormatter.internetDateTime.string(from: startTime), forKey: .startTime)
        }
        if let endTime {
            try container.encode(ISO8601DateFormatter.internetDateTime.string(from: endTime), forKey: .endTime)
        }
        // A `nil` recurrence is omitted rather than encoded as `null`:
        // the backend's Recurrence parser rejects explicit `null` with a
        // 400 bad-request (verified 2026-07-22).
        // TODO: clarify with the backend team how to turn a recurring
        // meeting into a one-off one: if an omitted field clears the
        // recurrence (PUT-as-full-replacement), this is already correct;
        // if it leaves it unchanged, clearing needs backend support.
        try container.encodeIfPresent(recurrence, forKey: .recurrence)
    }
}
