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
import WireCommonComponents
import WireUtilities

@objc
enum ColorSchemeVariant: UInt {
    case light, dark
}

extension UIColor {
    static var graphite = UIColor(rgb: (51, 55, 58))
    static var graphiteAlpha4 = UIColor(rgba: (51, 55, 58, 0.04))
    static var graphiteAlpha8 = UIColor(rgba: (51, 55, 58, 0.08))
    static var graphiteAlpha16 = UIColor(rgba: (51, 55, 58, 0.16))
    static var graphiteAlpha40 = UIColor(rgba: (51, 55, 58, 0.4))
    static var backgroundLightGraphite = UIColor(rgb: (30, 32, 33))
    static var lightGraphite = UIColor(rgb: (141, 152, 159))
    static var lightGraphiteAlpha8 = UIColor(rgba: (141, 152, 159, 0.08))
    static var lightGraphiteAlpha24 = UIColor(rgba: (141, 152, 159, 0.24))
    static var lightGraphiteAlpha48 = UIColor(rgba: (141, 152, 159, 0.48))
    static var lightGraphiteAlpha64 = UIColor(rgba: (141, 152, 159, 0.64))
    static var lightGraphiteWhite: UIColor = lightGraphiteAlpha8.removeAlphaByBlending(with: .white98)
    static var lightGraphiteDark: UIColor = lightGraphiteAlpha8.removeAlphaByBlending(with: .backgroundGraphite)
    static var graphiteDark = UIColor(rgb: (50, 54, 57))
    static var backgroundGraphite = UIColor(rgb: (22, 24, 25))
    static var backgroundGraphiteAlpha40 = UIColor(rgba: (22, 24, 25, 0.4))
    static var backgroundGraphiteAlpha12 = UIColor(rgba: (22, 24, 25, 0.12))
    static var white97 = UIColor(white: 0.97, alpha: 1)
    static var white98 = UIColor(white: 0.98, alpha: 1)
    static var whiteAlpha8 = UIColor(white: 1.0, alpha: 0.08)
    static var whiteAlpha16 = UIColor(white: 1.0, alpha: 0.16)
    static var whiteAlpha24 = UIColor(white: 1.0, alpha: 0.24)
    static var whiteAlpha40 = UIColor(white: 1.0, alpha: 0.4)
    static var whiteAlpha56 = UIColor(white: 1.0, alpha: 0.56)
    static var whiteAlpha64 = UIColor(white: 1.0, alpha: 0.64)
    static var whiteAlpha80 = UIColor(white: 1.0, alpha: 0.8)
    static var blackAlpha4 = UIColor(white: 0.0, alpha: 0.04)
    static var blackAlpha8 = UIColor(white: 0.0, alpha: 0.08)
    static var blackAlpha16 = UIColor(white: 0, alpha: 0.16)
    static var blackAlpha24 = UIColor(white: 0.0, alpha: 0.24)
    static var blackAlpha48 = UIColor(white: 0.0, alpha: 0.48)
    static var blackAlpha40 = UIColor(white: 0.0, alpha: 0.4)
    static var blackAlpha80 = UIColor(white: 0.0, alpha: 0.8)
    static var amberAlpha48 = UIColor(rgba: (254, 191, 2, 0.48))
    static var amberAlpha80 = UIColor(rgba: (254, 191, 2, 0.8))
}

