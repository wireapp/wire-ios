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

extension ZClientViewController {

    private func wrapInNavigationControllerAndPresent(viewController: UIViewController) {
        let navWrapperController: UINavigationController = viewController.wrapInNavigationController()
        navWrapperController.modalPresentationStyle = .formSheet

        dismissAllModalControllers { [weak self] in
            self?.present(navWrapperController, animated: true)
        }
    }

    func showConnectionRequest(userId: UUID) {
        let searchUserViewConroller = SearchUserViewController(
            userId: userId,
            profileViewControllerDelegate: self,
            userSession: userSession,
            mainCoordinator: tmpMainCoordinator // TODO: fix
        )

        wrapInNavigationControllerAndPresent(viewController: searchUserViewConroller)
    }

    func showUserProfile(user: UserType) {
        guard let selfUser = ZMUser.selfUser() else {
            assertionFailure("ZMUser.selfUser() is nil")
            return
        }

        let profileViewController = ProfileViewController(
            user: user,
            viewer: selfUser,
            context: .profileViewer,
            userSession: userSession,
            mainCoordinator: tmpMainCoordinator // TODO: fix
        )
        profileViewController.delegate = self

        wrapInNavigationControllerAndPresent(viewController: profileViewController)
    }

    func showConversation(_ conversation: ZMConversation, at message: ZMConversationMessage?) {
        switch conversation.conversationType {
        case .connection:
            selectIncomingContactRequestsAndFocus(onView: true)
        case .group, .oneOnOne:
            select(conversation: conversation,
                   scrollTo: message,
                   focusOnView: true,
                   animated: true)
        default:
            break
        }
    }
}
