////
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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
import OSLog

struct SystemLogger: LoggerProtocol {
    func debug(_ message: LogConvertible, attributes: LogAttributes?) {
        log(message, attributes: attributes, osLogType: .debug)
    }

    func info(_ message: LogConvertible, attributes: LogAttributes?) {
        log(message, attributes: attributes, osLogType: .info)
    }

    func notice(_ message: LogConvertible, attributes: LogAttributes?) {
        log(message, attributes: attributes, osLogType: .default)
    }

    func warn(_ message: LogConvertible, attributes: LogAttributes?) {
        log(message, attributes: attributes, osLogType: .fault)
    }

    func error(_ message: LogConvertible, attributes: LogAttributes?) {
        log(message, attributes: attributes, osLogType: .error)
    }

    func critical(_ message: LogConvertible, attributes: LogAttributes?) {
        log(message, attributes: attributes, osLogType: .fault)
    }

    private func log(_ message: LogConvertible, attributes: LogAttributes?, osLogType: OSLogType) {
        var logger: OSLog = OSLog.default
        if let tag = attributes?["tag"] as? String {

            logger = loggers[tag] ?? OSLog(subsystem: Bundle.main.bundleIdentifier ?? "main", category: tag)
        }
        #if DEBUG
            os_log(osLogType, log: logger, "%{public}@", "\(message.logDescription)")
        #else
            os_log(osLogType, log: logger, "\(message.logDescription)")
        #endif
    }
}

private var loggers: [String: OSLog] = [:]
