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

struct ConversationMLSMessageAddEventDecoder {
    // MARK: Internal

    func decode(
        from container: KeyedDecodingContainer<ConversationEventCodingKeys>
    ) throws -> ConversationMLSMessageAddEvent {
        let conversationID = try container.decode(
            ConversationID.self,
            forKey: .conversationQualifiedID
        )

        let senderID = try container.decode(
            UserID.self,
            forKey: .senderQualifiedID
        )

        let subconversation = try container.decodeIfPresent(
            String.self,
            forKey: .subconversation
        )

        let payload = try container.decode(
            Payload.self,
            forKey: .payload
        )

        return ConversationMLSMessageAddEvent(
            conversationID: conversationID,
            senderID: senderID,
            subconversation: subconversation,
            message: payload.text
        )
    }

    // MARK: Private

    private struct Payload: Decodable {
        let text: String
    }
}
