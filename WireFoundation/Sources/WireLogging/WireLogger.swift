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

public protocol NewWireLogger {
    typealias Tag = WireLoggerTag
}

public protocol TaggedWireLogger {
    typealias Tag = WireLoggerTag

    var tags: [Tag] { get }
}

public struct WireLoggerTag: RawRepresentable {

    public var rawValue: StringLiteralType

    public init?(rawValue: StringLiteralType) {
        self.rawValue = rawValue

//        os.Logger().notice("abcd \("xyz", privacy: .public)")
//        os.Logger().
    }
}

//public struct WireLoggerInterpolation: ExpressibleByStringInterpolation {
//    public init(stringInterpolation: DefaultStringInterpolation) {
//    }
//}

struct MyStruct {
    let id: Int
    let name: String
}

// MARK: -

struct MyStringInterpolation: StringInterpolationProtocol {
    // Buffer to store the interpolated string content
    private var output: String = ""

    // Required initializer
    init(literalCapacity: Int, interpolationCount: Int) {
        output.reserveCapacity(literalCapacity + interpolationCount * 20)
    }

    // Required method for appending literal strings
    mutating func appendLiteral(_ literal: String) {
        output.append(literal)
    }

    // Custom interpolation method for `MyStruct`
    mutating func appendInterpolation(_ value: MyStruct) {
        output.append("MyStruct(id: \(value.id), name: \(value.name))")
    }

    // Expose the final result as a string
    func outputString() -> String {
        return output
    }
}

// MARK: -

struct MyString: ExpressibleByStringInterpolation {
    let valuee: String

    init(stringLiteral value: String) {
        self.valuee = value
    }

    init(stringInterpolation: MyStringInterpolation) {
        self.valuee = stringInterpolation.outputString()
    }
}

// MARK: -

func something() {
    let myStruct = MyStruct(id: 42, name: "Alice")
    let anotherStruct = MyStruct(id: 7, name: "Bob")

    let myString: MyString = "This is \(myStruct), and here is \(anotherStruct)."
    print(myString.valuee)
    // Output: This is MyStruct(id: 42, name: Alice), and here is MyStruct(id: 7, name: Bob).
}
