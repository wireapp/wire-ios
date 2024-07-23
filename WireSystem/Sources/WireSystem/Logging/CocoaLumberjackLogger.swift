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

import CocoaLumberjackSwift
import Foundation

/// Logger to write logs to fileSystem via CocoaLumberjack
final class CocoaLumberjackLogger: LoggerProtocol {

    private let fileLogger: DDFileLogger = .init() // File Logger

    init() {
        fileLogger.rollingFrequency = 60 * 60 * 24 // 24 hours
        fileLogger.maximumFileSize = 100_000_000 // 100Mb
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7
        DDLog.add(fileLogger)
    }

    var logFiles: [URL] {
        fileLogger.logFileManager.unsortedLogFilePaths.map { URL(fileURLWithPath: $0) }
    }

    func debug(_ message: LogConvertible, attributes: LogAttributes...) {
        log(message, attributes: attributes, level: .debug)
    }

    func info(_ message: LogConvertible, attributes: LogAttributes...) {
        log(message, attributes: attributes, level: .info)
    }

    func notice(_ message: LogConvertible, attributes: LogAttributes...) {
        log(message, attributes: attributes, level: .info)
    }

    func warn(_ message: LogConvertible, attributes: LogAttributes...) {
        log(message, attributes: attributes, level: .warning)
    }

    func error(_ message: LogConvertible, attributes: LogAttributes...) {
        log(message, attributes: attributes, level: .error)
    }

    func critical(_ message: LogConvertible, attributes: LogAttributes...) {
        log(message, attributes: attributes, level: .error)
    }

    private func log(_ message: LogConvertible, attributes: [LogAttributes], level: DDLogLevel) {
        var mergedAttributes: LogAttributes = [:]
        for attribute in attributes {
            mergedAttributes.merge(attribute) { _, new in new }
        }

        var entry = "\(message.logDescription)\(attributesDescription(from: attributes))"

        if let tag = mergedAttributes[.tag] as? String {
            entry = "[\(tag)] - \(entry)"
        }

        let formatedMessage = DDLogMessage(DDLogMessageFormat(stringLiteral: entry), level: level, flag: .from(level))
        DDLog.log(asynchronous: true, message: formatedMessage)
    }

    public func addTag(_ key: LogAttributesKey, value: String?) {
        // do nothing
    }
}
