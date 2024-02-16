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

    public func addLogger(_ logger: LoggerProtocol) {
        self.loggers.append(logger)
    }

    public func debug(_ message: LogConvertible, attributes: LogAttributes?) {
        loggers.forEach {
            $0.debug(message, attributes: attributes)
        }
    }

    public func info(_ message: LogConvertible, attributes: LogAttributes?) {
        loggers.forEach {
            $0.info(message, attributes: attributes)
        }
    }

    public func notice(_ message: LogConvertible, attributes: LogAttributes?) {
        loggers.forEach {
            $0.notice(message, attributes: attributes)
        }
    }

    public func warn(_ message: LogConvertible, attributes: LogAttributes?) {
        loggers.forEach {
            $0.warn(message, attributes: attributes)
        }
    }

    public func error(_ message: LogConvertible, attributes: LogAttributes?) {
        loggers.forEach {
            $0.error(message, attributes: attributes)
        }
    }

    public func critical(_ message: LogConvertible, attributes: LogAttributes?) {
        loggers.forEach {
            $0.critical(message, attributes: attributes)
        }
    }

    public func persist(fileDestination: FileLoggerDestination) async {
        for logger in loggers {
            await logger.persist(fileDestination: fileDestination)
        }
    }
}
