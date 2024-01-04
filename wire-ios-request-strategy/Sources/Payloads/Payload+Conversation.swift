// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

extension Payload {
    struct Conversation: CodableAPIVersionAware, EventData {
        enum CodingKeys: String, CodingKey {
            case qualifiedID = "qualified_id"
            case id
            case type
            case creator
            case cipherSuite = "cipher_suite"
            case access
            case accessRole = "access_role"
            case accessRoleV2 = "access_role_v2"
            case name
            case members
            case lastEvent = "last_event"
            case lastEventTime = "last_event_time"
            case teamID = "team"
            case messageTimer = "message_timer"
            case readReceiptMode = "receipt_mode"
            case messageProtocol = "protocol"
            case mlsGroupID = "group_id"
            case epoch
            case epochTimestamp = "epoch_timestamp"
        }

        static var eventType: ZMUpdateEventType {
            return .conversationCreate
        }

        var qualifiedID: QualifiedID?
        var id: UUID?
        var type: Int?
        var creator: UUID?
        var cipherSuite: UInt16?
        var access: [String]?
        var accessRoles: [String]?
        var legacyAccessRole: String?
        var name: String?
        var members: ConversationMembers?
        var lastEvent: String?
        var lastEventTime: String?
        var teamID: UUID?
        var messageTimer: TimeInterval?
        var readReceiptMode: Int?
        var messageProtocol: String?
        var mlsGroupID: String?
        var epoch: UInt?
        var epochTimestamp: Date?

        init(qualifiedID: QualifiedID? = nil,
             id: UUID?  = nil,
             type: Int? = nil,
             creator: UUID? = nil,
             cipherSuite: UInt16? = nil,
             access: [String]? = nil,
             legacyAccessRole: String? = nil,
             accessRoles: [String]? = nil,
             name: String? = nil,
             members: ConversationMembers? = nil,
             lastEvent: String? = nil,
             lastEventTime: String? = nil,
             teamID: UUID? = nil,
             messageTimer: TimeInterval? = nil,
             readReceiptMode: Int? = nil,
             messageProtocol: String? = nil,
             mlsGroupID: String? = nil,
             epoch: UInt? = nil,
             epochTimestamp: Date? = nil
        ) {
            self.qualifiedID = qualifiedID
            self.id = id
            self.type = type
            self.creator = creator
            self.cipherSuite = cipherSuite
            self.access = access
            self.legacyAccessRole = legacyAccessRole
            self.accessRoles = accessRoles
            self.name = name
            self.members = members
            self.lastEvent = lastEvent
            self.lastEventTime = lastEventTime
            self.teamID = teamID
            self.messageTimer = messageTimer
            self.readReceiptMode = readReceiptMode
            self.messageProtocol = messageProtocol
            self.mlsGroupID = mlsGroupID
            self.epoch = epoch
            self.epochTimestamp = epochTimestamp
        }

        init(from decoder: Decoder, apiVersion: APIVersion) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            qualifiedID = try container.decodeIfPresent(QualifiedID.self, forKey: .qualifiedID)
            id = try container.decodeIfPresent(UUID.self, forKey: .id)
            type = try container.decodeIfPresent(Int.self, forKey: .type)
            creator = try container.decodeIfPresent(UUID.self, forKey: .creator)
            access = try container.decodeIfPresent([String].self, forKey: .access)
            name = try container.decodeIfPresent(String.self, forKey: .name)
            members = try container.decodeIfPresent(ConversationMembers.self, forKey: .members)
            lastEvent = try container.decodeIfPresent(String.self, forKey: .lastEvent)
            lastEventTime = try container.decodeIfPresent(String.self, forKey: .lastEventTime)
            teamID = try container.decodeIfPresent(UUID.self, forKey: .teamID)
            messageTimer = try container.decodeIfPresent(TimeInterval.self, forKey: .messageTimer)
            readReceiptMode = try container.decodeIfPresent(Int.self, forKey: .readReceiptMode)
            messageProtocol = try container.decodeIfPresent(String.self, forKey: .messageProtocol)
            mlsGroupID = try container.decodeIfPresent(String.self, forKey: .mlsGroupID)
            epoch = try container.decodeIfPresent(UInt.self, forKey: .epoch)

