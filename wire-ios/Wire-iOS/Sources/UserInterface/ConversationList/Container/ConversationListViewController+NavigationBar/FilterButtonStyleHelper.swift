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
import WireDesign

struct FilterButtonStyleHelper {

    /// Makes the action image based on the image name and selection state.
    ///
    /// - Parameters:
    ///   - imageName: The name of the image.
    ///   - isSelected: A boolean indicating whether the filter is currently selected.
    /// - Returns: A configured `UIImage`.
    static func makeActionImage(named imageName: String, isSelected: Bool) -> UIImage? {
        let font = UIFont.systemFont(ofSize: 17)
        let configuration = UIImage.SymbolConfiguration(font: font)
        let actionImage = UIImage(systemName: imageName)?.applyingSymbolConfiguration(configuration)

        // Apply the tint color conditionally based on the selection state
        if isSelected {
            return actionImage?.withTintColor(UIColor.accent(), renderingMode: .alwaysOriginal)
        } else {
            return actionImage
        }
    }

    /// Makes the attributed title based on the title and selection state.
    ///
    /// - Parameters:
    ///   - title: The title of the action.
    ///   - isSelected: A boolean indicating whether the filter is currently selected.
    /// - Returns: A configured `NSAttributedString`.
    static func makeAttributedTitle(for title: String, isSelected: Bool) -> NSAttributedString {
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: isSelected ? UIColor.accent() : SemanticColors.Label.textDefault
        ]
        return NSAttributedString(string: title, attributes: titleAttributes)
    }

}
