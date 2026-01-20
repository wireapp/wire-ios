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

/// The reason why a member was removed from a conversation.

public enum ConversationMemberLeaveReason: Sendable {

    /// The user has been removed from the team and therefore removed
    /// from all conversations.

    case userDeleted

    /// The user left the conversation by themselves.

    case userLeft

    /// The user was removed from the conversation by an admin.

    case userRemoved

}

enum ConversationMemberLeaveReasonV0: String, Sendable, Decodable, ToAPIModelConvertible {

    case userDeleted = "user-deleted"
    case userLeft = "left"
    case userRemoved = "removed"

    func toAPIModel() -> ConversationMemberLeaveReason {
        switch self {
        case .userDeleted:
            .userDeleted
        case .userLeft:
            .userLeft
        case .userRemoved:
            .userRemoved
        }
    }

}
