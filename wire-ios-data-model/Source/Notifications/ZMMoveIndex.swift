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

@objcMembers
public class ZMMovedIndex: NSObject {
    // MARK: Lifecycle

    public init(from: UInt, to: UInt) {
        self.from = from
        self.to = to
        super.init()
    }

    // MARK: Public

    public let from: UInt
    public let to: UInt

    /// - seealso: https://en.wikipedia.org/wiki/Pairing_function#Cantor_pairing_function
    override public var hash: Int {
        Int(((from + to) * (from + to + 1) / 2) + to)
    }

    override public func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? ZMMovedIndex else { return false }
        return other.from == from && other.to == to
    }
}
