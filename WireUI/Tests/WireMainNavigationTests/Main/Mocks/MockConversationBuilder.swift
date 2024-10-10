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

import UIKit

@testable import WireMainNavigation

// swiftlint:disable opening_brace

struct MockConversationBuilder: MainConversationBuilderProtocol {
    typealias ConversationList = PreviewConversationListViewController
    typealias SettingsBuilder = MockSettingsViewControllerBuilder
    typealias Conversation = MockConversationViewController<MockConversation, MockMessage>
    typealias ConversationModel = Conversation.ConversationModel
    typealias ConversationMessageModel = Conversation.ConversationMessageModel
    typealias User = MockUserProfileViewControllerBuilder.User

    @MainActor
    func build<MainCoordinator: MainCoordinatorProtocol>(
        conversation: Conversation.ConversationModel,
        message: Conversation.ConversationMessageModel?,
        mainCoordinator: MainCoordinator
    ) -> Conversation where
        MainCoordinator.ConversationList == ConversationList,
        MainCoordinator.SettingsContentBuilder == SettingsBuilder,
        MainCoordinator.ConversationModel == Conversation.ConversationModel,
        MainCoordinator.ConversationMessageModel == Conversation.ConversationMessageModel,
        MainCoordinator.User == User
    {
        .init()
    }
}

// swiftlint:enable opening_brace
