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

/// An event where a new conversation was created.

public struct ConversationCreateEvent: Equatable, Codable, Sendable {

    /// The id of the conversation.

    public let conversationID: ConversationID

    /// The id of the user who created the conversation.

    public let senderID: UserID

    /// When the conversation was created.

    public let timestamp: Date

    /// The conversation metadata.

    public let conversation: Conversation

    public init(
        conversationID: ConversationID,
        senderID: UserID,
        timestamp: Date,
        conversation: Conversation
    ) {
        self.conversationID = conversationID
        self.senderID = senderID
        self.timestamp = timestamp
        self.conversation = conversation
    }

}
