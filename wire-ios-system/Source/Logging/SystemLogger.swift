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

import Foundation
import OSLog

// MARK: - FileLoggerDestination

public protocol FileLoggerDestination {
    var log: URL? { get }
}

// MARK: - SystemLogger

struct SystemLogger: LoggerProtocol {
    // MARK: Internal

    let persistQueue = DispatchQueue(label: "persistQueue")

    var logFiles: [URL] {
        []
    }

    var lastReportTime: Date? {
        get {
            guard let interval = UserDefaults.standard.object(forKey: "com.wire.log.lastReportTime") as? TimeInterval
            else { return nil }
            return Date(timeIntervalSince1970: interval)
        }
        set {
            UserDefaults.standard.set(newValue?.timeIntervalSince1970, forKey: "com.wire.log.lastReportTime")
        }
    }

    func debug(_ message: any LogConvertible, attributes: LogAttributes...) {
        log(message, attributes: attributes, osLogType: .debug)
    }

    func info(_ message: any LogConvertible, attributes: LogAttributes...) {
        log(message, attributes: attributes, osLogType: .info)
    }

    func notice(_ message: any LogConvertible, attributes: LogAttributes...) {
        log(message, attributes: attributes, osLogType: .default)
    }

    func warn(_ message: any LogConvertible, attributes: LogAttributes...) {
        log(message, attributes: attributes, osLogType: .fault)
    }

    func error(_ message: any LogConvertible, attributes: LogAttributes...) {
        log(message, attributes: attributes, osLogType: .error)
    }

    func critical(_ message: any LogConvertible, attributes: LogAttributes...) {
        log(message, attributes: attributes, osLogType: .fault)
    }

    func addTag(_ key: LogAttributesKey, value: String?) {
        // do nothing, as it's only available on datadog
    }

    // MARK: Private

    private func log(_ message: LogConvertible, attributes: [LogAttributes], osLogType: OSLogType) {
        var mergedAttributes: LogAttributes = [:]
        for attribute in attributes {
            mergedAttributes.merge(attribute) { _, new in new }
        }

        var logger = OSLog.default
        if let tag = mergedAttributes[.tag] as? String {
            logger = loggers[tag] ?? OSLog(subsystem: Bundle.main.bundleIdentifier ?? "main", category: tag)
        }

        let message = "\(message.logDescription)\(attributesDescription(from: mergedAttributes))"

        if mergedAttributes[.public] as? Bool == true {
            os_log(osLogType, log: logger, "%{public}@", message)
        } else {
            os_log(osLogType, log: logger, "\(message)")
        }
    }
}

private var loggers: [String: OSLog] = [:]
