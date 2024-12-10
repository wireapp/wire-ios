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

/// An event where a proteus message was received in a conversation.

public struct ConversationProteusMessageAddEvent: Equatable, Codable, Sendable {

    /// The id of the conversation.

    public let conversationID: ConversationID

    /// The id of the user who sent the message.

    public let senderID: UserID

    /// When the message was sent.

    public let timestamp: Date

    /// The base 64 encoded message.

    public var message: MessageContent

    /// The base 64 encoded external data.

    public var externalData: MessageContent?

    /// The id of the user client who sent the message.

    public let messageSenderClientID: String

    /// The id of the user client who should receive the message.

    public let messageRecipientClientID: String

    /// Create a new `ConversationProteusMessageAddEvent`.
    ///
    /// - Parameters:
    ///   - conversationID: The id of the conversation.
    ///   - senderID: The id of the user who sent the message.
    ///   - timestamp: When the message was sent.
    ///   - message: The base 64 encoded message.
    ///   - externalData: The base 64 encoded external data.
    ///   - messageSenderClientID: The id of the user client who sent the message.
    ///   - messageRecipientClientID:  The id of the user client who should receive the message.

    public init(
        conversationID: ConversationID,
        senderID: UserID,
        timestamp: Date,
        message: MessageContent,
        externalData: MessageContent? = nil,
        messageSenderClientID: String,
        messageRecipientClientID: String
    ) {
        self.conversationID = conversationID
        self.senderID = senderID
        self.timestamp = timestamp
        self.message = message
        self.externalData = externalData
        self.messageSenderClientID = messageSenderClientID
        self.messageRecipientClientID = messageRecipientClientID
    }

}
