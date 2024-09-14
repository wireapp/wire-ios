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
import WireFoundation

extension UIFont {

    /// Creates a new font for the given style.
    ///
    /// - Parameter style: The desired text style.
    /// - Returns: A new font with the given text style.

    public static func font(for style: WireTextStyle) -> UIFont {
        switch style {
        case .largeTitle:
            return .preferredFont(forTextStyle: .largeTitle)

        case .h1:
            return .preferredFont(forTextStyle: .title3)

        case .h2:
            return .preferredFont(forTextStyle: .title3).withWeight(.bold)

        case .h3:
            return .preferredFont(forTextStyle: .headline)

        case .h4:
            return .preferredFont(forTextStyle: .subheadline)

        case .h5:
            return .preferredFont(forTextStyle: .footnote).withWeight(.semibold)

        case .body1:
            return .preferredFont(forTextStyle: .body)

        case .body2:
            let baseFont = UIFont.preferredFont(forTextStyle: .body).withSize(16)
            return UIFontMetrics.default.scaledFont(for: baseFont.withWeight(.semibold))

        case .body3:
            return .preferredFont(forTextStyle: .callout).withWeight(.bold)

        case .subline1:
            return .preferredFont(forTextStyle: .caption1)

        case .buttonSmall:
            let baseFont = UIFont.systemFont(ofSize: 14)
            return UIFontMetrics.default.scaledFont(for: baseFont.withWeight(.semibold))

        case .buttonBig:
            return .preferredFont(forTextStyle: .title3).withWeight(.bold)
        }
    }

    /// Create a new font with the specified weight.
    ///
    /// - Parameter weight: The desired font weight.
    /// - Returns: A new font with the specified weight.

    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        let weightTraits: [UIFontDescriptor.TraitKey: Any] = [.weight: weight.rawValue]
        let descriptor = fontDescriptor.addingAttributes([.traits: weightTraits])
        return UIFont(descriptor: descriptor, size: pointSize)
    }

}
