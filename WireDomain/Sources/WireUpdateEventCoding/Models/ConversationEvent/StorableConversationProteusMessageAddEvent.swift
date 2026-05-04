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
import WireNetwork

struct StorableConversationProteusMessageAddEvent: Equatable, Codable, Sendable {

    private let conversationID: StorableQualifiedID
    private let senderID: StorableQualifiedID
    private let timestamp: Date
    private let message: StorableMessageContent
    private let externalData: StorableMessageContent?
    private let messageSenderClientID: String
    private let messageRecipientClientID: String

    init(_ value: WireNetwork.ConversationProteusMessageAddEvent) {
        self.conversationID = StorableQualifiedID(value.conversationID)
        self.senderID = StorableQualifiedID(value.senderID)
        self.timestamp = value.timestamp
        self.message = StorableMessageContent(value.message)
        self.externalData = value.externalData.map(StorableMessageContent.init)
        self.messageSenderClientID = value.messageSenderClientID
        self.messageRecipientClientID = value.messageRecipientClientID
    }

    func toAPIModel() -> WireNetwork.ConversationProteusMessageAddEvent {
        .init(
            conversationID: conversationID.toAPIModel(),
            senderID: senderID.toAPIModel(),
            timestamp: timestamp,
            message: message.toAPIModel(),
            externalData: externalData?.toAPIModel(),
            messageSenderClientID: messageSenderClientID,
            messageRecipientClientID: messageRecipientClientID
        )
    }

}

private struct StorableMessageContent: Equatable, Codable, Sendable {

    let encryptedMessage: String
    let decryptedMessage: String?

    init(_ value: WireNetwork.MessageContent) {
        self.encryptedMessage = value.encryptedMessage
        self.decryptedMessage = value.decryptedMessage
    }

    func toAPIModel() -> WireNetwork.MessageContent {
        .init(
            encryptedMessage: encryptedMessage,
            decryptedMessage: decryptedMessage
        )
    }

}