            switch apiVersion {
            case .v0, .v1, .v2:
                legacyAccessRole = try container.decodeIfPresent(String.self, forKey: .accessRole)
                accessRoles = try container.decodeIfPresent([String].self, forKey: .accessRoleV2)
            case .v3, .v4, .v5:

                // v3 replaces the field "access_role_v2" with "access_role".
                // However, since the format of update events does not depend on versioning,
                // we may receive conversations from the `conversation.create` update event
                // which still have both "access_role_v2" and "access_role" fields

                if !container.contains(CodingKeys.accessRoleV2) {
                    legacyAccessRole = nil
                    accessRoles = try container.decodeIfPresent([String].self, forKey: .accessRole)
                } else {
                    legacyAccessRole = try container.decodeIfPresent(String.self, forKey: .accessRole)
                    accessRoles = try container.decodeIfPresent([String].self, forKey: .accessRoleV2)
                }
            }

            switch apiVersion {
            case .v0, .v1, .v2, .v3, .v4:
                cipherSuite = nil
                epochTimestamp = nil
            case .v5:
                cipherSuite = try container.decodeIfPresent(UInt16.self, forKey: .cipherSuite)
                epochTimestamp = try container.decodeIfPresent(Date.self, forKey: .epochTimestamp)
            }
        }

        func encode(to encoder: Encoder, apiVersion: APIVersion) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            try container.encodeIfPresent(qualifiedID, forKey: .qualifiedID)
            try container.encodeIfPresent(id, forKey: .id)
            try container.encodeIfPresent(type, forKey: .type)
            try container.encodeIfPresent(creator, forKey: .creator)
            try container.encodeIfPresent(access, forKey: .access)
            try container.encodeIfPresent(name, forKey: .name)
            try container.encodeIfPresent(members, forKey: .members)
            try container.encodeIfPresent(lastEvent, forKey: .lastEvent)
            try container.encodeIfPresent(lastEventTime, forKey: .lastEventTime)
            try container.encodeIfPresent(teamID, forKey: .teamID)
            try container.encodeIfPresent(messageTimer, forKey: .messageTimer)
            try container.encodeIfPresent(readReceiptMode, forKey: .readReceiptMode)
            try container.encodeIfPresent(messageProtocol, forKey: .messageProtocol)
            try container.encodeIfPresent(epoch, forKey: .epoch)
            try container.encodeIfPresent(mlsGroupID, forKey: .mlsGroupID)

