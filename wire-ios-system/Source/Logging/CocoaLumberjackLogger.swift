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

    private let fileLogger: DDFileLogger = DDFileLogger() // File Logger

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
        attributes.forEach {
            mergedAttributes.merge($0) { _, new in new }
        }

        // TODO: [WPB-6432] enable when ZMSLog is cleaned up
        /* let isSafe = mergedAttributes[.public] as? Bool == true
        guard isDebug || isSafe else {
            // skips logs in production builds with non redacted info
            return
        }*/

        var entry = "[\(formattedLevel(level))] \(message.logDescription)\(attributesDescription(from: mergedAttributes))"

        if let tag = mergedAttributes[.tag] as? String {
            entry = "[\(tag)] - \(entry)"
        }

        let formatedMessage = DDLogMessage(DDLogMessageFormat(stringLiteral: entry), level: level, flag: .from(level))
        DDLog.log(asynchronous: true, message: formatedMessage)
    }

    public func addTag(_ key: LogAttributesKey, value: String?) {
        // do nothing
    }

    private func formattedLevel(_ level: DDLogLevel) -> String {
        switch level {
        case .error:
            "ERROR"
        case .warning:
            "WARN"
        case .info:
            "INFO"
        case .debug:
            "DEBUG"
        default:
            "VERBOSE"
        }
    }

    private var isDebug: Bool {
        #if DEBUG
            return true
        #else
            return false
        #endif
    }
}
