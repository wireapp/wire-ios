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
/// Use `addText(_:)` and `addAttribute(_:)` to create the content to be logged.
public struct WireLogInterpolation: StringInterpolationProtocol {

    private(set) var content = ""
    private(set) var attributes = [WireLoggerAttribute]()

    #if DEBUG
    public let isDebugBuild = true
    #else
    public let isDebugBuild = false
    #endif

    public init(literalCapacity: Int, interpolationCount: Int) {}

    public mutating func appendLiteral(_ literal: StaticString) {
        writeText("\(literal)")
    }

    public mutating func appendInterpolation(_ literal: StaticString) {
        writeText("\(literal)")
    }

    /// Allows for adding additional tags to a log message.
    /// Depending on the logging system the attributes might for example be prepended in brackets or appended separately.
    public mutating func writeAttribute(_ attribute: WireLoggerAttribute) {
        attributes += [attribute]
    }

    // Adds text to the logged content. The provided value is not obfuscated.
    public mutating func writeText(_ text: String) {
        content += text
    }
}

public struct OSLogLoggingSystem: WireLoggingSystem {

    let logger = os.Logger()

    public func log(tag: Tag, level: Level, message: WireLogMessage) {
        let level = level.mappedToOSLogType()
        let attributes = message.interpolation.attributes.map { "[\($0)]" }
        let message = (attributes + [message.interpolation.content])
            .joined(separator: " ")
        logger.log(level: level, "\(message, privacy: .public)")

        // TODO: one os.Logger per tag
    }
}

extension WireLogLevel {

    func mappedToOSLogType() -> OSLogType {
        /*
         Note:
         - levels are `default`, `info`, `debug`, `error` and `fault`
         - `trace` is an alias for `debug`
         - `notice` is an alias for `default`
         - `warning` is an alias for `error`
         - `critical` is an alias for `fault`
         */

        switch self {
        case .debug:
                .debug
        case .info:
                .info
        case .notice:
                .default
        case .warn:
                .error
        case .error:
                .error
        case .critical:
                .fault
        }
    }
}


extension WireLogInterpolation {

    mutating func appendInterpolation(_ conversation: ConversationModel, something: Int) {
        if isDebugBuild {
            //
        } else {
            //
        }
        //writeAttribute()
    }
}

public struct ConversationModel {
    var id: Int
    var content: String
}

let xxx = WireLogger(tag: "dummy") { AggregatedLogger(loggingSystems: []) }
    .debug("sending ping in \( ConversationModel(id: 1, content: "Hello World"), something: 0 ) a \("abcd")")
//    .debug("abcd")



extension WireLogInterpolation {

    @available(*, deprecated, message: "Overload `WireLogInterpolation.appendInterpolation` instead.")
    mutating func appendInterpolation(_ uncheckedString: UncheckedString) {
//        if isDebugBuild {
//            //
//        } else {
//            //
//        }
    }
}

/// A type which is only used during migrating to the new logging.
public struct UncheckedString {

    let value: String

    public init(_ value: String) {
        self.value = value
    }
}
