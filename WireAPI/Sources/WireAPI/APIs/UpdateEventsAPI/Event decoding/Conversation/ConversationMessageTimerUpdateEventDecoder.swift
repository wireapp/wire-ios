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

struct ConversationMessageTimerUpdateEventDecoder {
    // MARK: Internal

    func decode(
        from container: KeyedDecodingContainer<ConversationEventCodingKeys>
    ) throws -> ConversationMessageTimerUpdateEvent {
        let conversationID = try container.decode(
            ConversationID.self,
            forKey: .conversationQualifiedID
        )

        let senderID = try container.decode(
            UserID.self,
            forKey: .senderQualifiedID
        )

        let timestamp = try container.decode(
            UTCTimeMillis.self,
            forKey: .timestamp
        )

        let payload = try container.decode(
            Payload.self,
            forKey: .payload
        )

        return ConversationMessageTimerUpdateEvent(
            conversationID: conversationID,
            senderID: senderID,
            timestamp: timestamp.date,
            newTimer: payload.messageTimer
        )
    }

    // MARK: Private

    private struct Payload: Decodable {
        enum CodingKeys: String, CodingKey {
            case messageTimer = "message_timer"
        }

        let messageTimer: Int64?
    }
}
