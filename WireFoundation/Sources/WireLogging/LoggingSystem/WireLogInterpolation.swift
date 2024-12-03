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

/// This type's purpose is restricting the automatic conversion of custom types to String, in order to reduce the risk of leaking sensible information.
/// Each custom type which can be logged must define how it should appear in the logs.
/// Query the property `isDebugBuild` in order to know, if the value should be obfuscated or not.
public struct WireLogInterpolation: StringInterpolationProtocol {

    //private var logInterpolation: OSLogInterpolation
    // TODO: stack calls
    private var calls = [(any StringInterpolationProtocol) -> Void]()

#if DEBUG
    public let isDebugBuild = true
    #else
    public let isDebugBuild = false
    #endif

    public init(literalCapacity: Int, interpolationCount: Int) {
        //logInterpolation = .init(literalCapacity: literalCapacity, interpolationCount: interpolationCount)
        //calls += [{ $0.appendLiteral(<#T##literal: any StringInterpolationProtocol.StringLiteralType##any StringInterpolationProtocol.StringLiteralType#>) }]
    }

    public mutating func appendLiteral(_ literal: StaticString) {
        //logInterpolation.appendLiteral("\(literal)")
    }

    public mutating func appendInterpolation(_ value: Dummy) {
        fatalError("Shouldn't be called.")
    }

    /// A non-usable type for the `appendInterpolation` method in order to comply with the requirements of `StringInterpolationProtocol`.
    public enum Dummy {}
}

public struct OSLogLoggingSystem: WireLoggingSystem {

    let logger = os.Logger()

    public func log(tag: Tag, level: Level, message: WireLogMessage) {
        message
    }
}


extension WireLogInterpolation {

    mutating func appendInterpolation(_ conversation: ConversationModel, something: Int) {
        //if isDebugBuild
        //appendInterpolation(<#T##value: StaticString##StaticString#>)
        appendLiteral("Conversation(")
        //appendInterpolation("abcd \(3)")
    }
}

public struct ConversationModel {
    var id: Int
    var content: String
}

let xxx = WireLogger(tag: "dummy") { AggregatedLogger(loggingSystems: []) }
    .debug("sending ping in \( ConversationModel(id: 1, content: "Hello World"), something: 0 )")
//    .debug("abcd")
