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

/// Implements the delegate method `splitViewControllerSupportedInterfaceOrientations(_: UISplitViewController)`
/// and returns a value based on the intersection of all column's view controllers' supported interface orientations.
///
/// Note: For tablets with a `UIRequiresFullScreen` value of `false` the `UIViewControllers`' `supportedInterfaceOrientations`
/// property isn't read and therefore in this project this class is only relevant when running on phones.
public final class SupportedOrientationsDelegatingSplitViewControllerDelegate: UISplitViewControllerDelegate {

    public init() {}

    public func splitViewControllerSupportedInterfaceOrientations(
        _ splitViewController: UISplitViewController
    ) -> UIInterfaceOrientationMask {

        // This implementation is a quick-fix for the purpose of preventing some screens of
        // the app from rotating on phones. It's fragile and and might need to be revisited.

        guard splitViewController.viewController(for: .compact) == nil else {
            fatalError("This implementation does not support `.compact` columns. Extend it if needed.")
        }

        // form an intersection of the view controllers' supported interface orientations
        var supportedInterfaceOrientations = UIInterfaceOrientationMask.all
        for column in [UISplitViewController.Column.primary, .supplementary, .secondary] {
            if let viewController = splitViewController.viewController(for: column) {
                supportedInterfaceOrientations.formIntersection(viewController.supportedInterfaceOrientations)
            }
        }

        return supportedInterfaceOrientations
    }
}

// MARK: - Associated Object

public extension SupportedOrientationsDelegatingSplitViewControllerDelegate {

    /// By setting the instance as delegate and retained associated object we don't need to subclass the split view controller in order to achieve the desired behavior.
    func setAsDelegateAndNontomicRetainedAssociatedObject(_ splitViewController: UISplitViewController) {

        guard splitViewController.viewController(for: .compact) == nil else {
            fatalError("This implementation does not support `.compact` columns. Extend it if needed.")
        }

        splitViewController.delegate = self
        objc_setAssociatedObject(splitViewController, &associatedObjectKey, self, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

private nonisolated(unsafe) var associatedObjectKey = 0
