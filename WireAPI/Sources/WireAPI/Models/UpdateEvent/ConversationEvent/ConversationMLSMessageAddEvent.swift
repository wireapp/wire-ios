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

/// An event where an mls message was received in a conversation.

public struct ConversationMLSMessageAddEvent: Equatable, Codable, Sendable {

    /// The id of the conversation.

    public let conversationID: ConversationID

    /// The id of the user who sent the message.

    public let senderID: UserID

    /// The subconversation that received the message.
    ///
    /// If a value is present, then the message belongs to
    /// the subconversation with that name. If `nil`, the
    /// message belongs to the parent conversation.

    public let subconversation: String?

    /// The base 64 encoded message.

    public let message: String

}
