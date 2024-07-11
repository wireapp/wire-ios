//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

public struct MessageAddBackupModel {

    public let nonce: UUID
    public let content: String
    public let conversationID: UUID
    public let senderUserID: UUID
    public let senderClientID: String?
    public let time: Date

    public init(
        nonce: UUID,
        content: String,
        conversationID: UUID,
        senderUserID: UUID,
        senderClientID: String?,
        time: Date
    ) {
        self.nonce = nonce
        self.content = content
        self.conversationID = conversationID
        self.senderUserID = senderUserID
        self.senderClientID = senderClientID
        self.time = time
    }

}

public enum EventBackupModel: Decodable {

    case messageAdd(MessageAddBackupModel)
    case unknown

    enum CodingKeys: String, CodingKey {

        case type
        case nonce = "id"
        case conversationID = "conversation"
        case senderUserID = "from"
        case senderClientID = "from_client_id"
        case time
        case data

    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "conversation.message-add":
            let nonce = try container.decode(UUID.self, forKey: .nonce)
            let conversationID = try container.decode(UUID.self, forKey: .conversationID)
            let senderUserID = try container.decode(UUID.self, forKey: .senderUserID)
            let senderClientID = try container.decodeIfPresent(String.self, forKey: .senderClientID)
            let time = try container.decode(Date.self, forKey: .time)
            let payload = try container.decode(MessageAddEventPayload.self, forKey: .data)

            let messageAddData = MessageAddBackupModel(
                nonce: nonce,
                content: payload.content,
                conversationID: conversationID,
                senderUserID: senderUserID,
                senderClientID: senderClientID,
                time: time
            )

            self = .messageAdd(messageAddData)

        default:
            self = .unknown
        }
    }

}

struct MessageAddEventPayload: Decodable {

    let content: String

}
