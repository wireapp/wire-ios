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
struct UserProfileViewControllerBuilder: MainUserProfileBuilderProtocol {
    typealias UserID = WireDataModel.QualifiedID

    func build(
        userID: UserID,
        mainCoordinator: some MainCoordinatorProtocol
    ) -> ProfileViewController {

        fatalError("TODO")
        let user: (any UserType)! = nil
        let viewer: (any UserType)! = nil
        let userSession: (any UserSession)! = nil

        return .init(
            user: user,
            viewer: viewer,
            context: .profileViewer,
            userSession: userSession,
            mainCoordinator: mainCoordinator
        )
    }
}

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
