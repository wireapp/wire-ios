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

struct ConversationCreateEventDecoder {

    func decode(
        from container: KeyedDecodingContainer<ConversationEventCodingKeys>
    ) throws -> ConversationCreateEvent {
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
        let accessRoles = payload.accessRoles?.map { $0.toAPIModel() }
        let access = payload.access?.map { $0.toAPIModel() }

        let conversation = Conversation(
            id: payload.id,
            qualifiedID: payload.qualifiedID?.toAPIModel(),
            teamID: payload.teamID,
            type: payload.type?.toAPIModel(),
            messageProtocol: payload.messageProtocol?.toAPIModel(),
            mlsGroupID: payload.mlsGroupID,
            cipherSuite: payload.cipherSuite?.toAPIModel(),
            epoch: payload.epoch,
            epochTimestamp: payload.epochTimestamp?.date,
            creator: payload.creator,
            members: payload.members?.toAPIModel(),
            name: payload.name,
            messageTimer: payload.messageTimer,
            readReceiptMode: payload.readReceiptMode,
            access: access.flatMap { Set($0) },
            accessRoles: accessRoles.flatMap { Set($0) },
            legacyAccessRole: payload.legacyAccessRole?.toAPIModel(),
            lastEvent: payload.lastEvent,
            lastEventTime: payload.lastEventTime?.date,
            groupType: payload.groupType?.toAPIModel()
        )
        return ConversationCreateEvent(
            conversationID: conversationID.toAPIModel(),
            senderID: senderID.toAPIModel(),
            timestamp: timestamp.date,
            conversation: conversation
        )
    }

    private struct Payload: Decodable {

        let id: UUID?
        let qualifiedID: QualifiedIDV0?
        let teamID: UUID?
        let type: ConversationTypeV0?
        let messageProtocol: ConversationMessageProtocolV0?
        let mlsGroupID: String?
        let cipherSuite: MLSCipherSuiteV0?
        let epoch: UInt?
        let epochTimestamp: UTCTime?
        let creator: UUID?
        let members: Members?
        let name: String?
        let messageTimer: TimeInterval?
        let readReceiptMode: Int?
        let access: Set<ConversationAccessModeV0>?
        let accessRoles: Set<ConversationAccessRoleV0>?
        let legacyAccessRole: ConversationAccessRoleLegacyV0?
        let lastEvent: String?
        let lastEventTime: UTCTime?
        let groupType: ConversationGroupTypeV8?

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
            case groupType = "group_conv_type"

        }

    }

    private struct Members: Decodable, ToAPIModelConvertible {

        let others: [Member]
        let selfMember: Member

        enum CodingKeys: String, CodingKey {

            case others
            case selfMember = "self"

        }

        func toAPIModel() -> Conversation.Members {
            Conversation.Members(
                others: others.map { $0.toAPIModel() },
                selfMember: selfMember.toAPIModel()
            )
        }

    }

    struct Member: Decodable, ToAPIModelConvertible {

        let qualifiedID: QualifiedIDV0?
        let id: UUID?
        let qualifiedTarget: QualifiedIDV0?
        let target: UUID?
        let conversationRole: String?
        let service: ServiceV0?
        let archived: Bool?
        let archivedReference: UTCTime?
        let hidden: Bool?
        let hiddenReference: String?
        let mutedStatus: Int?
        let mutedReference: UTCTime?

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

        func toAPIModel() -> Conversation.Member {
            Conversation.Member(
                qualifiedID: qualifiedID?.toAPIModel(),
                id: id,
                qualifiedTarget: qualifiedTarget?.toAPIModel(),
                target: target,
                conversationRole: conversationRole,
                service: service?.toAPIModel(),
                archived: archived,
                archivedReference: archivedReference?.date,
                hidden: hidden,
                hiddenReference: hiddenReference,
                mutedStatus: mutedStatus,
                mutedReference: mutedReference?.date
            )
        }

    }

}
