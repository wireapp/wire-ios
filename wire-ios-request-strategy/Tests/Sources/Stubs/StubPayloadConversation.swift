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
@testable import WireRequestStrategy

extension Payload.Conversation {
    static func stub(
        qualifiedID: QualifiedID? = nil,
        id: UUID? = nil,
        type: BackendConversationType? = nil,
        creator: UUID? = nil,
        access: [String]? = nil,
        accessRole: String? = nil,
        accessRoles: [String]? = nil,
        name: String? = nil,
        members: Payload.ConversationMembers? = nil,
        lastEvent: String? = nil,
        lastEventTime: String? = nil,
        teamID: UUID? = nil,
        messageTimer: TimeInterval? = nil,
        readReceiptMode: Int? = nil,
        messageProtocol: String? = "proteus",
        mlsGroupID: String? = Data("id".utf8).base64EncodedString()
    ) -> Self {
        self.init(
            qualifiedID: qualifiedID,
            id: id,
            type: type?.rawValue,
            creator: creator,
            access: access,
            legacyAccessRole: accessRole,
            accessRoles: accessRoles,
            name: name,
            members: members,
            lastEvent: lastEvent,
            lastEventTime: lastEventTime,
            teamID: teamID,
            messageTimer: messageTimer,
            readReceiptMode: readReceiptMode,
            messageProtocol: messageProtocol,
            mlsGroupID: mlsGroupID
        )

    }
}
