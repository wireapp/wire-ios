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

import WireConversationList

final class AnyConversationListCoordinator<ConversationModel, MessageID>: ConversationListCoordinatorProtocol where
MessageID: Sendable {

    let showConversation: (ConversationModel) async -> Void
    let showConversationScrolledToMessage: (ConversationModel, MessageID) async -> Void

    init<ConversationListCoordinator: ConversationListCoordinatorProtocol>(
        conversationListCoordinator: ConversationListCoordinator
    ) where
    ConversationListCoordinator.ConversationModel == ConversationModel,
    ConversationListCoordinator.MessageID == MessageID {

        showConversation = { conversation in
            await conversationListCoordinator.showConversation(conversation: conversation)
        }
        showConversationScrolledToMessage = { conversation, messageID in
            await conversationListCoordinator.showConversation(conversation: conversation, scrolledToMessageWith: messageID)
        }
    }

    func showConversation(conversation: ConversationModel) async {
        await showConversation(conversation)
    }

    func showConversation(conversation: ConversationModel, scrolledToMessageWith messageID: MessageID) async {
        await showConversationScrolledToMessage(conversation, messageID)
    }
}
