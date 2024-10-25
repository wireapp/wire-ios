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

/// The reason why a member was removed from a conversation.

public enum ConversationMemberLeaveReason: String, Codable, Sendable {

    /// The user has been removed from the team and therefore removed
    /// from all conversations.

    case userDeleted = "user-deleted"

    /// The user left the conversation by themselves.

    case left

    /// The user was removed from the conversation by an admin.

    case removed

}
