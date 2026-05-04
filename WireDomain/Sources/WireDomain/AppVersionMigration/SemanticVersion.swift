//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

public struct SemanticVersion: Sendable, Hashable, ExpressibleByStringLiteral {

    public let major: UInt
    public let minor: UInt
    public let patch: UInt

    public var string: String {
        "\(major).\(minor).\(patch)"
    }

    public init(stringLiteral value: String) {
        let components = value
            .split(separator: ".")
            .compactMap { UInt($0) }

        self.major = components.first ?? 0
        self.minor = components.dropFirst().first ?? 0
        self.patch = components.dropFirst(2).first ?? 0
    }

}

extension SemanticVersion: Comparable {

    public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        guard lhs.major == rhs.major else {
            // Major determines order.
            return lhs.major < rhs.major
        }

        guard lhs.minor == rhs.minor else {
            // Minor determines order.
            return lhs.minor < rhs.minor
        }

        // Patch determines order.
        return lhs.patch < rhs.patch
    }

}

extension SemanticVersion: CustomStringConvertible {

    public var description: String {
        string
    }

}
