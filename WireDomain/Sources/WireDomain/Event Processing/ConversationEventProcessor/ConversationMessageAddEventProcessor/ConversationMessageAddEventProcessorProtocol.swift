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
import GenericMessageProtocol
import WireDataModel
import WireNetwork

/// The purpose of this protocol is sharing code between `ConversationMLSMessageAddEventProcessor` and
/// `ConversationProteusMessageAddEventProcessor`.

protocol ConversationMessageAddEventProcessorProtocol {

    var messageLocalStore: any MessageLocalStoreProtocol { get }

    /// Due to the protobuf declaration being extended we might receive a generic message where `content` cannot be
    /// deserialized.
    /// This method adds a system message to the conversation in order to inform the user.

    func addUnknownContentTypeSystemMessage(
        senderID: UserID,
        conversationID: ConversationID,
        date: Date
    ) async

    func addInvalidSystemMessage(
        senderID: UserID,
        conversationID: ConversationID,
        date: Date
    ) async

    func handleMessageContentNil(
        messageID: String,
        payload: Data,
        senderID: WireNetwork.QualifiedID,
        conversationID: WireNetwork.QualifiedID,
        unknownStrategy: GenericMessage.UnknownStrategy,
        date: Date
    ) async

}

extension ConversationMessageAddEventProcessorProtocol {

    func addUnknownContentTypeSystemMessage(
        senderID: UserID,
        conversationID: ConversationID,
        date: Date
    ) async {
        let systemMessageType: SystemMessageType = .unknownMessageContentTypeReceived(
            sender: (senderID.id, senderID.domain),
            date: date
        )
        await messageLocalStore.addSystemMessage(
            messageType: systemMessageType,
            conversationID: conversationID.id,
            conversationDomain: conversationID.domain
        )
    }

    func addInvalidSystemMessage(
        senderID: UserID,
        conversationID: ConversationID,
        date: Date
    ) async {
        let systemMessageType: SystemMessageType = .invalid(
            sender: (senderID.id, senderID.domain),
            date: date
        )
        await messageLocalStore.addSystemMessage(
            messageType: systemMessageType,
            conversationID: conversationID.id,
            conversationDomain: conversationID.domain
        )
    }

    func handleMessageContentNil(
        messageID: String,
        payload: Data,
        senderID: WireNetwork.QualifiedID,
        conversationID: WireNetwork.QualifiedID,
        unknownStrategy: GenericMessage.UnknownStrategy,
        date: Date
    ) async {
        switch unknownStrategy {
        case .ignore:
            return
        case .discardAndWarn:
            await addUnknownContentTypeSystemMessage(
                senderID: senderID,
                conversationID: conversationID,
                date: date
            )
        case .warnUserAllowRetry:
            await messageLocalStore.addUnknownMessage(
                messageID: UUID(transportString: messageID) ?? UUID(),
                conversationID: conversationID.id,
                conversationDomain: conversationID.domain,
                senderID: senderID.id,
                senderDomain: senderID.domain,
                payload: payload,
                date: date
            )
        }
    }

}
