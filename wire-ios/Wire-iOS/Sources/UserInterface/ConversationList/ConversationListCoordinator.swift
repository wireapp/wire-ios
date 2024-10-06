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
import WireDataModel
import WireMainNavigation

@MainActor
final class ConversationListCoordinator<MainCoordinator: MainCoordinatorProtocol>: ConversationListCoordinatorProtocol {

    typealias ConversationModel = MainCoordinator.ConversationBuilder.Conversation.ConversationModel
    typealias ConversationMessageModel = MainCoordinator.ConversationBuilder.Conversation.ConversationMessageModel

    let mainCoordinator: MainCoordinator

    init(mainCoordinator: MainCoordinator) {
        self.mainCoordinator = mainCoordinator
    }

    func showConversation(conversation: ConversationModel) async {
        await mainCoordinator.showConversation(conversation: conversation, message: nil)
    }

    func showConversation(conversation: ConversationModel, scrolledTo message: ConversationMessageModel) async {
        await mainCoordinator.showConversation(conversation: conversation, message: message)
    }
}
