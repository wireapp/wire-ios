//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import os

public class SystemLogger: LoggerProtocol {

    let persistQueue = DispatchQueue(label: "persistQueue")
    private var tags = [LogAttributesKey: String]()

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

    public init() {}

    public func debug(_ message: any LogConvertible, attributes: LogAttributes...) {
        log(message, attributes: attributes, osLogType: .debug)
    }

    public func info(_ message: any LogConvertible, attributes: LogAttributes...) {
        log(message, attributes: attributes, osLogType: .info)
    }

    public func notice(_ message: any LogConvertible, attributes: LogAttributes...) {
        log(message, attributes: attributes, osLogType: .default)
    }

    public func warn(_ message: any LogConvertible, attributes: LogAttributes...) {
        log(message, attributes: attributes, osLogType: .default)
    }

    public func error(_ message: any LogConvertible, attributes: LogAttributes...) {
        log(message, attributes: attributes, osLogType: .error)
    }

    public func critical(_ message: any LogConvertible, attributes: LogAttributes...) {
        log(message, attributes: attributes, osLogType: .fault)
    }

    public func addTag(_ key: LogAttributesKey, value: String?) {
        if let value {
            tags[key] = value
        } else {
            tags.removeValue(forKey: key)
        }
    }

    private func log(_ message: any LogConvertible, attributes: [LogAttributes], osLogType: OSLogType) {
        var mergedAttributes: LogAttributes = [:]
        attributes.forEach {
            mergedAttributes.merge($0) { _, new in new }
        }

        var logger = OSLog.default
        if let tag = mergedAttributes[.tag] as? String {
            logger = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "main", category: tag)
        }

        var finalMessage = "\(message.logDescription)\(attributesDescription(from: mergedAttributes))"
        #if DEBUG
            os_log(osLogType, log: logger, "%{public}@", finalMessage)
        #else
            os_log(osLogType, log: logger, "\(finalMessage)")
        #endif
    }
}
