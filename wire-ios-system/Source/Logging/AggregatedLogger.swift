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

public class AggregatedLogger: LoggerProtocol {
    private var loggers: [LoggerProtocol] = []

    init(loggers: [LoggerProtocol]) {
        self.loggers = loggers
    }

    public var logFiles: [URL] {
        return loggers.reduce(into: [], { $0 += $1.logFiles })
    }

    public func addLogger(_ logger: LoggerProtocol) {
        self.loggers.append(logger)
    }

    public func debug(_ message: any LogConvertible, attributes: LogAttributes...) {
        let mergedAttributes = flattenArray(attributes)
        loggers.forEach {
            $0.debug(message, attributes: mergedAttributes)
        }
    }

    public func info(_ message: any LogConvertible, attributes: LogAttributes...) {
        let mergedAttributes = flattenArray(attributes)
        loggers.forEach {
            $0.info(message, attributes: mergedAttributes)
        }
    }

    public func notice(_ message: any LogConvertible, attributes: LogAttributes...) {
        let mergedAttributes = flattenArray(attributes)
        loggers.forEach {
            $0.notice(message, attributes: mergedAttributes)
        }
    }

    public func warn(_ message: any LogConvertible, attributes: LogAttributes...) {
        let mergedAttributes = flattenArray(attributes)
        loggers.forEach {
            $0.warn(message, attributes: mergedAttributes)
        }
    }

    public func error(_ message: any LogConvertible, attributes: LogAttributes...) {
        let mergedAttributes = flattenArray(attributes)
        loggers.forEach {
            $0.error(message, attributes: mergedAttributes)
        }
    }

    public func critical(_ message: any LogConvertible, attributes: LogAttributes...) {
        let mergedAttributes = flattenArray(attributes)
        loggers.forEach {
            $0.critical(message, attributes: mergedAttributes)
        }
    }

    public func addTag(_ key: LogAttributesKey, value: String?) {
        loggers.forEach {
            $0.addTag(key, value: value)
        }
    }
}
