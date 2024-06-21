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

#if canImport(WireDatadog)

import DatadogLogs
import WireAnalytics
import WireDatadog
import WireSystem

extension WireDatadog: WireSystem.LoggerProtocol {
    public func debug(_ message: any LogConvertible, attributes: LogAttributes...) {
        log(
            level: .debug,
            message: message,
            attributes: attributes
        )
    }

    public func info(_ message: any LogConvertible, attributes: LogAttributes...) {
        log(
            level: .info,
            message: message,
            attributes: attributes
        )
    }

    public func notice(_ message: any LogConvertible, attributes: LogAttributes...) {
        log(
            level: .notice,
            message: message,
            attributes: attributes
        )
    }

    public func warn(_ message: any LogConvertible, attributes: LogAttributes...) {
        log(
            level: .warn,
            message: message,
            attributes: attributes
        )
    }

    public func error(_ message: any LogConvertible, attributes: LogAttributes...) {
        log(
            level: .error,
            message: message,
            attributes: attributes
        )
    }

    public func critical(_ message: any LogConvertible, attributes: LogAttributes...) {
        log(
            level: .critical,
            message: message,
            attributes: attributes
        )
    }

    public func addTag(_ key: LogAttributesKey, value: String?) {
        if let value {
            logger?.addAttribute(forKey: key.rawValue, value: value)
        } else {
            logger?.removeAttribute(forKey: key.rawValue)
        }
    }

    // MARK: Helpers

    private func log(
        level: LogLevel,
        message: any LogConvertible,
        error: Error? = nil,
        attributes: [LogAttributes] = []
    ) {
        let plainAttributes: [String: any Encodable] = attributes.reduce(into: [:]) { partialResult, logAttribute in
            logAttribute.forEach { item in
                partialResult[item.key.rawValue] = item.value
            }
        }

        log(
            level: level,
            message: message.logDescription,
            error: error,
            attributes: plainAttributes
        )
    }

    public var logFiles: [URL] {
        []
    }
}

#endif
