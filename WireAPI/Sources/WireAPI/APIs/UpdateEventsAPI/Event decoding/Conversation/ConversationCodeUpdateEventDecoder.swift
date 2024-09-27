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

struct ConversationCodeUpdateEventDecoder {
    // MARK: Internal

    func decode(
        from container: KeyedDecodingContainer<ConversationEventCodingKeys>
    ) throws -> ConversationCodeUpdateEvent {
        let conversationID = try container.decode(
            ConversationID.self,
            forKey: .conversationQualifiedID
        )

        let senderID = try container.decode(
            UserID.self,
            forKey: .senderQualifiedID
        )

        let payload = try container.decode(
            Payload.self,
            forKey: .payload
        )

        return ConversationCodeUpdateEvent(
            conversationID: conversationID,
            senderID: senderID,
            uri: payload.uri,
            key: payload.key,
            code: payload.code,
            isPasswordProtected: payload.hasPassword ?? false
        )
    }

    // MARK: Private

    private struct Payload: Decodable {
        enum CodingKeys: String, CodingKey {
            case uri
            case key
            case code
            case hasPassword = "has_password"
        }

        let uri: String?
        let key: String
        let code: String
        let hasPassword: Bool?
    }
}
