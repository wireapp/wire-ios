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

import WireDataModel

extension AccentColor {

    var uiColor: UIColor {
        switch self {
        case .blue:
            UIColor(light: .blue500Light, dark: .blue500Dark)
        case .green:
            UIColor(light: .green500Light, dark: .green500Dark)
        case .red:
            UIColor(light: .red500Light, dark: .red500Dark)
        case .amber:
            UIColor(light: .amber500Light, dark: .amber500Dark)
        case .turquoise:
            UIColor(light: .turquoise500Light, dark: .turquoise500Dark)
        case .purple:
            UIColor(light: .purple500Light, dark: .purple500Dark)
        }
    }
}
