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
import WireCommonComponents
import WireDataModel
import WireSyncEngine

final class ConversationListTopBarViewController: UIViewController {

    private let account: Account

    /// Name, availability and verification info about the self user.
    var selfUserStatus = UserStatus()

    private let selfUser: SelfUserType
    private var userSession: UserSession
    private let selfProfileViewControllerBuilder: any ViewControllerBuilder

    let navigationItemToManage: () -> UINavigationItem?

    /// init a ConversationListTopBarViewController
    ///
    /// - Parameters:
    ///   - account: the Account of the user
    ///   - selfUser: the self user object. Allow to inject a mock self user for testing
    ///   - selfProfileViewControllerBuilder: a builder for the self profile view controller
    init(
        account: Account,
        selfUser: SelfUserType,
        userSession: UserSession,
        selfProfileViewControllerBuilder: some ViewControllerBuilder,
        navigationItemToManage: @escaping () -> UINavigationItem?
    ) {
        self.account = account
        self.selfUser = selfUser
        self.userSession = userSession
        self.selfProfileViewControllerBuilder = selfProfileViewControllerBuilder
        self.navigationItemToManage = navigationItemToManage

        super.init(nibName: nil, bundle: nil)

        viewRespectsSystemMinimumLayoutMargins = false
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ConversationListTopBarViewController: UIViewControllerTransitioningDelegate {

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SwizzleTransition(direction: .vertical)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SwizzleTransition(direction: .vertical)
    }
}
