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

struct ConversationCreateEventDecoder {
    // MARK: Internal

    struct Member: Decodable, ToAPIModelConvertible {
        enum CodingKeys: String, CodingKey {
            case qualifiedID = "qualified_id"
            case id
            case qualifiedTarget = "qualified_target"
            case target
            case conversationRole = "conversation_role"
            case service
            case archived = "otr_archived"
            case archivedReference = "otr_archived_ref"
            case hidden = "otr_hidden"
            case hiddenReference = "otr_hidden_ref"
            case mutedStatus = "otr_muted_status"
            case mutedReference = "otr_muted_ref"
        }

        let qualifiedID: QualifiedID?
        let id: UUID?
        let qualifiedTarget: QualifiedID?
        let target: UUID?
        let conversationRole: String?
        let service: Service?
        let archived: Bool?
        let archivedReference: UTCTimeMillis?
        let hidden: Bool?
        let hiddenReference: String?
        let mutedStatus: Int?
        let mutedReference: UTCTimeMillis?

        func toAPIModel() -> Conversation.Member {
            Conversation.Member(
                qualifiedID: qualifiedID,
                id: id,
                qualifiedTarget: qualifiedTarget,
                target: target,
                conversationRole: conversationRole,
                service: service,
                archived: archived,
                archivedReference: archivedReference?.date,
                hidden: hidden,
                hiddenReference: hiddenReference,
                mutedStatus: mutedStatus,
                mutedReference: mutedReference?.date
            )
        }
    }

    func decode(
        from container: KeyedDecodingContainer<ConversationEventCodingKeys>
    ) throws -> ConversationCreateEvent {
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

        return ConversationCreateEvent(
            conversationID: conversationID,
            senderID: senderID,
            timestamp: timestamp.date,
            conversation: .init(
                id: payload.id,
                qualifiedID: payload.qualifiedID,
                teamID: payload.teamID,
                type: payload.type,
                messageProtocol: payload.messageProtocol,
                mlsGroupID: payload.mlsGroupID,
                cipherSuite: payload.cipherSuite,
                epoch: payload.epoch,
                epochTimestamp: payload.epochTimestamp?.date,
                creator: payload.creator,
                members: payload.members?.toAPIModel(),
                name: payload.name,
                messageTimer: payload.messageTimer,
                readReceiptMode: payload.readReceiptMode,
                access: payload.access,
                accessRoles: payload.accessRoles,
                legacyAccessRole: payload.legacyAccessRole,
                lastEvent: payload.lastEvent,
                lastEventTime: payload.lastEventTime?.date
            )
        )
    }

    // MARK: Private

    private struct Payload: Decodable {
        enum CodingKeys: String, CodingKey {
            case id
            case qualifiedID = "qualified_id"
            case teamID = "team"
            case type
            case messageProtocol = "protocol"
            case mlsGroupID = "group_id"
            case cipherSuite = "cipher_suite"
            case epoch
            case epochTimestamp = "epoch_timestamp"
            case creator
            case members
            case name
            case messageTimer = "message_timer"
            case readReceiptMode = "receipt_mode"
            case access
            case accessRoles = "access_role_v2"
            case legacyAccessRole = "access_role"
            case lastEvent = "last_event"
            case lastEventTime = "last_event_time"
        }

        let id: UUID?
        let qualifiedID: ConversationID?
        let teamID: UUID?
        let type: ConversationType?
        let messageProtocol: ConversationMessageProtocol?
        let mlsGroupID: String?
        let cipherSuite: MLSCipherSuite?
        let epoch: UInt?
        let epochTimestamp: UTCTime?
        let creator: UUID?
        let members: Members?
        let name: String?
        let messageTimer: TimeInterval?
        let readReceiptMode: Int?
        let access: Set<ConversationAccessMode>?
        let accessRoles: Set<ConversationAccessRole>?
        let legacyAccessRole: ConversationAccessRoleLegacy?
        let lastEvent: String?
        let lastEventTime: UTCTimeMillis?
    }

    private struct Members: Decodable, ToAPIModelConvertible {
        enum CodingKeys: String, CodingKey {
            case others
            case selfMember = "self"
        }

        let others: [Member]
        let selfMember: Member

        func toAPIModel() -> Conversation.Members {
            Conversation.Members(
                others: others.map { $0.toAPIModel() },
                selfMember: selfMember.toAPIModel()
            )
        }
    }
}
