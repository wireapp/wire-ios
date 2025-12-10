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

import Foundation
import WireDataModel
import WireMessagingDomain
import WireMainNavigationUI
import WireSyncEngine

enum UserDetailViewControllerFactory {

    /// Create a ServiceDetailViewController if the user is a serviceUser, otherwise return a ProfileViewController
    ///
    /// - Parameters:
    ///   - user: user to show the details
    ///   - conversation: conversation currently displaying
    ///   - profileViewControllerDelegate: a ProfileViewControllerDelegate for ProfileViewController
    /// - Returns: if the user is a serviceUser, return a ProfileHeaderServiceDetailViewController. if the user not a
    /// serviceUser, return a ProfileViewController
    static func createUserDetailViewController(
        user: UserType,
        conversation: ZMConversation,
        profileViewControllerDelegate: ProfileViewControllerDelegate,
        userSession: UserSession,
        mainCoordinator: AnyMainCoordinator,
        selfProfileUIBuilder: some SelfProfileViewControllerBuilderProtocol,
        conversationCreationRepository: any ConversationCreationRepositoryProtocol
    ) -> UIViewController {

        if user.isAppOrBot, let serviceUser = user as? ServiceUser {
            return ServiceDetailViewController(
                serviceUser: serviceUser,
                actionType: .removeService(conversation),
                userSession: userSession
            )

        } else {
            let profileViewController = ProfileViewController(
                user: user,
                viewer: userSession.selfUser,
                conversation: conversation,
                userSession: userSession,
                mainCoordinator: mainCoordinator,
                selfProfileUIBuilder: selfProfileUIBuilder,
                conversationCreationRepository: conversationCreationRepository
            )
            profileViewController.delegate = profileViewControllerDelegate
            return profileViewController
        }
    }
}
