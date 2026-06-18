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

struct ConversationDescriptionUpdateEventDecoder {

    func decode(
        from container: KeyedDecodingContainer<ConversationEventCodingKeys>
    ) throws -> ConversationDescriptionUpdateEvent {
        let conversationID = try container.decode(
            QualifiedIDV0.self,
            forKey: .conversationQualifiedID
        )

        let senderID = try container.decode(
            QualifiedIDV0.self,
            forKey: .senderQualifiedID
        )

        let timestamp = try container.decode(
            UTCTime.self,
            forKey: .timestamp
        )

        let payload = try container.decode(
            Payload.self,
            forKey: .payload
        )

        return ConversationDescriptionUpdateEvent(
            conversationID: conversationID.toAPIModel(),
            senderID: senderID.toAPIModel(),
            timestamp: timestamp.date,
            version: payload.version,
            ciphertext: payload.ciphertext
        )
    }

    private struct Payload: Decodable {

        let version: Int
        let ciphertext: String
        

        enum CodingKeys: String, CodingKey {

            case version = "version"
            case ciphertext = "ciphertext"
            

        }
    }

}
