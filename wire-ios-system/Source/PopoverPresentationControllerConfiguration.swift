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

// MARK: - PopoverPresentationControllerConfiguration

/// Wraps the infos about how a popover should be presented.
public enum PopoverPresentationControllerConfiguration {
    case barButtonItem(_ barButtonItem: UIBarButtonItem)
    case sourceView(sourceView: UIView, sourceRect: CGRect)

    // MARK: Public

    // MARK: Static

    public static func sourceView(_ sourceView: UIView, _ sourceRect: CGRect) -> Self {
        .sourceView(sourceView: sourceView, sourceRect: sourceRect)
    }

    @MainActor
    public static func superviewAndFrame(
        of view: UIView,
        insetBy inset: (dx: CGFloat, dy: CGFloat) = (0, 0)
    ) -> Self! {
        guard let superview = view.superview else { return nil }
        return .sourceView(sourceView: superview, sourceRect: view.frame.insetBy(dx: inset.dx, dy: inset.dy))
    }
}

// MARK: - UIViewController + configurePopoverPresentationController

extension UIViewController {
    /// Sets the required properties for presenting the popover presentation controller, if it's non-`nil`.
    /// (`sourceView` and `sourceRect`, or `barButtonItem`)
    /// - Returns: `true` if the poover controller has been confiugured, `false` if `popoverPresentationController` is
    /// `nil`.
    @discardableResult
    public func configurePopoverPresentationController(
        using configuration: PopoverPresentationControllerConfiguration
    ) -> Bool {
        guard let popoverPresentationController else { return false }

        switch configuration {
        case let .barButtonItem(barButtonItem):
            popoverPresentationController.barButtonItem = barButtonItem

        case let .sourceView(sourceView, sourceRect):
            popoverPresentationController.sourceView = sourceView
            popoverPresentationController.sourceRect = sourceRect
        }

        return true
    }
}
