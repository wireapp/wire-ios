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
import WireSyncEngine

extension ConversationListViewController.ViewModel: StartUIDelegate {
    func startUI(_ startUI: StartUIViewController, didSelect user: UserType) {
        guard let userID = user.qualifiedID else {
            return
        }

        let conversation = user.oneToOneConversation

        Task {
            do {
                let isReady = try await userSession.checkOneOnOneConversationIsReady.invoke(userID: userID)

                if isReady {
                    // If the conversation exists, and is established (in case of mls),
                    // then we open the conversation
                    guard let conversation else {
                        return
                    }
                    await openConversation(conversation)

                } else {
                    // If the conversation should be using mls and is not established,
                    // or does not exits, then we open the user profile to let the user
                    // create the conversation
                    await openUserProfile(user)
                }
            } catch {
                WireLogger.conversation.warn("failed to check if one on one conversation is ready: \(error)")
            }
        }
    }

    func startUI(_ startUI: StartUIViewController, didSelect conversation: ZMConversation) {
        startUI.dismissIfNeeded(animated: true) {
            ZClientViewController.shared?.select(conversation: conversation, focusOnView: true, animated: true)
        }
    }

    @MainActor
    func openConversation(_ conversation: ZMConversation) {
        ZClientViewController.shared?.select(conversation: conversation, focusOnView: true, animated: true)
    }

    @MainActor
    func openUserProfile(_ user: UserType) {
        let profileViewController = ProfileViewController(
            user: user,
            viewer: selfUserLegalHoldSubject,
            context: .profileViewer,
            userSession: userSession,
            mainCoordinator: mainCoordinator
        )
        profileViewController.delegate = self

        let navigationController = profileViewController.wrapInNavigationController()
        navigationController.modalPresentationStyle = .formSheet

        ZClientViewController.shared?.present(navigationController, animated: true)
    }
}
