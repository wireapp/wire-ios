//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
    private let instanceAttributes: LogAttributes

    // MARK: - Initialization

    public init(tag: String, instanceAttributes: LogAttributes = [:]) {
        self.tag = tag
        self.instanceAttributes = instanceAttributes
    }

    // MARK: - LoggerProtocol

    public func addTag(_ key: LogAttributesKey, value: String?) {
        Self.provider?.addTag(key, value: value)
    }

    public func debug(_ message: any LogConvertible, attributes: LogAttributes...) {
        guard let provider = Self.provider, let rendered = render(message) else { return }
        provider.debug(rendered, attributes: finalizedAttributes(attributes))
    }

    public func info(_ message: any LogConvertible, attributes: LogAttributes...) {
        guard let provider = Self.provider, let rendered = render(message) else { return }
        provider.info(rendered, attributes: finalizedAttributes(attributes))
    }

    public func notice(_ message: any LogConvertible, attributes: LogAttributes...) {
        guard let provider = Self.provider, let rendered = render(message) else { return }
        provider.notice(rendered, attributes: finalizedAttributes(attributes))
    }

    public func warn(_ message: any LogConvertible, attributes: LogAttributes...) {
        guard let provider = Self.provider, let rendered = render(message) else { return }
        provider.warn(rendered, attributes: finalizedAttributes(attributes))
    }

    public func error(_ message: any LogConvertible, attributes: LogAttributes...) {
        guard let provider = Self.provider, let rendered = render(message) else { return }
        provider.error(rendered, attributes: finalizedAttributes(attributes))
    }

    public func critical(_ message: any LogConvertible, attributes: LogAttributes...) {
        guard let provider = Self.provider, let rendered = render(message) else { return }
        provider.critical(rendered, attributes: finalizedAttributes(attributes))
    }

    // MARK: - Private Helpers

    /// Renders the message to its `String` description exactly once, returning `nil`
    /// for empty messages so they can be skipped.
    private func render(_ message: any LogConvertible) -> String? {
        let rendered = message.logDescription
        return rendered.isEmpty ? nil : rendered
    }

    private func finalizedAttributes(_ attributes: [LogAttributes]) -> LogAttributes {
        var finalizedAttributes = flattenArray(attributes + [instanceAttributes])

        if !tag.isEmpty {
            finalizedAttributes[.tag] = tag
        }

        return finalizedAttributes
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

    // MARK: -

    @resultBuilder
    struct LoggersBuilder {
        public static func buildBlock(_ loggers: any LoggerProtocol...) -> [any LoggerProtocol] {
            loggers
        }
    }

    static func initialize(@LoggersBuilder _ makeLoggers: () -> [any LoggerProtocol]) {
        initialize(loggers: makeLoggers())
    }

}
