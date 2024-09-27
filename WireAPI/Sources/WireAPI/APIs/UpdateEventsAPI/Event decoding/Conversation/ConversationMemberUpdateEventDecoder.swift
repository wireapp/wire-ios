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

struct ConversationMemberUpdateEventDecoder {
    // MARK: Internal

    func decode(
        from container: KeyedDecodingContainer<ConversationEventCodingKeys>
    ) throws -> ConversationMemberUpdateEvent {
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

        return ConversationMemberUpdateEvent(
            conversationID: conversationID,
            senderID: senderID,
            timestamp: timestamp.date,
            memberChange: ConversationMemberChange(
                id: payload.userID,
                newRoleName: payload.role,
                newMuteStatus: payload.muteStatus,
                muteStatusReferenceDate: payload.muteStatusReference?.date,
                newArchivedStatus: payload.archivedStatus,
                archivedStatusReferenceDate: payload.archivedStatusReference?.date
            )
        )
    }

    // MARK: Private

    private struct Payload: Decodable {
        enum CodingKeys: String, CodingKey {
            case userID = "qualified_target"
            case role = "conversation_role"
            case muteStatus = "otr_muted_status"
            case muteStatusReference = "otr_muted_ref"
            case archivedStatus = "otr_archived"
            case archivedStatusReference = "otr_archived_ref"
        }

        let userID: UserID
        let role: String?
        let muteStatus: Int?
        let muteStatusReference: UTCTimeMillis?
        let archivedStatus: Bool?
        let archivedStatusReference: UTCTimeMillis?
    }
}
