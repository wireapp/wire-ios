//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireDesign

enum FilterButtonStyleHelper {

    /// Makes the action image based on the image name and selection state.
    ///
    /// - Parameters:
    ///   - imageName: The name of the image.
    ///   - isSelected: A boolean indicating whether the filter is currently selected.
    /// - Returns: A configured `UIImage`.
    static func makeActionImage(named imageName: String, isSelected: Bool) -> UIImage? {
        // Handle custom unread badge icon
        if imageName == "customUnreadBadge" {
            return createUnreadFilterIcon(isSelected: isSelected)
        }

        let configuration = UIImage.SymbolConfiguration(font: .systemFont(ofSize: 17))
        let actionImage = UIImage(systemName: imageName, withConfiguration: configuration)

        // Apply the tint color conditionally based on the selection state
        if isSelected {
            return actionImage?.withTintColor(UIColor.accent(), renderingMode: .alwaysOriginal)
        } else {
            return actionImage
        }
    }

    /// Creates a custom unread filter icon that shows a badge with "1" inside.
    /// This matches the RoundedBadge appearance from ConversationListAccessoryView.
    ///
    /// - Parameter isSelected: Whether the filter is currently selected.
    /// - Returns: A custom UIImage showing a badge with "1".
    private static func createUnreadFilterIcon(isSelected: Bool) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 24))
        return renderer.image { _ in
            // Draw the badge background
            let badgeRect = CGRect(x: 2, y: 2, width: 20, height: 20)
            let path = UIBezierPath(roundedRect: badgeRect, cornerRadius: 10)

            if isSelected {
                UIColor.accent().setFill()
                path.fill()
            } else {
                SemanticColors.Label.textDefault.setStroke()
                path.lineWidth = 1.5
                path.stroke()
            }

            // Draw the "1" text inside
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.mediumSemiboldFont.withSize(12),
                .foregroundColor: isSelected ? UIColor.white : SemanticColors.Label.textDefault,
                .paragraphStyle: paragraphStyle
            ]

            let text = "1"
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (24 - textSize.width) / 2,
                y: (24 - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )

            text.draw(in: textRect, withAttributes: attributes)
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
