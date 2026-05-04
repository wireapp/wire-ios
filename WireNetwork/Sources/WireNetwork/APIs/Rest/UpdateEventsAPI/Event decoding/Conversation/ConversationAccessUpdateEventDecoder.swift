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

struct ConversationAccessUpdateEventDecoder {

    func decode(
        from container: KeyedDecodingContainer<ConversationEventCodingKeys>
    ) throws -> ConversationAccessUpdateEvent {
        let conversationID = try container.decode(
            QualifiedIDV0.self,
            forKey: .conversationQualifiedID
        )

        let senderID = try container.decode(
            QualifiedIDV0.self,
            forKey: .senderQualifiedID
        )

        let payload = try container.decode(
            Payload.self,
            forKey: .payload
        )

        let accessRoles = payload.accessRoles?.map { $0.toAPIModel() }
        return ConversationAccessUpdateEvent(
            conversationID: conversationID.toAPIModel(),
            senderID: senderID.toAPIModel(),
            accessModes: Set(payload.accessModes.map { $0.toAPIModel() }),
            accessRoles: accessRoles.flatMap { Set($0) },
            legacyAccessRole: payload.legacyAccessRole?.toAPIModel()
        )
    }

    private struct Payload: Decodable {

        let accessModes: Set<ConversationAccessModeV0>
        let legacyAccessRole: ConversationAccessRoleLegacyV0?
        let accessRoles: Set<ConversationAccessRoleV0>?

        enum CodingKeys: String, CodingKey {

            case accessModes = "access"
            case legacyAccessRole = "access_role"
            case accessRoles = "access_role_v2"

        }

    }

}
