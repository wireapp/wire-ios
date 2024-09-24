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

import SwiftUI

public extension Color {

    static let primaryViewBackground = Color(
        uiColor: UIColor(
            light: .gray20,
            dark: .gray100
        )
    )

    static let primaryText = Color(
        uiColor: UIColor(
            light: .black,
            dark: .white
        )
    )

    static let secondaryText = Color(
        uiColor: UIColor(
            light: .gray70,
            dark: .gray30
        )
    )

    static let primaryButtonBackground = Color(
        uiColor: UIColor(
            light: .blue500Light,
            dark: .blue500Dark
        )
    )

    static let primaryButtonText = Color(
        uiColor: UIColor(
            light: .white,
            dark: .black
        )
    )

    static let secondaryButtonBackground = Color(
        uiColor: UIColor(
            light: .white,
            dark: .gray95
        )
    )

    static let secondaryButtonBackgroundHighlighted = Color(
        uiColor: UIColor(
            light: .white,
            dark: .gray80
        )
    )
    
    static let secondaryButtonBorder = Color(
        uiColor: UIColor(
            light: .gray40,
            dark: .gray80
        )
    )

    static let secondaryButtonText = Color(
        uiColor: UIColor(
            light: .black,
            dark: .white
        )
    )
}

private extension UIColor {

    convenience init(light: ColorResource, dark: ColorResource) {
        self.init { traits in
            .init(resource: traits.userInterfaceStyle == .dark ? dark : light)
        }
    }
}
