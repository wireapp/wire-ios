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

public import Foundation

public struct WireLogger: LoggerProtocol, Sendable {

    public static func initialize(loggers: [any LoggerProtocol]) {
        guard provider == nil else {
            assertionFailure("WireLogger.initialize called more than once")
            return
        }

        provider = AggregatedLogger(loggers: loggers)
    }

    private nonisolated(unsafe) static var provider: (any LoggerProtocol)?

    public let tag: String

    // MARK: - Initialization

    public init(tag: String) {
        self.tag = tag
    }

    // MARK: - LoggerProtocol

    public var logFiles: [URL] {
        Self.provider?.logFiles ?? []
    }

    public func addTag(_ key: LogAttributesKey, value: String?) {
        Self.provider?.addTag(key, value: value)
    }

    public func debug(_ message: any LogConvertible, attributes: LogAttributes) {
        guard shouldLogMessage(message) else { return }
        Self.provider?.debug(message, attributes: finalizedAttributes([attributes]))
    }

    public func info(_ message: any LogConvertible, attributes: LogAttributes...) {
        guard shouldLogMessage(message) else { return }
        Self.provider?.info(message, attributes: finalizedAttributes(attributes))
    }

    public func notice(_ message: any LogConvertible, attributes: LogAttributes...) {
        guard shouldLogMessage(message) else { return }
        Self.provider?.notice(message, attributes: finalizedAttributes(attributes))
    }

    public func warn(_ message: any LogConvertible, attributes: LogAttributes...) {
        guard shouldLogMessage(message) else { return }
        Self.provider?.warn(message, attributes: finalizedAttributes(attributes))
    }

    public func error(_ message: any LogConvertible, attributes: LogAttributes...) {
        guard shouldLogMessage(message) else { return }
        Self.provider?.error(message, attributes: finalizedAttributes(attributes))
    }

    public func critical(_ message: any LogConvertible, attributes: LogAttributes...) {
        guard shouldLogMessage(message) else { return }
        Self.provider?.critical(message, attributes: finalizedAttributes(attributes))
    }

    // MARK: - Private Helpers

    private func shouldLogMessage(_ message: any LogConvertible) -> Bool {
        !message.logDescription.isEmpty
    }

    private func finalizedAttributes(_ attributes: [LogAttributes]) -> LogAttributes {
        var finalizedAttributes = flattenArray(attributes)

        if !tag.isEmpty {
            finalizedAttributes[.tag] = tag
        }

        return finalizedAttributes
    }

    // MARK: Static Functions

    public static var logFiles: [URL] {
        provider?.logFiles ?? []
    }
}

// MARK: - Helpers

public extension WireLogger {
    func setClientID(_ clientID: String) {
        addTag(.selfClientId, value: clientID)
    }

    func clearClientID() {
        addTag(.selfClientId, value: nil)
    }

    func setActiveAccount(accoundID: String) {
        addTag(.accountID, value: accoundID)
    }

    func clearActiveAccount() {
        addTag(.accountID, value: nil)
    }

}
