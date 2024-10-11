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

final class ProfilePresenter: NSObject, ViewControllerDismisser {

    var profileOpenedFromPeoplePicker = false
    var keyboardPersistedAfterOpeningProfile = false

    let mainCoordinator: AnyMainCoordinator<MainCoordinatorDependencies>
    private var presentedFrame: CGRect = .zero
    private weak var viewToPresentOn: UIView?
    private weak var controllerToPresentOn: UIViewController?
    private var onDismiss: (() -> Void)?

    init(mainCoordinator: AnyMainCoordinator<MainCoordinatorDependencies>) {
        self.mainCoordinator = mainCoordinator
        super.init()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(deviceOrientationChanged),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
    }

    @objc
    func deviceOrientationChanged(_ notification: Notification?) {
        guard
            let controllerToPresentOn,
            controllerToPresentOn.isIPadRegular()
        else { return }

        ZClientViewController.shared?.transitionToList(animated: false, completion: nil)

        guard
            viewToPresentOn != nil,
            let presentedViewController = controllerToPresentOn.presentedViewController
        else { return }

        presentedViewController.popoverPresentationController?.sourceRect = presentedFrame
        presentedViewController.preferredContentSize = presentedViewController.view.frame.insetBy(dx: -0.01, dy: 0.0).size
    }

    func presentProfileViewController(
        for user: UserType,
        in controller: UIViewController?,
        from rect: CGRect,
        userSession: UserSession,
        onDismiss: @escaping () -> Void
    ) {
        guard let viewer = SelfUser.provider?.providedSelfUser else {
            assertionFailure("expected available 'user'!")
            return
        }

        profileOpenedFromPeoplePicker = true
        viewToPresentOn = controller?.view
        controllerToPresentOn = controller
        presentedFrame = rect

        self.onDismiss = onDismiss

        let profileViewController = ProfileViewController(
            user: user,
            viewer: viewer,
            context: .search,
            userSession: userSession,
            mainCoordinator: mainCoordinator
        )
        profileViewController.delegate = self
        profileViewController.viewControllerDismisser = self

        let navigationController = profileViewController.wrapInNavigationController()
        navigationController.modalPresentationStyle = .formSheet

        controllerToPresentOn?.present(navigationController, animated: true)
    }

    func dismiss(viewController: UIViewController, completion: (() -> Void)? = nil) {
        viewController.dismiss(animated: true) {
            completion?()
            self.onDismiss?()
            self.controllerToPresentOn = nil
            self.viewToPresentOn = nil
            self.presentedFrame = .zero
            self.onDismiss = nil
        }
    }
}
