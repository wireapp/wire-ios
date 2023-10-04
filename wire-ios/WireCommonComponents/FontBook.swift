//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

extension UIFont {

    public enum FontStyle {
        case title3
        case headline
        case body
        case subheadline
        case caption1
        case title3Bold
        case calloutBold
        case footnoteSemibold
        case bodyTwoSemibold
        case buttonSmallSemibold
        case buttonBigSemibold
    }

    public static func font(for style: FontStyle) -> UIFont {
        switch style {
        case .title3:
            return .preferredFont(forTextStyle: .title3)

        case .headline:
            return .preferredFont(forTextStyle: .headline)

        case .body:
            return .preferredFont(forTextStyle: .body)

        case .subheadline:
            return .preferredFont(forTextStyle: .subheadline)

        case .caption1:
            return .preferredFont(forTextStyle: .caption1)

        case .title3Bold:
            return .preferredFont(forTextStyle: .title3).withWeight(.bold)

        case .calloutBold:
            return .preferredFont(forTextStyle: .callout).withWeight(.bold)

        case .footnoteSemibold:
            return .preferredFont(forTextStyle: .footnote).withWeight(.semibold)

        case .bodyTwoSemibold:
            return preferredFont(forTextStyle: .body).withSize(16).withWeight(.semibold)

        case .buttonSmallSemibold:
            return  .systemFont(ofSize: 14, weight: .semibold)

        case .buttonBigSemibold:
            return  .preferredFont(forTextStyle: .title3).withWeight(.bold)
        }
    }

    /// Returns a new font with the weight specified
    ///
    /// - Parameter weight: The new font weight
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        var weightTraits: [UIFontDescriptor.TraitKey: Any] = [:]

        switch weight {
        case .ultraLight:
            weightTraits = [.weight: -0.8]
        case .thin:
            weightTraits = [.weight: -0.6]
        case .light:
            weightTraits = [.weight: -0.4]
        case .regular:
            weightTraits = [:]
        case .medium:
            weightTraits = [.weight: 0.23]
        case .semibold:
            weightTraits = [.weight: 0.3]
        case .bold:
            weightTraits = [.weight: 0.4]
        case .heavy:
            weightTraits = [.weight: 0.56]
        case .black:
            weightTraits = [.weight: 0.63]
        default:
            // Handle other weights or return nil if not supported
            break
        }

         let descriptor = fontDescriptor.addingAttributes([.traits: weightTraits])

        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
