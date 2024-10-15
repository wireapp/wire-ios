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
import WireMainNavigationUI
import WireSyncEngine

@MainActor
final class UserProfileViewControllerBuilder: MainUserProfileBuilderProtocol {
    typealias User = any UserType

    let userSession: UserSession
    var delegate: ProfileViewControllerDelegate?

    init(userSession: some WireSyncEngine.UserSession) {
        self.userSession = userSession
    }

    func build(
        user: User,
        mainCoordinator: some MainCoordinatorProtocol
    ) -> UINavigationController {
        let rootViewController = ProfileViewController(
            user: user,
            viewer: userSession.selfUserLegalHoldSubject,
            context: .profileViewer,
            userSession: userSession,
            mainCoordinator: mainCoordinator
        )
        rootViewController.delegate = delegate
        let navigtaionController = UINavigationController(rootViewController: rootViewController)
        navigtaionController.modalPresentationStyle = .formSheet
        return navigtaionController
    }
}