enum ColorSchemeColor: Int {
    case textForeground
    case textBackground
    case textDimmed
    case textPlaceholder
    case textInBadge
    case iconNormal
    case iconSelected
    case iconHighlighted
    case iconBackgroundSelected
    case iconBackgroundSelectedNoAccent
    case iconShadow
    case iconHighlight
    case iconGuest
    case popUpButtonOverlayShadow
    case buttonHighlighted
    case buttonEmptyText
    case buttonFaded
    case tabNormal
    case tabSelected
    case tabHighlighted
    case background
    case contentBackground
    case barBackground
    case searchBarBackground
    case separator
    case cellSeparator
    case backgroundOverlay
    case backgroundOverlayWithoutPicture
    case placeholderBackground
    case avatarBorder
    case loadingDotActive
    case loadingDotInactive
    case paleSeparator
    case listAvatarInitials
    case audioButtonOverlay
    case sectionBackground
    case sectionBackgroundHighlighted
    case sectionText
    case tokenFieldBackground
    case tokenFieldTextPlaceHolder
    case selfMentionHighlight
    case cellHighlight
    case replyBorder
    case replyHighlight
    case secondaryAction
    case secondaryActionDimmed
    case errorIndicator
    case landingScreen
    case utilityError
    case utilityNeutral
    case utilitySuccess
    case textSecurityNotClassified
    case backgroundSecurityNotClassified
    case white

