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

struct ConversationViewControllerBuilder: MainConversationBuilderProtocol {

    var userSession: UserSession
    var mediaPlaybackManager: MediaPlaybackManager?
    var conversationLoader: (_ conversationID: UUID) async -> ZMConversation?

    @MainActor
    func build(
        conversationID: UUID,
        mainCoordinator: some MainCoordinatorProtocol
    ) async -> ConversationRootViewController {
        let viewController = ConversationRootViewController(
            conversation: await conversationLoader(conversationID)!, // TODO: a view controller shouldn't have to perform async tasks, either let the controller fetch the conversation or fetch it before
            message: nil, // TODO: use `scroll(to:)`
            userSession: userSession,
            mainCoordinator: mainCoordinator,
            mediaPlaybackManager: mediaPlaybackManager
        )
        viewController.hidesBottomBarWhenPushed = true
        return viewController
    }
}
