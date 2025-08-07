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
import WireNetwork
import GenericMessageProtocol

/// The purpose of this protocol is sharing code between `ConversationMLSMessageAddEventProcessor` and
/// `ConversationProteusMessageAddEventProcessor`.

protocol ConversationMessageAddEventProcessorProtocol {

    var messageLocalStore: any MessageLocalStoreProtocol { get }

    func addInvalidSystemMessage(
        senderID: UserID,
        conversationID: ConversationID,
        date: Date
    ) async

    func handleNilContent(
        payload: Data,
        unknownStrategy: GenericMessage.UnknownStrategy
    ) async

}

extension ConversationMessageAddEventProcessorProtocol {

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
        payload: Data,
        unknownStrategy: GenericMessage.UnknownStrategy
    ) async {
        switch unknownStrategy {
        case .ignore:
            fatalError("TODO")
        case .discardAndWarn:
            fatalError("TODO")
        case .warnUserAllowRetry:
            fatalError("TODO")
            // await messageLocalStore.addUnknownMessage()
        }
    }

}
