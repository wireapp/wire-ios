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
import WireFoundation

/// A type which only exists because optional `AccentColor?` cannot be represented in Objective C.
@objc(ZMAccentColor) @objcMembers
public final class ZMAccentColor: NSObject {

    // MARK: Objective C bridging

    public static var blue: ZMAccentColor { .from(accentColor: .blue) }
    public static var green: ZMAccentColor { .from(accentColor: .green) }
    public static var red: ZMAccentColor { .from(accentColor: .red) }
    public static var amber: ZMAccentColor { .from(accentColor: .amber) }
    public static var turquoise: ZMAccentColor { .from(accentColor: .turquoise) }
    public static var purple: ZMAccentColor { .from(accentColor: .purple) }

    // MARK: Helpers

    public static var `default`: ZMAccentColor { .from(accentColor: .default) }
    public static var min: ZMAccentColor { .blue }
    public static var max: ZMAccentColor { .purple }

    /// Singleton instances
    private static let mapping = {
        var mapping = [AccentColor: ZMAccentColor]()
        for accentColor in AccentColor.allCases {
            mapping[accentColor] = .init(accentColor: accentColor)
        }
        return mapping
    }()

    // MARK: -

    public let accentColor: AccentColor
    public var rawValue: ZMAccentColorRawValue { accentColor.rawValue }

    private init(accentColor: AccentColor) {
        self.accentColor = accentColor
    }

    public static func from(rawValue: ZMAccentColorRawValue) -> ZMAccentColor? {
        guard let accentColor = AccentColor(rawValue: rawValue) else { return nil }
        return ZMAccentColor.mapping[accentColor]!
    }

    public static func from(accentColor: AccentColor) -> ZMAccentColor {
        mapping[accentColor]!
    }

    public override var debugDescription: String {
        .init(reflecting: accentColor)
    }
}
