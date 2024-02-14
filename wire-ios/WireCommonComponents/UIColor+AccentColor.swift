//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
import WireDataModel

public enum AccentColor: Int16, CaseIterable {

    case blue = 1
    case green
    case yellow // Deprecated
    case red
    case amber
    case turquoise
    case purple

    public static var `default`: Self { .blue }

    /// Returns a random accent color.
    public static var random: AccentColor {
        return AccentColor.allSelectable().randomElement()!
    }

    public init?(ZMAccentColor zmAccentColor: ZMAccentColor) {
        self.init(rawValue: zmAccentColor.rawValue)
    }

    public var zmAccentColor: ZMAccentColor {
        return ZMAccentColor(rawValue: rawValue)!
    }

    public static func allSelectable() -> [AccentColor] {
        return [.blue,
                .green,
                .red,
                .amber,
                .turquoise,
                .purple]
    }

}
