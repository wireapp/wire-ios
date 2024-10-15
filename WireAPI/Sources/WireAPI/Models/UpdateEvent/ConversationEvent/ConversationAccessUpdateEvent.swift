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

/// An event where the access settings of a conversation were updated.

public struct ConversationAccessUpdateEvent: Equatable, Codable {

    /// The id of the conversation.

    public let conversationID: ConversationID

    /// The id of the user who updated the access settings.

    public let senderID: UserID

    /// The new access modes.

    public let accessModes: Set<ConversationAccessMode>

    /// The new access roles.

    public let accessRoles: Set<ConversationAccessRole>

    /// The new legacy access role.

    public let legacyAccessRole: ConversationAccessRoleLegacy?

    public init(conversationID: ConversationID,
                senderID: UserID,
                accessModes: Set<ConversationAccessMode>,
                accessRoles: Set<ConversationAccessRole>,
                legacyAccessRole: ConversationAccessRoleLegacy?) {
        self.conversationID = conversationID
        self.senderID = senderID
        self.accessModes = accessModes
        self.accessRoles = accessRoles
        self.legacyAccessRole = legacyAccessRole
    }

}
