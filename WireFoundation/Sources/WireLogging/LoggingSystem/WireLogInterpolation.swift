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

    //private var logInterpolation: OSLogInterpolation
    // TODO: stack calls
    private var calls = [(any StringInterpolationProtocol) -> Void]()

    public init(literalCapacity: Int, interpolationCount: Int) {
        //logInterpolation = .init(literalCapacity: literalCapacity, interpolationCount: interpolationCount)
        //calls += [{ $0.appendLiteral(<#T##literal: any StringInterpolationProtocol.StringLiteralType##any StringInterpolationProtocol.StringLiteralType#>) }]
    }

    public mutating func appendLiteral(_ literal: StaticString) {
        //logInterpolation.appendLiteral("\(literal)")
    }

    public mutating func appendInterpolation(_ value: Int) {
        //logInterpolation.appendLiteral("\(value)")
    }
}

public struct OSLogLoggingSystem: WireLoggingSystem {

    let logger = os.Logger()

    public func log(tag: Tag, level: Level, message: WireLogMessage) {
        message
    }
}


extension WireLogInterpolation {

    mutating func appendInterpolation(_ conversation: ConversationModel, something: Int) {
        //appendInterpolation(<#T##value: StaticString##StaticString#>)
    }
}

public struct ConversationModel {
    var id: Int
    var content: String
}

let xxx = WireLogger(tag: "dummy") { [] }
//    .debug("sending ping in \( ConversationModel(id: 1, content: "Hello World"), something: 0 )")
    .debug("abcd \(4)")
