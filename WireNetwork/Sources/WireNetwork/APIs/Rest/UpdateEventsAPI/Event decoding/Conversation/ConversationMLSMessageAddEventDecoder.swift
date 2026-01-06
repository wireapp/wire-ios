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

struct ConversationMLSMessageAddEventDecoder {

    func decode(
        from container: KeyedDecodingContainer<ConversationEventCodingKeys>
    ) throws -> ConversationMLSMessageAddEvent {
        let conversationID = try container.decode(
            QualifiedIDV0.self,
            forKey: .conversationQualifiedID
        )

        let senderID = try container.decode(
            QualifiedIDV0.self,
            forKey: .senderQualifiedID
        )

        let subconversation = try container.decodeIfPresent(
            String.self,
            forKey: .subconversation
        )

        let payload = try container.decode(
            String.self,
            forKey: .payload
        )

        let timestamp = try container.decodeIfPresent(
            UTCTime.self,
            forKey: .timestamp
        )

        return ConversationMLSMessageAddEvent(
            conversationID: conversationID.toAPIModel(),
            senderID: senderID.toAPIModel(),
            subconversation: subconversation,
            message: payload,
            timestamp: timestamp?.date,
            decryptedMessages: []
        )
    }

}
