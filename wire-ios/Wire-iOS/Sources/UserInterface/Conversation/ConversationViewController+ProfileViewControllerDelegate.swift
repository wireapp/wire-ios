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

import WireSyncEngine

extension ConversationViewController {

    func createUserDetailViewController() -> UIViewController {
        guard let user = (conversation.firstActiveParticipantOtherThanSelf ?? conversation.connectedUser) else {
            fatal("no firstActiveParticipantOtherThanSelf!")
        }

        return UserDetailViewControllerFactory.createUserDetailViewController(
            user: user,
            conversation: conversation,
            profileViewControllerDelegate: self,
            viewControllerDismisser: self,
            userSession: userSession,
            mainCoordinator: mainCoordinator
        )
    }
}

extension ConversationViewController: ProfileViewControllerDelegate {
    func profileViewController(_ controller: ProfileViewController?, wantsToNavigateTo conversation: ZMConversation) {
        dismiss(animated: true) {
            fatalError("TODO")
            // TODO: fix
            //self.mainCoordinator.openConversation(conversation, focusOnView: true, animated: true)
        }
    }
}
