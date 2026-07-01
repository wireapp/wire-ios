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

/// The various types of conversations.

public enum ConversationType: Sendable {

    /// A conversation with many participants.

    case group

    /// A conversation with only the self user.

    case `self`

    /// A conversation between the two users.

    case oneOnOne

    /// A placeholder conversation for a pending connection
    /// to another user.

    case connection

}

enum ConversationTypeV0: Int, Sendable, Decodable, ToAPIModelConvertible {

    case group = 0
    case `self` = 1
    case oneOnOne = 2
    case connection = 3

    func toAPIModel() -> ConversationType {
        switch self {
        case .group:
            .group
        case .self:
            .self
        case .oneOnOne:
            .oneOnOne
        case .connection:
            .connection
        }
    }
}
