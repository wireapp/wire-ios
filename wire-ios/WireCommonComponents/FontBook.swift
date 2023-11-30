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

//     Constants for weight values
//     Those values come directly from the system
//     DON"T MODIFY THOSE VALUES
//     You can verify those values by running:
//     let familyName = "SF Pro"
//     Define the font weights and their respective values
//        let fontWeights: [(weight: UIFont.Weight, name: String)] = [
//            (.ultraLight, "Ultra Light"),
//            (.thin, "Thin"),
//            (.light, "Light"),
//            (.regular, "Regular"),
//            (.medium, "Medium"),
//            (.semibold, "Semibold"),
//            (.bold, "Bold"),
//            (.heavy, "Heavy"),
//            (.black, "Black")
//        ]
//    
//        print("Font weights for \(familyName):")
//        for (weight, weightName) in fontWeights {
//            print("\(weight.rawValue): \(weightName)")
//        }
    private struct WeightValues {
        static let ultraLight: CGFloat = -0.8
        static let thin: CGFloat = -0.6
        static let light: CGFloat = -0.4
        static let regular: CGFloat = 0.0
        static let medium: CGFloat = 0.23
        static let semibold: CGFloat = 0.3
        static let bold: CGFloat = 0.4
        static let heavy: CGFloat = 0.56
        static let black: CGFloat = 0.62
    }

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
            let baseFont = UIFont.preferredFont(forTextStyle: .body).withSize(16)
            return UIFontMetrics.default.scaledFont(for: baseFont.withWeight(.semibold))

        case .buttonSmallSemibold:
            let baseFont = UIFont.systemFont(ofSize: 14)
            return UIFontMetrics.default.scaledFont(for: baseFont.withWeight(.semibold))

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
            weightTraits = [.weight: WeightValues.ultraLight]
        case .thin:
            weightTraits = [.weight: WeightValues.thin]
        case .light:
            weightTraits = [.weight: WeightValues.light]
        case .regular:
            weightTraits = [:]
        case .medium:
            weightTraits = [.weight: WeightValues.medium]
        case .semibold:
            weightTraits = [.weight: WeightValues.semibold]
        case .bold:
            weightTraits = [.weight: WeightValues.bold]
        case .heavy:
            weightTraits = [.weight: WeightValues.heavy]
        case .black:
            weightTraits = [.weight: WeightValues.black]
        default:
            // Handle other weights or return nil if not supported
            break
        }

        let descriptor = fontDescriptor.addingAttributes([.traits: weightTraits])

        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
