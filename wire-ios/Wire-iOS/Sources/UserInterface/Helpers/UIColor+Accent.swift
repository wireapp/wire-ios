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
import WireDesign
import WireFoundation
import WireSyncEngine

private var overridenAccentColor: AccentColor?

extension UIColor {

    class func indexedAccentColor() -> ZMAccentColor? {
        // priority 1: overriden color
        if overridenAccentColor != nil {
            return overridenAccentColor.map { .from(accentColor: $0) }
        }

        guard
            let activeUserSession = SessionManager.shared?.activeUserSession,
            AccentColor.allCases.map(\.rawValue).contains(activeUserSession.providedSelfUser.accentColorValue)
        else {
            // priority 3: default color
            return .default
        }

        // priority 2: color from self user
        return .from(rawValue: activeUserSession.providedSelfUser.accentColorValue)
    }

    /// Set override accent color. Can set to `nil` to remove override.
    ///
    /// - Parameter overrideColor: the override color
    class func setAccentOverride(_ overrideColor: ZMAccentColor?) {
        if overridenAccentColor == overrideColor?.accentColor {
            return
        }

        overridenAccentColor = overrideColor?.accentColor
    }

    static var accentDarken: UIColor {
        return accent().mix(.black, amount: 0.1).withAlphaComponent(0.32)
    }

    static var accentDimmedFlat: UIColor {
        if ColorScheme.default.variant == .light {
            return accent().withAlphaComponent(0.16).removeAlphaByBlending(with: .white)
        } else {
            return accentDarken
        }
    }

    class func accent() -> UIColor {
        (indexedAccentColor() ?? .default).accentColor.uiColor
    }

    class func lowAccentColor() -> UIColor {
        switch (indexedAccentColor() ?? .default).accentColor {
        case .blue:
            return SemanticColors.View.backgroundBlue
        case .red:
            return SemanticColors.View.backgroundRed
        case .green:
            return SemanticColors.View.backgroundGreen
        case .amber:
            return SemanticColors.View.backgroundAmber
        case .turquoise:
            return SemanticColors.View.backgroundTurqoise
        case .purple:
            return SemanticColors.View.backgroundPurple
        }
    }

    class func lowAccentColorForUsernameMention() -> UIColor {
        switch (indexedAccentColor() ?? .default).accentColor {
        case .blue:
            return SemanticColors.View.backgroundBlueUsernameMention
        case .red:
            return SemanticColors.View.backgroundRedUsernameMention
        case .green:
            return SemanticColors.View.backgroundGreenUsernameMention
        case .amber:
            return SemanticColors.View.backgroundAmberUsernameMention
        case .turquoise:
            return SemanticColors.View.backgroundTurqoiseUsernameMention
        case .purple:
            return SemanticColors.View.backgroundPurpleUsernameMention
        }
    }

    static func buttonEmptyText(variant: ColorSchemeVariant) -> UIColor {
        switch variant {
        case .dark:
            return .white
        case .light:
            return accent()
        }
    }
}
