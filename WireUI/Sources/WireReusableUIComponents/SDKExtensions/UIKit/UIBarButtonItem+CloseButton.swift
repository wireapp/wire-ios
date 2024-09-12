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
import WireDesign // TODO: could we get rid of this dependency and move the code into WireFoundation?

public extension UIBarButtonItem {
    /// Creates a customized close button for use in navigation bars.
    ///
    /// This method creates a UIBarButtonItem configured as a close button with a custom image,
    /// tint color, and accessibility features.
    ///
    /// - Parameters:
    ///   - action: A UIAction to be performed when the button is tapped.
    ///   - accessibilityLabel: A string describing the button's purpose for accessibility.
    ///
    /// - Returns: A UIBarButtonItem configured as a close button.
    static func closeButton(action: UIAction, accessibilityLabel: String) -> UIBarButtonItem {
        let closeImage = UIImage(named: "Close")

        let closeItem = UIBarButtonItem(title: accessibilityLabel, primaryAction: action)

        closeItem.image = closeImage

        closeItem.style = .plain
        closeItem.tintColor = SemanticColors.Icon.foregroundDefaultBlack

        closeItem.accessibilityLabel = accessibilityLabel
        closeItem.accessibilityIdentifier = "close"

        return closeItem
    }
}
