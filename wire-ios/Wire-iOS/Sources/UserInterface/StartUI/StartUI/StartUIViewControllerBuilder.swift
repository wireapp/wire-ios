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
import WireMainNavigationUI
import WireSyncEngine

final class StartUIViewControllerBuilder: ConnectViewControllerBuilderProtocol {

    let userSession: UserSession
    let mainCoordinator: AnyMainCoordinator
    let createGroupConversationUIBuilder: CreateGroupConversationViewControllerBuilderProtocol
    let selfProfileUIBuilder: SelfProfileViewControllerBuilderProtocol
    var delegate: StartUIDelegate?

    init(
        userSession: UserSession,
        mainCoordinator: AnyMainCoordinator,
        createGroupConversationUIBuilder: CreateGroupConversationViewControllerBuilderProtocol,
        selfProfileUIBuilder: SelfProfileViewControllerBuilderProtocol
    ) {
        self.userSession = userSession
        self.mainCoordinator = mainCoordinator
        self.createGroupConversationUIBuilder = createGroupConversationUIBuilder
        self.selfProfileUIBuilder = selfProfileUIBuilder
    }

    func build() -> UIViewController {
        let viewController = StartUIViewController(
            userSession: userSession,
            mainCoordinator: mainCoordinator,
            createGroupConversationUIBuilder: createGroupConversationUIBuilder,
            selfProfileUIBuilder: selfProfileUIBuilder
        )
        viewController.delegate = delegate
        return viewController
    }
}
