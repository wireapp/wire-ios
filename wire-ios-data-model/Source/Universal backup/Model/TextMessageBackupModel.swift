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

    public let conversationID: QualifiedID

    public let senderUserID: QualifiedID

    public init(
        nonce: UUID,
        content: String,
        conversationID: QualifiedID,
        senderUserID: QualifiedID
    ) {
        self.nonce = nonce
        self.content = content
        self.conversationID = conversationID
        self.senderUserID = senderUserID
    }

}

public enum EventBackupModel: Decodable {

    case messageAdd(MessageAddBackupModel)
    case unknown

    enum CodingKeys: String, CodingKey {

        case type
        case conversationID = "qualified_conversation"
        case senderUserID = "qualified_from"
        case time
        case data

    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "conversation.meesage-add":
            let conversationID = try container.decode(QualifiedID.self, forKey: .conversationID)
            let senderUserID = try container.decode(QualifiedID.self, forKey: .senderUserID)
            let time = try container.decode(String.self, forKey: .time)
            let payload = try container.decode(MessageAddEventPayload.self, forKey: .data)

            let messageAddData = MessageAddBackupModel(
                nonce: UUID(),
                content: payload.content,
                conversationID: conversationID,
                senderUserID: senderUserID
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
