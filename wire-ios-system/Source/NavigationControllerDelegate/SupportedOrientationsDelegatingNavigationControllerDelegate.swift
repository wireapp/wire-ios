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

/// Implements the delegate method `navigationControllerSupportedInterfaceOrientations(_: UINavigationController)`
/// and returns the value of the top view controller's supported interface orientations.
public final class SupportedOrientationsDelegatingNavigationControllerDelegate: NSObject,
    UINavigationControllerDelegate {
    public func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController)
        -> UIInterfaceOrientationMask {
        navigationController.topViewController?.supportedInterfaceOrientations ?? .all
    }
}

// MARK: - Associated Object

extension SupportedOrientationsDelegatingNavigationControllerDelegate {
    /// By setting the instance as delegate and retained associated object we don't need to subclass the navigation
    /// controller in order to achieve the desired behavior.
    public func setAsDelegateAndNontomicRetainedAssociatedObject(_ navigationController: UINavigationController) {
        navigationController.delegate = self
        objc_setAssociatedObject(navigationController, &associatedObjectKey, self, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

private nonisolated(unsafe) var associatedObjectKey = 0