    fileprivate func colorPair(accentColor: UIColor) -> ColorPair {
        switch self {
        case .textForeground:
            ColorPair(light: .graphite, dark: .white)

        case .textBackground:
            ColorPair(light: .white, dark: .backgroundGraphite)

        case .textDimmed:
            ColorPair(both: .lightGraphite)

        case .textPlaceholder:
            ColorPair(both: .lightGraphiteAlpha64)

        case .textInBadge:
            ColorPair(both: .black)

        case .separator:
            ColorPair(light: .lightGraphiteAlpha48, dark: .lightGraphiteAlpha24)

        case .barBackground:
            ColorPair(light: .white, dark: .backgroundLightGraphite)

        case .background:
            ColorPair(light: .white, dark: .backgroundGraphite)

        case .contentBackground:
            ColorPair(light: .white97, dark: .backgroundGraphite)

        case .iconNormal:
            ColorPair(light: .graphite, dark: .white)

        case .iconSelected:
            ColorPair(light: .white, dark: .black)

        case .iconHighlighted:
            ColorPair(both: .white)

        case .iconShadow:
            ColorPair(light: .blackAlpha8, dark: .blackAlpha24)

        case .iconHighlight:
            ColorPair(light: .white, dark: .whiteAlpha16)

        case .iconBackgroundSelected:
            ColorPair(light: accentColor, dark: .white)

        case .iconBackgroundSelectedNoAccent:
            ColorPair(light: .graphite, dark: .white)

        case .popUpButtonOverlayShadow:
            ColorPair(light: .blackAlpha24, dark: .black)

        case .buttonHighlighted:
            ColorPair(light: .whiteAlpha24, dark: .blackAlpha24)

        case .buttonEmptyText:
            ColorPair(light: accentColor, dark: .white)

        case .buttonFaded:
            ColorPair(light: .graphiteAlpha40, dark: .whiteAlpha40)

        case .tabNormal:
            ColorPair(light: .blackAlpha48, dark: .whiteAlpha56)

        case .tabSelected:
            ColorPair(light: .graphite, dark: .white)

        case .tabHighlighted:
            ColorPair(light: .lightGraphite, dark: .lightGraphiteAlpha48)

        case .backgroundOverlay:
            ColorPair(light: .blackAlpha24, dark: .blackAlpha48)

        case .backgroundOverlayWithoutPicture:
            ColorPair(both: .blackAlpha80)

        case .avatarBorder:
            ColorPair(light: .blackAlpha8, dark: .whiteAlpha16)

        case .audioButtonOverlay:
            ColorPair(both: .lightGraphiteAlpha24)

        case .placeholderBackground:
            ColorPair(light: .lightGraphiteWhite, dark: .lightGraphiteDark)

        case .loadingDotActive:
            ColorPair(light: .graphiteAlpha40, dark: .whiteAlpha40)

        case .loadingDotInactive:
            ColorPair(light: .graphiteAlpha16, dark: .whiteAlpha16)

        case .paleSeparator:
            ColorPair(both: .lightGraphiteAlpha24)

        case .listAvatarInitials:
            ColorPair(both: .blackAlpha40)

        case .sectionBackground:
            ColorPair(both: .clear)

        case .sectionBackgroundHighlighted:
            ColorPair(light: .graphiteAlpha4, dark: .backgroundLightGraphite)

        case .sectionText:
            ColorPair(light: .blackAlpha40, dark: .whiteAlpha40)

        case .tokenFieldBackground:
            ColorPair(light: .blackAlpha4, dark: .whiteAlpha16)

        case .tokenFieldTextPlaceHolder:
            ColorPair(light: .lightGraphite, dark: .whiteAlpha40)

        case .cellSeparator:
            ColorPair(light: .graphiteAlpha8, dark: .whiteAlpha8)

        case .searchBarBackground:
            ColorPair(light: .white, dark: .whiteAlpha8)

        case .iconGuest:
            ColorPair(light: .backgroundGraphiteAlpha40, dark: .whiteAlpha64)

        case .selfMentionHighlight:
            ColorPair(light: .amberAlpha48, dark: .amberAlpha80)

        case .cellHighlight:
            ColorPair(light: .white97, dark: .whiteAlpha16)

        case .replyBorder:
            ColorPair(
                light: UIColor(white: 233.0 / 255.0, alpha: 1),
                dark: UIColor(white: 114.0 / 255.0, alpha: 1)
            )

        case .replyHighlight:
            ColorPair(
                light: UIColor(rgb: 0x33373A, alpha: 0.24),
                dark: UIColor(white: 1, alpha: 0.24)
            )

        case .secondaryAction:
            ColorPair(light: UIColor(rgb: 0xE8ECEE), dark: .backgroundLightGraphite)

        case .secondaryActionDimmed:
            ColorPair(
                light: UIColor(rgb: 0xE8ECEE, alpha: 0.24),
                dark: UIColor.backgroundLightGraphite.withAlphaComponent(0.24)
            )

        case .errorIndicator:
            ColorPair(light: UIColor(rgb: 0xE60606), dark: UIColor(rgb: 0xFC3E37))

        case .landingScreen:
            ColorPair(light: .graphiteDark, dark: .white)

        case .utilityError:
            ColorPair(light: UIColor(rgb: 0xE41734), dark: UIColor(rgb: 0xFC7887))

        case .utilityNeutral:
            ColorPair(light: UIColor(rgb: 0x0772DE), dark: UIColor(rgb: 0x26BDFF))

        case .utilitySuccess:
            ColorPair(light: UIColor(rgb: 0x148545), dark: UIColor(rgb: 0x35C763))

        case .textSecurityNotClassified:
            ColorPair(light: .white, dark: .graphite)

        case .backgroundSecurityNotClassified:
            ColorPair(light: .graphite, dark: .white)

        case .white:
            ColorPair(light: .white, dark: .white)
        }
    }
}

final class ColorScheme: NSObject {
    private(set) var colors: [AnyHashable: Any]?
    var variant: ColorSchemeVariant = .light
    private(set) var defaultColorScheme: ColorScheme?
    var accentColor: UIColor = .red

    static let `default` = ColorScheme()
    func color(named: ColorSchemeColor, variant: ColorSchemeVariant? = nil) -> UIColor {
        let colorSchemeVariant = variant ?? self.variant
        let colorPair = named.colorPair(accentColor: accentColor)
        switch colorSchemeVariant {
        case .dark:
            return colorPair.dark
        case .light:
            return colorPair.light
        }
    }
}

private struct ColorPair {
    let light: UIColor
    let dark: UIColor
}

extension ColorPair {
    fileprivate init(both color: UIColor) {
        self.init(light: color, dark: color)
    }
}

extension UIColor {
    static func from(scheme: ColorSchemeColor, variant: ColorSchemeVariant? = nil) -> UIColor {
        ColorScheme.default.color(named: scheme, variant: variant)
    }
}
