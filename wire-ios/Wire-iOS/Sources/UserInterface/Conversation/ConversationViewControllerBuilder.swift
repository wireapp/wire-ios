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
import WireDataModel
import WireMainNavigation
import WireSyncEngine

@MainActor
struct ConversationViewControllerBuilder: MainConversationBuilderProtocol {

    typealias ConversationList = ConversationListViewController
    typealias SettingsBuilder = SettingsViewControllerBuilder
    typealias Conversation = ConversationRootViewController
    typealias User = any UserType

    var userSession: UserSession
    var mediaPlaybackManager: MediaPlaybackManager?

    func build<MainCoordinator: MainCoordinatorProtocol>(
        conversation: ZMConversation,
        message: ZMConversationMessage?,
        mainCoordinator: MainCoordinator
    ) -> Conversation where
    MainCoordinator.ConversationList == ConversationList,
    MainCoordinator.SettingsContentBuilder == SettingsBuilder,
    MainCoordinator.ConversationModel == Conversation.ConversationModel,
    MainCoordinator.ConversationMessageModel == Conversation.ConversationMessageModel,
    MainCoordinator.User == User {

        let viewController = ConversationRootViewController(
            conversation: conversation,
            message: message,
            userSession: userSession,
            mainCoordinator: .init(mainCoordinator: mainCoordinator),
            mediaPlaybackManager: mediaPlaybackManager
        )
        viewController.hidesBottomBarWhenPushed = true
        return viewController
    }
}
