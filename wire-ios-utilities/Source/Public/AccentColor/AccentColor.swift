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

public enum AccentColor: Int16, CaseIterable, Hashable {
    case blue = 1
    case green
    // yellow used to be defined here
    case red = 4
    case amber
    case turquoise
    case purple
}

// MARK: - Default and random value

extension AccentColor {
    public static var `default`: Self { .blue }

    /// Returns a random accent color.
    public static var random: AccentColor {
        return AccentColor.allSelectable().randomElement()!
    }

    public init?(ZMAccentColor zmAccentColor: AccentColor) {
        self.init(rawValue: zmAccentColor.rawValue)
    }

    public var zmAccentColor: AccentColor {
        return AccentColor(rawValue: rawValue)!
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
