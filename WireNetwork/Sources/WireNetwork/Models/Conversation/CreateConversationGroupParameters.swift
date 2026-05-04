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

public import Foundation

public struct CreateGroupConversationParameters: Sendable {
    let groupType: ConversationGroupType
    let messageProtocol: ConversationMessageProtocol
    let creatorClientID: String
    let qualifiedUserIDs: [QualifiedID]
    let unqualifiedUserIDs: [UUID]
    let name: String?
    let accessMode: Set<ConversationAccessMode>
    let accessRoles: Set<ConversationAccessRole>
    let legacyAccessRole: ConversationAccessRole?
    let teamID: UUID?
    let isReadReceiptsEnabled: Bool
    let skipCreator: Bool?
    let cells: Bool?

    public init(
        groupType: ConversationGroupType,
        messageProtocol: ConversationMessageProtocol,
        creatorClientID: String,
        qualifiedUserIDs: [QualifiedID],
        unqualifiedUserIDs: [UUID],
        name: String?,
        accessMode: Set<ConversationAccessMode>,
        accessRoles: Set<ConversationAccessRole>,
        legacyAccessRole: ConversationAccessRole?,
        teamID: UUID?,
        isReadReceiptsEnabled: Bool,
        cells: Bool? = nil, // parameter used from api v8
        skipCreator: Bool? = nil // until really used
    ) {
        self.groupType = groupType
        self.messageProtocol = messageProtocol
        self.creatorClientID = creatorClientID
        self.qualifiedUserIDs = qualifiedUserIDs
        self.unqualifiedUserIDs = unqualifiedUserIDs
        self.name = name
        self.accessMode = accessMode
        self.accessRoles = accessRoles
        self.legacyAccessRole = legacyAccessRole
        self.teamID = teamID
        self.isReadReceiptsEnabled = isReadReceiptsEnabled
        self.skipCreator = skipCreator
        self.cells = cells
    }
}
