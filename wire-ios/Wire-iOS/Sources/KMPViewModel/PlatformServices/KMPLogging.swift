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

enum KMPLogLevel: String, Equatable, Sendable {
    case trace
    case debug
    case info
    case warning
    case error
    case fault
}

struct KMPLogContext: Equatable, Sendable {

    let category: String
    let metadata: [String: String]

    init(
        category: String,
        metadata: [String: String] = [:]
    ) {
        self.category = category
        self.metadata = metadata
    }
}

protocol KMPLogging {
    func log(
        _ level: KMPLogLevel,
        _ message: @autoclosure () -> String,
        context: KMPLogContext,
        file: StaticString,
        function: StaticString,
        line: UInt
    )
}

extension KMPLogging {

    func trace(
        _ message: @autoclosure () -> String,
        context: KMPLogContext,
        file: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        log(.trace, message(), context: context, file: file, function: function, line: line)
    }

    func debug(
        _ message: @autoclosure () -> String,
        context: KMPLogContext,
        file: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        log(.debug, message(), context: context, file: file, function: function, line: line)
    }

    func info(
        _ message: @autoclosure () -> String,
        context: KMPLogContext,
        file: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        log(.info, message(), context: context, file: file, function: function, line: line)
    }

    func warning(
        _ message: @autoclosure () -> String,
        context: KMPLogContext,
        file: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        log(.warning, message(), context: context, file: file, function: function, line: line)
    }

    func error(
        _ message: @autoclosure () -> String,
        context: KMPLogContext,
        file: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        log(.error, message(), context: context, file: file, function: function, line: line)
    }

    func fault(
        _ message: @autoclosure () -> String,
        context: KMPLogContext,
        file: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        log(.fault, message(), context: context, file: file, function: function, line: line)
    }
}

struct AnyKMPLogger: KMPLogging {

    private let logMessage: (KMPLogLevel, String, KMPLogContext, StaticString, StaticString, UInt) -> Void

    init<Logger: KMPLogging>(_ logger: Logger) {
        self.logMessage = { level, message, context, file, function, line in
            logger.log(level, message, context: context, file: file, function: function, line: line)
        }
    }

    init(log: @escaping (KMPLogLevel, String, KMPLogContext, StaticString, StaticString, UInt) -> Void) {
        self.logMessage = log
    }

    func log(
        _ level: KMPLogLevel,
        _ message: @autoclosure () -> String,
        context: KMPLogContext,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) {
        logMessage(level, message(), context, file, function, line)
    }
}
