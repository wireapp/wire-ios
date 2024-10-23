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
    let selfProfileUIBuilder: SelfProfileViewControllerBuilderProtocol
    var delegate: StartUIDelegate?
    weak var conversationCreationControllerDelegate: ConversationCreationControllerDelegate?

    init(
        userSession: UserSession,
        selfProfileUIBuilder: SelfProfileViewControllerBuilderProtocol
    ) {
        self.userSession = userSession
        self.selfProfileUIBuilder = selfProfileUIBuilder
    }

    func build(mainCoordinator: AnyMainCoordinator) -> UINavigationController {
        let rootViewController = StartUIViewController(
            userSession: userSession,
            mainCoordinator: mainCoordinator,
            selfProfileUIBuilder: selfProfileUIBuilder
        )
        rootViewController.delegate = delegate
        rootViewController.conversationCreationControllerDelegate = conversationCreationControllerDelegate
        return .init(rootViewController: rootViewController)
    }
}
