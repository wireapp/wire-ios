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
struct UserProfileViewControllerBuilder<UserSession>: MainUserProfileBuilderProtocol where
UserSession: WireSyncEngine.UserSession {
    typealias UserID = WireDataModel.QualifiedID

    let userSession: UserSession
    let userLoader: (_ userID: UserID) async -> UserType?
    var delegate: ProfileViewControllerDelegate?

    init(
        userSession: UserSession,
        userLoader: @escaping (_ userID: UserID) async -> UserType?
    ) {
        self.userSession = userSession
        self.userLoader = userLoader
    }

    func build(
        userID: UserID,
        mainCoordinator: some MainCoordinatorProtocol
    ) async -> UINavigationController {

        let user = await userLoader(userID) // TODO: loading shouldn't happen here, instead pass the id into the `ProfileViewController`

        let rootViewController = ProfileViewController(
            user: user!, // TODO: don't force-unwrap
            viewer: userSession.selfUserLegalHoldSubject,
            context: .profileViewer,
            userSession: userSession,
            mainCoordinator: mainCoordinator
        )
        rootViewController.delegate = delegate
        return UINavigationController(rootViewController: rootViewController)
    }
}

// TODO: delete commented code
/*
 extension ConversationListViewController.ViewModel: StartUIDelegate {

     // TODO: migrate this code into MainCoordinator
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
 */
