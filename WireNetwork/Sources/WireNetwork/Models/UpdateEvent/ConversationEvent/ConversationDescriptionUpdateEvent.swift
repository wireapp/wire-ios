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

/// An event when the conversation description was changed

public struct ConversationDescriptionUpdateEvent: Equatable, Sendable {

    /// The id of the conversation.

    public let conversationID: ConversationID

    /// The id of the user who updated the message timer.

    public let senderID: UserID

    /// When the description was changed.

    public let timestamp: Date
    
    /// Version counter of the description

    public let version: Int

    /// Encrypted description

    public let ciphertext: String

    public init(
        conversationID: ConversationID,
        senderID: UserID,
        timestamp: Date,
        version: Int,
        ciphertext: String
    ) {
        self.conversationID = conversationID
        self.senderID = senderID
        self.timestamp = timestamp
        self.version = version
        self.ciphertext = ciphertext
    }

}