            switch apiVersion {
            case .v0, .v1, .v2:
                try container.encodeIfPresent(legacyAccessRole, forKey: .accessRole)
                try container.encodeIfPresent(accessRoles, forKey: .accessRoleV2)
            case .v3, .v4, .v5:
                if legacyAccessRole == nil {
                    try container.encodeIfPresent(accessRoles, forKey: .accessRole)
                } else {
                    try container.encodeIfPresent(legacyAccessRole, forKey: .accessRole)
                    try container.encodeIfPresent(accessRoles, forKey: .accessRoleV2)
                }
            }
        }
    }

    // MARK: - Actions

    struct ConversationUpdateRole: Codable {
        enum CodingKeys: String, CodingKey {
            case role = "conversation_role"
        }

        let role: String

        init?(role: String) {
            self.role = role
        }
    }

    // MARK: - Events

    struct ConversationEvent<T: CodableEventData>: Codable {

        let id: UUID?
        let data: T
        let from: UUID?
        let qualifiedID: QualifiedID?
        let qualifiedFrom: QualifiedID?
        let timestamp: Date?
        let type: String?

        enum CodingKeys: String, CodingKey {
            case id = "conversation"
            case data
            case from
            case qualifiedID = "qualified_conversation"
            case qualifiedFrom = "qualified_from"
            case timestamp = "time"
            case type
        }

    }

    struct UpdateConverationMemberLeave: CodableEventData {
        enum CodingKeys: String, CodingKey {
            case userIDs = "user_ids"
            case qualifiedUserIDs = "qualified_user_ids"
        }

        static var eventType: ZMUpdateEventType {
            return .conversationMemberLeave
        }

        let userIDs: [UUID]?
        let qualifiedUserIDs: [QualifiedID]?
    }

    struct UpdateConverationMemberJoin: CodableEventData {
        enum CodingKeys: String, CodingKey {
            case userIDs = "user_ids"
            case users
        }

        static var eventType: ZMUpdateEventType {
            return .conversationMemberJoin
        }

        let userIDs: [UUID]?
        let users: [ConversationMember]?

    }

    struct UpdateConversationConnectionRequest: CodableEventData {
        static var eventType: ZMUpdateEventType {
            return .conversationConnectRequest
        }
    }

    struct UpdateConversationDeleted: CodableEventData {
        static var eventType: ZMUpdateEventType {
            return .conversationDelete
        }
    }

    struct UpdateConversationReceiptMode: CodableEventData {
        enum CodingKeys: String, CodingKey {
            case readReceiptMode = "receipt_mode"
        }

        static var eventType: ZMUpdateEventType {
            return .conversationReceiptModeUpdate
        }

        let readReceiptMode: Int
    }

    struct UpdateConversationMessageTimer: CodableEventData {
        enum CodingKeys: String, CodingKey {
            case messageTimer = "message_timer"
        }

        static var eventType: ZMUpdateEventType {
            return .conversationMessageTimerUpdate
        }

        let messageTimer: TimeInterval?
    }

    struct UpdateConversationAccess: CodableEventData {
        enum CodingKeys: String, CodingKey {
            case access
            case accessRole = "access_role"
            case accessRoleV2 = "access_role_v2"
        }

        static var eventType: ZMUpdateEventType {
            return .conversationAccessModeUpdate
        }

        let access: [String]
        let accessRole: String?
        let accessRoleV2: [String]?

        init(accessMode: ConversationAccessMode, accessRoles: Set<ConversationAccessRoleV2>) {
            access = accessMode.stringValue
            accessRole = ConversationAccessRole.fromAccessRoleV2(accessRoles).rawValue
            accessRoleV2 = accessRoles.map(\.rawValue)
        }
    }

    struct UpdateConversationName: CodableEventData {
        var name: String

        static var eventType: ZMUpdateEventType {
            return .conversationRename
        }

        init?(_ conversation: ZMConversation) {
            guard
                conversation.hasLocalModifications(forKey: ZMConversationUserDefinedNameKey),
                let userDefinedName = conversation.userDefinedName
            else {
                return nil
            }

            name = userDefinedName
        }

        init(name: String) {
            self.name = name
        }
    }

    struct UpdateConversationMLSWelcome: Codable {

        enum CodingKeys: String, CodingKey {
            case id = "conversation"
            case qualifiedID = "qualified_conversation"
            case from
            case qualifiedFrom = "qualified_from"
            case timestamp = "time"
            case type
            case data
        }

        // This is currently the id of the self conversation.
        let id: UUID

        let qualifiedID: QualifiedID?
        let from: UUID
        let qualifiedFrom: QualifiedID?
        let timestamp: Date
        let type: String
        let data: String
    }

    struct UpdateConversationMLSMessageAdd: Codable {

        enum CodingKeys: String, CodingKey {
            case id = "conversation"
            case qualifiedID = "qualified_conversation"
            case from
            case qualifiedFrom = "qualified_from"
            case subconversationType = "subconv"
            case timestamp = "time"
            case type
            case data
        }

        let id: UUID
        let qualifiedID: QualifiedID?
        let from: UUID
        let qualifiedFrom: QualifiedID?
        let subconversationType: SubgroupType?
        let timestamp: Date
        let type: String
        let data: String
    }

    struct UpdateConversationProtocolChange: CodableEventData {
        static var eventType: ZMUpdateEventType {
            return .conversationConnectRequest
        }
    }
}
