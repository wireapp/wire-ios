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

public import Foundation

/// An event where an mls message was received in a conversation.

public struct ConversationMLSMessageAddEvent: Equatable, Sendable {

    public struct DecryptedMessage: Equatable, Sendable {

        public let message: String

        public let senderClientID: String?

        public init(
            message: String,
            senderClientID: String?
        ) {
            self.message = message
            self.senderClientID = senderClientID
        }
    }

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

    /// The date the message was received.

    public let timestamp: Date?

    /// The decrypted current message + decrypted buffered messages
    /// along with the related sender client ID for each message.

    public var decryptedMessages: [DecryptedMessage] = []

    public init(
        conversationID: ConversationID,
        senderID: UserID,
        subconversation: String?,
        message: String,
        timestamp: Date?,
        decryptedMessages: [DecryptedMessage]
    ) {
        self.conversationID = conversationID
        self.senderID = senderID
        self.subconversation = subconversation
        self.message = message
        self.timestamp = timestamp
        self.decryptedMessages = decryptedMessages
    }

}
