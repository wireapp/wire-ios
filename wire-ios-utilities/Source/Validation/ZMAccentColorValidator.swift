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

@objc public final class ZMAccentColorValidator: NSObject, ZMPropertyValidator {

    @objc(validateValue:error:)
    public static func validateValue(_ ioValue: AutoreleasingUnsafeMutablePointer<AnyObject?>!) throws {
        var pointee = ioValue.pointee as Any?
        defer { ioValue.pointee = pointee as AnyObject? }
        try validateValue(&pointee)
    }

    @discardableResult public static func validateValue(_ inoutValue: inout Any?) throws -> Bool {

        guard let value = inoutValue as? AccentColor.RawValue else { return true }

        let offset = Int16(arc4random_uniform(UInt32(ZMAccentColorMax - ZMAccentColorMin)))
        if value < ZMAccentColorMin || ZMAccentColorMax < value, let color = AccentColor(rawValue: ZMAccentColorMin + offset) {
            inoutValue = NSNumber(value: color.rawValue)
        }
        return true
    }
}
