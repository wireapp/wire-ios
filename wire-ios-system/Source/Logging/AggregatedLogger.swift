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

final class AggregatedLogger: LoggerProtocol {
    // MARK: Lifecycle

    init(loggers: [any LoggerProtocol]) {
        self.loggers = loggers
    }

    // MARK: Internal

    // MARK: - LoggerProtocol

    var logFiles: [URL] {
        loggers.reduce(into: []) { $0 += $1.logFiles }
    }

    func addLogger(_ logger: any LoggerProtocol) {
        loggers.append(logger)
    }

    func debug(_ message: any LogConvertible, attributes: LogAttributes...) {
        let mergedAttributes = flattenArray(attributes)
        for logger in loggers {
            logger.debug(message, attributes: mergedAttributes)
        }
    }

    func info(_ message: any LogConvertible, attributes: LogAttributes...) {
        let mergedAttributes = flattenArray(attributes)
        for logger in loggers {
            logger.info(message, attributes: mergedAttributes)
        }
    }

    func notice(_ message: any LogConvertible, attributes: LogAttributes...) {
        let mergedAttributes = flattenArray(attributes)
        for logger in loggers {
            logger.notice(message, attributes: mergedAttributes)
        }
    }

    func warn(_ message: any LogConvertible, attributes: LogAttributes...) {
        let mergedAttributes = flattenArray(attributes)
        for logger in loggers {
            logger.warn(message, attributes: mergedAttributes)
        }
    }

    func error(_ message: any LogConvertible, attributes: LogAttributes...) {
        let mergedAttributes = flattenArray(attributes)
        for logger in loggers {
            logger.error(message, attributes: mergedAttributes)
        }
    }

    func critical(_ message: any LogConvertible, attributes: LogAttributes...) {
        let mergedAttributes = flattenArray(attributes)
        for logger in loggers {
            logger.critical(message, attributes: mergedAttributes)
        }
    }

    func addTag(_ key: LogAttributesKey, value: String?) {
        for logger in loggers {
            logger.addTag(key, value: value)
        }
    }

    // MARK: Private

    private var loggers: [any LoggerProtocol]
}
