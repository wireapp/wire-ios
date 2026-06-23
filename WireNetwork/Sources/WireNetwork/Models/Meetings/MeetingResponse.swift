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

// MARK: - MeetingFrequency

public enum MeetingFrequency: String, Codable {
    case daily
    case weekly
    case monthly
    case yearly
}

// MARK: - MeetingRecurrence

public struct MeetingRecurrence: Encodable {

    public let frequency: MeetingFrequency
    public let interval: Int?
    public let until: Date?

    public init(frequency: MeetingFrequency, interval: Int? = nil, until: Date? = nil) {
        self.frequency = frequency
        self.interval = interval
        self.until = until
    }

    enum CodingKeys: String, CodingKey {
        case frequency
        case interval
        case until
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(frequency, forKey: .frequency)
        try container.encodeIfPresent(interval, forKey: .interval)
        if let until {
            try container.encode(ISO8601DateFormatter.internetDateTime.string(from: until), forKey: .until)
        }
    }
}

// MARK: - MeetingRecurrenceV0 (internal, for decoding)

struct MeetingRecurrenceV0: Decodable {

    let frequency: MeetingFrequency
    let interval: Int?
    let until: UTCTime?

    func toMeetingRecurrence() -> MeetingRecurrence {
        MeetingRecurrence(
            frequency: frequency,
            interval: interval,
            until: until?.date
        )
    }
}

// MARK: - MeetingResponse

public struct MeetingResponse {

    public let id: QualifiedID
    public let title: String
    public let creatorID: QualifiedID
    public let startTime: Date
    public let endTime: Date
    public let conversationID: QualifiedID
    public let invitedEmails: [String]
    public let isTrial: Bool
    public let createdAt: Date
    public let updatedAt: Date
    public let recurrence: MeetingRecurrence?

    public init(
        id: QualifiedID,
        title: String,
        creatorID: QualifiedID,
        startTime: Date,
        endTime: Date,
        conversationID: QualifiedID,
        invitedEmails: [String],
        isTrial: Bool,
        createdAt: Date,
        updatedAt: Date,
        recurrence: MeetingRecurrence? = nil
    ) {
        self.id = id
        self.title = title
        self.creatorID = creatorID
        self.startTime = startTime
        self.endTime = endTime
        self.conversationID = conversationID
        self.invitedEmails = invitedEmails
        self.isTrial = isTrial
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.recurrence = recurrence
    }
}

// MARK: - MeetingListResponseV0 (internal, for decoding an array response)

struct MeetingListResponseV0: Decodable, ToAPIModelConvertible {

    private let meetings: [MeetingResponseV0]

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        meetings = try container.decode([MeetingResponseV0].self)
    }

    func toAPIModel() -> [MeetingResponse] {
        meetings.map { $0.toAPIModel() }
    }
}

// MARK: - MeetingResponseV0 (internal, for decoding)

struct MeetingResponseV0: Decodable, ToAPIModelConvertible {

    let qualifiedID: QualifiedIDV0
    let title: String
    let qualifiedCreator: QualifiedIDV0
    let startTime: UTCTime
    let endTime: UTCTime
    let qualifiedConversation: QualifiedIDV0
    let invitedEmails: [String]
    let trial: Bool
    let createdAt: UTCTime
    let updatedAt: UTCTime
    let recurrence: MeetingRecurrenceV0?

    enum CodingKeys: String, CodingKey {
        case qualifiedID = "qualified_id"
        case title
        case qualifiedCreator = "qualified_creator"
        case startTime = "start_time"
        case endTime = "end_time"
        case qualifiedConversation = "qualified_conversation"
        case invitedEmails = "invited_emails"
        case trial
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case recurrence
    }

    func toAPIModel() -> MeetingResponse {
        MeetingResponse(
            id: qualifiedID.toAPIModel(),
            title: title,
            creatorID: qualifiedCreator.toAPIModel(),
            startTime: startTime.date,
            endTime: endTime.date,
            conversationID: qualifiedConversation.toAPIModel(),
            invitedEmails: invitedEmails,
            isTrial: trial,
            createdAt: createdAt.date,
            updatedAt: updatedAt.date,
            recurrence: recurrence?.toMeetingRecurrence()
        )
    }
}
