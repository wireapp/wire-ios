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

/// Logger to write logs tro fileSystem via ZMSLog
public class LegacyLogger: LoggerProtocol {

    private var loggers = [String: ZMSLog]()

    subscript(tag: String) -> ZMSLog {
        if loggers[tag] == nil {
            loggers[tag] = ZMSLog(tag: tag)
        }
        return loggers[tag]!
    }

    public func debug(_ message: LogConvertible, attributes: LogAttributes?) {
        log(message, attributes: attributes, level: .debug)
    }

    public func info(_ message: LogConvertible, attributes: LogAttributes?) {
        log(message, attributes: attributes, level: .info)
    }

    public func notice(_ message: LogConvertible, attributes: LogAttributes?) {
        log(message, attributes: attributes, level: .warn)
    }

    public func warn(_ message: LogConvertible, attributes: LogAttributes?) {
        log(message, attributes: attributes, level: .warn)
    }

    public func error(_ message: LogConvertible, attributes: LogAttributes?) {
        log(message, attributes: attributes, level: .error)
    }

    public func critical(_ message: LogConvertible, attributes: LogAttributes?) {
        log(message, attributes: attributes, level: .error)
    }

    private func log(_ message: LogConvertible, attributes: LogAttributes?, level: ZMLogLevel_t) {
        let entry = SanitizedString(value: message.logDescription)

        if let tag = attributes?["tag"] as? String {

            self[tag].safePublic(entry, level: level, osLogOn: false)
        } else {
            self["legacy"].safePublic(entry, level: level, osLogOn: false)
        }
    }

    public func persist(fileDestination: FileLoggerDestination) async {
        // do nothing
    }
}
