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

import WireConversationListUI

final class AnyConversationListCoordinator<ConversationModel, ConversationMessageModel>: ConversationListCoordinatorProtocol {

    let showConversation: (ConversationModel) async -> Void
    let showConversationScrolledToMessage: (ConversationModel, ConversationMessageModel) async -> Void

    init<ConversationListCoordinator: ConversationListCoordinatorProtocol>(
        conversationListCoordinator: ConversationListCoordinator
    ) where
    ConversationListCoordinator.ConversationModel == ConversationModel,
    ConversationListCoordinator.ConversationMessageModel == ConversationMessageModel {

        showConversation = { conversation in
            await conversationListCoordinator.showConversation(conversation: conversation)
        }
        showConversationScrolledToMessage = { conversation, message in
            await conversationListCoordinator.showConversation(conversation: conversation, scrolledTo: message)
        }
    }

    func showConversation(conversation: ConversationModel) async {
        await showConversation(conversation)
    }

    func showConversation(conversation: ConversationModel, scrolledTo message: ConversationMessageModel) async {
        await showConversationScrolledToMessage(conversation, message)
    }
}
