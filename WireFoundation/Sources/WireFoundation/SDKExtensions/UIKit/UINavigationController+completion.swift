//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

public import UIKit

public extension UINavigationController {

    // MARK: - setViewControllers

    func setViewControllers(
        _ viewControllers: [UIViewController],
        animated: Bool,
        completion: @escaping () -> Void
    ) {
        setViewControllers(viewControllers, animated: animated)

        guard animated, let coordinator = transitionCoordinator else {
            return DispatchQueue.main.async { completion() }
        }

        coordinator.animate(alongsideTransition: nil) { _ in completion() }
    }

    // MARK: - pushViewController

    func pushViewController(
        _ viewController: UIViewController,
        animated: Bool,
        completion: @escaping () -> Void
    ) {
        pushViewController(viewController, animated: animated)

        guard animated, let coordinator = transitionCoordinator else {
            return DispatchQueue.main.async { completion() }
        }

        coordinator.animate(alongsideTransition: nil) { _ in completion() }
    }

    // MARK: - popViewController

    func popViewController(
        animated: Bool,
        completion: @escaping () -> Void
    ) {
        popViewController(animated: animated)

        guard animated, let coordinator = transitionCoordinator else {
            return DispatchQueue.main.async { completion() }
        }

        coordinator.animate(alongsideTransition: nil) { _ in completion() }
    }

    // MARK: - popToRootViewController

    func popToRootViewController(animated: Bool, completion: @escaping () -> Void) {
        popToRootViewController(animated: animated)

        guard animated, let coordinator = transitionCoordinator else {
            return DispatchQueue.main.async { completion() }
        }

        coordinator.animate(alongsideTransition: nil) { _ in completion() }
    }
}
