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

public struct WireLogInterpolation: StringInterpolationProtocol {
    // Buffer to store the interpolated string content
    private var output: String = ""

    // Required initializer
    public init(literalCapacity: Int, interpolationCount: Int) {
        output.reserveCapacity(literalCapacity + interpolationCount * 20)
    }

    // Required method for appending literal strings
    public mutating func appendLiteral(_ literal: StaticString) {
        output.append("\(literal)")
    }

    // Custom interpolation method for `MyStruct`
    public mutating func appendInterpolation(_ value: MyStruct) {
        output.append("MyStruct(id: \(value.id), name: \(value.name))")
    }

    // Expose the final result as a string
    func outputString() -> String {
        return output
        os.Logger().log("abcd \(3)")
    }
}
