//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireNetwork
import WireDataModel

/// The purpose of this protocol is sharing code between `ConversationMLSMessageAddEventProcessor` and
/// `ConversationProteusMessageAddEventProcessor`.

protocol ConversationMessageAddEventProcessorProtocol {

    var messageLocalStore: any MessageLocalStoreProtocol { get }

    func addUnknownSystemMessage(
        senderID: UserID,
        conversationID: ConversationID,
        date: Date
    ) async

    func addInvalidSystemMessage( // TODO: same text?
        senderID: UserID,
        conversationID: ConversationID,
        date: Date
    ) async

    func handleNilContent(
        messageID: String,
        payload: Data,
        senderID: WireNetwork.QualifiedID,
        conversationID: WireNetwork.QualifiedID,
        unknownStrategy: GenericMessage.UnknownStrategy,
        date: Date
    ) async

}

extension ConversationMessageAddEventProcessorProtocol {

    func addUnknownSystemMessage(
        senderID: UserID,
        conversationID: ConversationID,
        date: Date
    ) async {
        let systemMessageType: SystemMessageType = .unknownMessageReceived(
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

    func handleNilContent(
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
            await addUnknownSystemMessage(
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
