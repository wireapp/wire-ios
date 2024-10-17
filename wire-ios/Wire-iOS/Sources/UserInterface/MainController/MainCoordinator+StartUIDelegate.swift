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

import WireDataModel
import WireMainNavigationUI

extension MainCoordinator: StartUIDelegate where Dependencies.ConversationModel == ZMConversation, Dependencies.User == any UserType {

    @MainActor
    func startUIViewController(_ viewController: StartUIViewController, didSelect user: any UserType) {
        Task {
            guard let userID = user.qualifiedID else { return }

            let userSession = viewController.userSession
            let conversation = user.oneToOneConversation

            do {
                let isReady = try await userSession.checkOneOnOneConversationIsReady.invoke(userID: userID)

                if isReady {

                    // If the conversation exists, and is established (in case of mls),
                    // then we open the conversation
                    guard let conversation else { return }
                    await showConversation(conversation: conversation, message: nil)

                } else {

                    // If the conversation should be using mls and is not established,
                    // or does not exits, then we open the user profile to let the user
                    // create the conversation
                    await showUserProfile(user: user)

                }
            } catch {
                WireLogger.conversation.warn("failed to check if one on one conversation is ready: \(error)")
            }
        }
    }

    @MainActor
    func startUIViewController(_ viewController: StartUIViewController, didSelect conversation: ZMConversation) {
        Task {
            await showConversation(conversation: conversation, message: nil)
        }
    }
}
