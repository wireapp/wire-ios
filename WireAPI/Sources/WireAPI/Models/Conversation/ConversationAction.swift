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

/// Represents the actions that ca be performed in a conversation.

public enum ConversationAction: Hashable {

    /// The action of adding a new member to a conversation.

    case addConversationMember

    /// The action of removing an existing member from a conversation.

    case removeConversationMember

    /// The action of changing the conversation name.

    case modifyConversationName

    /// The action of changing the self-deleting message timer for the conversation.

    case modifyConversationMessageTimer

    /// The action of changing the read receipt mode of the conversation.

    case modifyConversationReceiptMode

    /// The action of changing the which members are allow to be present in the conversation.

    case modifyConversationAccess

    /// The action of changing the role of other members in the conversation.

    case modifyOtherConversationMember

    /// The action of removing yourself as a member of the conversation.

    case leaveConversation

    /// The action of deleting the conversation for all members.

    case deleteConversation
}
