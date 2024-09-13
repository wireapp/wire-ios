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

final class RotationAwareNavigationController: UINavigationController {
    override var shouldAutorotate: Bool {
        if let topController = viewControllers.last {
            topController.shouldAutorotate
        } else {
            super.shouldAutorotate
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if let topController = viewControllers.last {
            topController.supportedInterfaceOrientations
        } else {
            super.supportedInterfaceOrientations
        }
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        if let topController = viewControllers.last {
            topController.preferredInterfaceOrientationForPresentation
        } else {
            super.preferredInterfaceOrientationForPresentation
        }
    }

    override func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        viewControllers.forEach { $0.hideDefaultButtonTitle() }

        super.setViewControllers(viewControllers, animated: animated)
    }

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        viewController.hideDefaultButtonTitle()

        super.pushViewController(viewController, animated: animated)
    }

    // MARK: - status bar

    override var childForStatusBarStyle: UIViewController? {
        topViewController
    }

    override var childForStatusBarHidden: UIViewController? {
        topViewController
    }
}
