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

// MARK: - UpdateAccessRolesError

public enum UpdateAccessRolesError: Error {
    case unknown
    case invalidOperation
    case accessDenied
    case actionDenied
    case conversationNotFound
}

// MARK: - UpdateAccessRolesAction

public class UpdateAccessRolesAction: EntityAction {
    // MARK: - Types

    public typealias Result = Void
    public typealias Failure = UpdateAccessRolesError

    // MARK: - Properties

    public var resultHandler: ResultHandler?

    public let conversationID: NSManagedObjectID
    public let accessMode: ConversationAccessMode
    public let accessRoles: Set<ConversationAccessRoleV2>

    // MARK: - Life cycle

    public init(
        conversation: ZMConversation,
        accessMode: ConversationAccessMode,
        accessRoles: Set<ConversationAccessRoleV2>,
        resultHandler: ResultHandler? = nil
    ) {
        self.conversationID = conversation.objectID
        self.accessMode = accessMode
        self.accessRoles = accessRoles
        self.resultHandler = resultHandler
    }
}
