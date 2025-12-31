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

import UIKit
import WireMainNavigationUI
import WireMessagingDomain
import WireSyncEngine

final class CreateGroupConversationViewControllerBuilder: CreateGroupConversationViewControllerBuilderProtocol {

    let userSession: UserSession
    let conversationCreationRepository: ConversationCreationRepositoryProtocol
    weak var delegate: ConversationCreationControllerDelegate?

    init(
        userSession: UserSession,
        conversationCreationRepository: ConversationCreationRepositoryProtocol
    ) {
        self.userSession = userSession
        self.conversationCreationRepository = conversationCreationRepository
    }

    @MainActor
    func build() async -> UIViewController {
        let viewController = await ConversationCreationController(
            preSelectedParticipants: nil,
            userSession: userSession
        )
        viewController.delegate = delegate
        return viewController
    }
}
