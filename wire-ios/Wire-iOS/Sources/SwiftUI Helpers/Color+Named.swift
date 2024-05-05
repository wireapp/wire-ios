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

import Foundation
import SwiftUI

extension Color {

    static let primaryText = Color(uiColor: UIColor(
            light: Asset.Colors.black,
            dark: Asset.Colors.white
        )
    )

    static let secondaryText = Color(uiColor: UIColor(
            light: Asset.Colors.gray70,
            dark: Asset.Colors.gray30
        )
    )

    static let primaryButtonBackground = Color(uiColor: UIColor(
            light: Asset.Colors.blue500Light,
            dark: Asset.Colors.blue500Dark
        )
    )

    static let primaryButtonText = Color(uiColor: UIColor(
            light: Asset.Colors.white,
            dark: Asset.Colors.black
        )
    )

    static let secondaryButtonBackground = Color(uiColor: UIColor(
            light: Asset.Colors.white,
            dark: Asset.Colors.gray95
        )
    )

    static let secondaryButtonBorder = Color(uiColor: UIColor(
            light: Asset.Colors.gray40,
            dark: Asset.Colors.gray80
        )
    )

    static let secondaryButtonText = Color(uiColor: UIColor(
            light: Asset.Colors.black,
            dark: Asset.Colors.white
        )
    )

}
