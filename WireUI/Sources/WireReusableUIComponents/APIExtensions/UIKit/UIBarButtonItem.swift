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

public extension UIBarButtonItem {
    /// Creates a bar button item for a navigation bar with a specified title and action.
    ///
    /// This method follows Apple's guidelines for bar button items, using a fixed font size.
    ///
    /// - Parameters:
    ///   - title: The text to display on the button.
    ///   - action: The action to perform when the button is tapped.
    ///
    /// - Returns: A configured `UIBarButtonItem` for use in a navigation bar.
    ///
    /// - Note: The font size is fixed at 17 points with a regular weight, adhering to Apple's
    ///         recommendations for bar button items. This ensures consistency across different
    ///         device sizes and accessibility settings.
    ///
    /// - Note: When the font size is large enough due to accessibility settings, the
    ///         LargeContentViewer is applied automatically by the system, enhancing
    ///         readability for users with visual impairments.
    private static func createNavigationBarButtonItem(
        title: String,
        action: UIAction
    ) -> UIBarButtonItem {
        let buttonFont = UIFont.systemFont(ofSize: 17, weight: .regular)

        let barButtonItem = UIBarButtonItem(
            title: title,
            primaryAction: action
        )

        let buttonStates: [UIControl.State] = [
            .normal,
            .highlighted,
            .disabled,
            .selected,
            .focused,
            .application,
            .reserved
        ]

        for buttonState in buttonStates {
            barButtonItem.setTitleTextAttributes(
                [
                    .font: buttonFont
                ],
                for: buttonState
            )
        }

        return barButtonItem
    }

    /// Creates a right bar button item for a navigation bar.
    static func createNavigationRightBarButtonItem(
        title: String,
        action: UIAction
    ) -> UIBarButtonItem {
        createNavigationBarButtonItem(title: title, action: action)
    }

    /// Creates a left bar button item for a navigation bar.
    static func createNavigationLeftBarButtonItem(
        title: String,
        action: UIAction
    ) -> UIBarButtonItem {
        createNavigationBarButtonItem(title: title, action: action)
    }
}
