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

@objc
public enum ConversationGroupType: Int16 {

    /// No group type set

    case none = 0

    /// A group conversation

    case group = 1

    /// A channel conversation

    case channel = 2

}

public extension ZMConversation {

    /// The group conversation type.

    @NSManaged var groupType: ConversationGroupType

    /// Whether the conversation is a channel.
    ///
    /// Returns `true` if the conversation type is `group` **and** the group type is `channel`, otherwise false.

    var isChannel: Bool {
        guard conversationType == .group else { return false }

        return groupType == .channel
    }

}
