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

extension Payload {
    struct NewConversation: CodableAPIVersionAware, Equatable {
        enum CodingKeys: String, CodingKey {
            case users
            case qualifiedUsers = "qualified_users"
            case access
            case accessRole = "access_role"
            case accessRoleV2 = "access_role_v2"
            case name
            case team
            case messageTimer = "message_timer"
            case readReceiptMode = "receipt_mode"
            case conversationRole = "conversation_role"
            case creatorClient = "creator_client"
            case messageProtocol = "protocol"
        }

        let users: [UUID]?
        let qualifiedUsers: [QualifiedID]?
        let access: [String]?
        let legacyAccessRole: String?
        let accessRoles: [String]?
        let name: String?
        let team: ConversationTeamInfo?
        let messageTimer: TimeInterval?
        let readReceiptMode: Int?
        let conversationRole: String?

        // API V2 only
        let creatorClient: String?
        let messageProtocol: String?

        init(
            users: [UUID]? = nil,
            qualifiedUsers: [QualifiedID]? = nil,
            access: [String]? = nil,
            legacyAccessRole: String? = nil,
            accessRoles: [String]? = nil,
            name: String? = nil,
            team: Payload.ConversationTeamInfo? = nil,
            messageTimer: TimeInterval? = nil,
            readReceiptMode: Int? = nil,
            conversationRole: String? = nil,
            creatorClient: String? = nil,
            messageProtocol: String? = nil
        ) {
            self.users = users
            self.qualifiedUsers = qualifiedUsers
            self.access = access
            self.legacyAccessRole = legacyAccessRole
            self.accessRoles = accessRoles
            self.name = name
            self.team = team
            self.messageTimer = messageTimer
            self.readReceiptMode = readReceiptMode
            self.conversationRole = conversationRole
            self.creatorClient = creatorClient
            self.messageProtocol = messageProtocol
        }

        init(_ action: CreateGroupConversationAction) {
            switch action.messageProtocol {
            case .mls, .mixed:
                messageProtocol = "mls"
                creatorClient = action.creatorClientID
                qualifiedUsers = nil
                users = nil

            case .proteus:
                messageProtocol = "proteus"
                creatorClient = nil
                qualifiedUsers = action.qualifiedUserIDs
                users = action.unqualifiedUserIDs
            }

            name = action.name
            access = action.accessMode?.stringValue
            legacyAccessRole = action.legacyAccessRole?.rawValue
            accessRoles = action.accessRoles.map(\.rawValue)
            conversationRole = ZMConversation.defaultMemberRoleName
            team = action.teamID.map { ConversationTeamInfo(teamID: $0) }
            readReceiptMode = action.isReadReceiptsEnabled ? 1 : 0
            messageTimer = nil
        }

        init(from decoder: Decoder, apiVersion: WireTransport.APIVersion) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            users = try container.decodeIfPresent([UUID].self, forKey: .users)
            qualifiedUsers = try container.decodeIfPresent([QualifiedID].self, forKey: .qualifiedUsers)
            access = try container.decodeIfPresent([String].self, forKey: .access)
            name = try container.decodeIfPresent(String.self, forKey: .name)
            team = try container.decodeIfPresent(Payload.ConversationTeamInfo.self, forKey: .team)
            messageTimer = try container.decodeIfPresent(TimeInterval.self, forKey: .messageTimer)
            readReceiptMode = try container.decodeIfPresent(Int.self, forKey: .readReceiptMode)
            conversationRole = try container.decodeIfPresent(String.self, forKey: .conversationRole)
            creatorClient = try container.decodeIfPresent(String.self, forKey: .creatorClient)
            messageProtocol = try container.decodeIfPresent(String.self, forKey: .messageProtocol)

            switch apiVersion {
            case .v0, .v1, .v2:
                legacyAccessRole = try container.decodeIfPresent(String.self, forKey: .accessRole)
                accessRoles = try container.decodeIfPresent([String].self, forKey: .accessRoleV2)
            case .v3, .v4, .v5, .v6:
                accessRoles = try container.decodeIfPresent([String].self, forKey: .accessRole)
                legacyAccessRole = nil
            }
        }

        func encode(to encoder: Encoder, apiVersion: APIVersion) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            try container.encodeIfPresent(users, forKey: .users)
            try container.encodeIfPresent(qualifiedUsers, forKey: .qualifiedUsers)
            try container.encodeIfPresent(access, forKey: .access)
            try container.encodeIfPresent(name, forKey: .name)
            try container.encodeIfPresent(team, forKey: .team)
            try container.encodeIfPresent(messageTimer, forKey: .messageTimer)
            try container.encodeIfPresent(readReceiptMode, forKey: .readReceiptMode)
            try container.encodeIfPresent(conversationRole, forKey: .conversationRole)
            try container.encodeIfPresent(messageProtocol, forKey: .messageProtocol)
            try container.encodeIfPresent(creatorClient, forKey: .creatorClient)

            switch apiVersion {
            case .v0, .v1, .v2:
                try container.encodeIfPresent(legacyAccessRole, forKey: .accessRole)
                try container.encodeIfPresent(accessRoles, forKey: .accessRoleV2)
            case .v3, .v4, .v5, .v6:
                try container.encodeIfPresent(accessRoles, forKey: .accessRole)
            }
        }
    }
}
