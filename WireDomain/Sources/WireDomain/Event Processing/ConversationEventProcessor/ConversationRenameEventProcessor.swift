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

import WireAPI
import WireDataModel

/// Process conversation rename events.

protocol ConversationRenameEventProcessorProtocol {

    /// Process a conversation rename event.
    ///
    /// - Parameter event: A conversation rename event.

    func processEvent(_ event: ConversationRenameEvent) async throws

}

struct ConversationRenameEventProcessor: ConversationRenameEventProcessorProtocol {

    let context: NSManagedObjectContext

    func processEvent(_ event: ConversationRenameEvent) async throws {
        await context.perform {
            let conversation = ZMConversation.fetchOrCreate(
                with: event.conversationID.uuid,
                domain: event.conversationID.domain,
                in: context
            )

            let sender = ZMUser.fetchOrCreate(
                with: event.senderID.uuid,
                domain: event.senderID.domain,
                in: context
            )

            let nameDidChange = conversation.userDefinedName != event.newName
            conversation.userDefinedName = event.newName

            if nameDidChange {
                let message = ZMSystemMessage(
                    nonce: UUID(),
                    managedObjectContext: context
                )

                message.systemMessageType = .conversationNameChanged
                message.visibleInConversation = conversation
                message.serverTimestamp = event.timestamp
                message.users = [sender]
                message.text = event.newName

                conversation.updateTimestampsAfterUpdatingMessage(message)
            }
        }
    }

}
