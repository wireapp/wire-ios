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

public protocol WireLoggingSystem {

    typealias Tag = WireLoggerTag
    typealias Level = WireLogLevel

    func log(tag: Tag, level: Level, message: WireLogInterpolation)
}
// DatadogLogger: WireLoggingSystem (different target, like WireAnalytics)
// OSLog: WireLoggingSystem
// ...

struct AggregatedLogger: WireLoggingSystem {

    var loggingSystems: () -> [any WireLoggingSystem]

    init(loggingSystems: @escaping @autoclosure () -> [any WireLoggingSystem]) {
        self.loggingSystems = loggingSystems
    }

    func log(tag: Tag, level: Level, message: WireLogInterpolation) {
        loggingSystems().forEach { loggingSystem in
            loggingSystem.log(tag: tag, level: level, message: message)
        }
    }
}

/// Convenience interface to the Wire logging systems.
public struct WireLogger {
    public typealias Tag = WireLoggerTag
    private typealias Level = WireLogLevel

    public var tag: Tag
    private var loggingSystem: () -> any WireLoggingSystem

    public init(
        _ tag: Tag,
        _ loggingSystem: @escaping  () -> any WireLoggingSystem
    ) {
        self.tag = tag
        self.loggingSystem = loggingSystem
    }

    public func debug(_ message: WireLogInterpolation) {
        log(.debug, message)
    }

    public func info(_ message: WireLogInterpolation) {
        log(.info, message)
    }

    public func notice(_ message: WireLogInterpolation) {
        log(.notice, message)
    }

    public func warn(_ message: WireLogInterpolation) {
        log(.warn, message)
    }

    public func error(_ message: WireLogInterpolation) {
        log(.error, message)
    }

    public func critical(_ message: WireLogInterpolation) {
        log(.critical, message)
    }

    private func log(_ level: Level, _ message: WireLogInterpolation) {
        loggingSystem()
            .log(tag: tag, level: level, message: message)
    }
}

extension WireLogger {

//    static var loggingSystems = [any WireLoggingSystem]()
//
//    static var network = TaggedWireLogger(tag: .init(rawValue: "network"))
}

public struct WireLoggerTag: ExpressibleByStringLiteral, RawRepresentable {

    public var rawValue: StringLiteralType

    public init(stringLiteral rawValue: StringLiteralType) {
        self.rawValue = rawValue
    }

    public init?(rawValue: StringLiteralType) {
        self.rawValue = rawValue
    }
}






// public struct WireLoggerInterpolation: ExpressibleByStringInterpolation {
//    public init(stringInterpolation: DefaultStringInterpolation) {
//    }
// }

public struct MyStruct {
    public let id: Int
    public let name: String
    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}

// MARK: -

public struct WireLogInterpolation: StringInterpolationProtocol {
    // Buffer to store the interpolated string content
    private var output: String = ""

    // Required initializer
    public init(literalCapacity: Int, interpolationCount: Int) {
        output.reserveCapacity(literalCapacity + interpolationCount * 20)
    }

    // Required method for appending literal strings
    public mutating func appendLiteral(_ literal: String) {
        output.append(literal)
    }

    // Custom interpolation method for `MyStruct`
    public mutating func appendInterpolation(_ value: MyStruct) {
        output.append("MyStruct(id: \(value.id), name: \(value.name))")
    }

    // Expose the final result as a string
    func outputString() -> String {
        return output
    }
}

// MARK: -

public struct WireLogMessage: ExpressibleByStringInterpolation {
    let valuee: String

    public init(stringLiteral value: String) {
        self.valuee = value
    }

    public init(stringInterpolation: WireLogInterpolation) {
        self.valuee = stringInterpolation.outputString()
    }
}

// MARK: -

func something() {
    let myStruct = MyStruct(id: 42, name: "Alice")
    let anotherStruct = MyStruct(id: 7, name: "Bob")

    let myString: WireLogMessage = "This is \(myStruct), and here is \(anotherStruct)."
    print(myString.valuee)
    // Output: This is MyStruct(id: 42, name: Alice), and here is MyStruct(id: 7, name: Bob).
}

/*
 - injectable logger (protocol)
 - interpolation with strict types (stringinterpolation should trigger warning or error)
 - force public flag
 - check the current attributes
 - additional info
 - ?
 */
