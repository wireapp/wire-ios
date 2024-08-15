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

public struct WireLogger: LoggerProtocol {

<<<<<<< HEAD
    private static var provider = AggregatedLogger(loggers: [
        SystemLogger(),
        CocoaLumberjackLogger()
    ])
=======
    public static var provider: LoggerProtocol = AggregatedLogger(loggers: [SystemLogger(), CocoaLumberjackLogger()])
>>>>>>> a932c3a914 (chore: cherry pick share logs through wire - WPB-10436 (#1801))

    public let tag: String

    // MARK: - Initialization

    public init(tag: String) {
        self.tag = tag
    }

    // MARK: - LoggerProtocol

    public var logFiles: [URL] {
<<<<<<< HEAD
        Self.provider.logFiles
=======
        Self.provider.logFiles ?? []
>>>>>>> a932c3a914 (chore: cherry pick share logs through wire - WPB-10436 (#1801))
    }

    public func addTag(_ key: LogAttributesKey, value: String?) {
        Self.provider.addTag(key, value: value)
    }

    public func debug(_ message: any LogConvertible, attributes: LogAttributes...) {
        guard shouldLogMessage(message) else { return }
        Self.provider.debug(message, attributes: finalizedAttributes(attributes))
    }

    public func info(_ message: any LogConvertible, attributes: LogAttributes...) {
        guard shouldLogMessage(message) else { return }
        Self.provider.info(message, attributes: finalizedAttributes(attributes))
    }

    public func notice(_ message: any LogConvertible, attributes: LogAttributes...) {
        guard shouldLogMessage(message) else { return }
        Self.provider.notice(message, attributes: finalizedAttributes(attributes))
    }

    public func warn(_ message: any LogConvertible, attributes: LogAttributes...) {
        guard shouldLogMessage(message) else { return }
        Self.provider.warn(message, attributes: finalizedAttributes(attributes))
    }

    public func error(_ message: any LogConvertible, attributes: LogAttributes...) {
        guard shouldLogMessage(message) else { return }
        Self.provider.error(message, attributes: finalizedAttributes(attributes))
    }

    public func critical(_ message: any LogConvertible, attributes: LogAttributes...) {
        guard shouldLogMessage(message) else { return }
        Self.provider.critical(message, attributes: finalizedAttributes(attributes))
    }

<<<<<<< HEAD
    // MARK: - Private Helpers
=======
    public static var logFiles: [URL] {
        provider.logFiles
    }
>>>>>>> a932c3a914 (chore: cherry pick share logs through wire - WPB-10436 (#1801))

    private func shouldLogMessage(_ message: LogConvertible) -> Bool {
        return !message.logDescription.isEmpty
    }

    private func finalizedAttributes(_ attributes: [LogAttributes]) -> LogAttributes {
        var finalizedAttributes = flattenArray(attributes)

        if !tag.isEmpty {
            finalizedAttributes[.tag] = tag
        }

<<<<<<< HEAD
        return finalizedAttributes
=======
        switch level {
        case .debug:
            Self.provider.debug(message, attributes: attributes)

        case .info:
            Self.provider.info(message, attributes: attributes)

        case .notice:
            Self.provider.notice(message, attributes: attributes)

        case .warn:
            Self.provider.warn(message, attributes: attributes)

        case .error:
            Self.provider.error(message, attributes: attributes)

        case .critical:
            Self.provider.critical(message, attributes: attributes)
        }
>>>>>>> a932c3a914 (chore: cherry pick share logs through wire - WPB-10436 (#1801))
    }

    // MARK: Static Functions

    public static var logFiles: [URL] {
        provider.logFiles
    }

    public static func addLogger(_ logger: LoggerProtocol) {
        provider.addLogger(logger)
    }
}
