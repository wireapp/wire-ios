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

import os

/// This type's purpose is controlling the interface to an `OSLogInterpolation`.
/// Each custom type should define how it should appear in the logs.
public struct WireLogInterpolation: StringInterpolationProtocol {

    private var logInterpolation: OSLogInterpolation

    // Required initializer
    public init(literalCapacity: Int, interpolationCount: Int) {
        logInterpolation = .init(literalCapacity: literalCapacity, interpolationCount: interpolationCount)
    }

    // Required method for appending literal strings
    public mutating func appendLiteral(_ literal: StaticString) {
        logInterpolation.appendLiteral("\(literal)")
    }

    // Custom interpolation method for `MyStruct`
    public mutating func appendInterpolation(_ value: StaticString) {
        logInterpolation.appendLiteral("\(value)")
    }
}
