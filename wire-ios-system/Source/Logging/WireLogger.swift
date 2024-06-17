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

public struct WireLogger: LoggerProtocol {

    public static var provider: LoggerProtocol? = AggregatedLogger(loggers: [SystemLogger(), CocoaLumberjackLogger()])

    public let tag: String

    public init(tag: String = "") {
        self.tag = tag
    }

    public var logFiles: [URL] {
        Self.provider?.logFiles ?? []
    }

    public func addTag(_ key: LogAttributesKey, value: String?) {
        Self.provider?.addTag(key, value: value)
    }

    public func debug(_ message: any LogConvertible, attributes: LogAttributes...) {
        guard shouldLogMessage(message) else { return }
        log(level: .debug, message: message, attributes: attributes)
    }

    public func info(_ message: any LogConvertible, attributes: LogAttributes...) {
        guard shouldLogMessage(message) else { return }
        log(level: .info, message: message, attributes: attributes)
    }

    public func notice(_ message: any LogConvertible, attributes: LogAttributes...) {
        guard shouldLogMessage(message) else { return }
        log(level: .notice, message: message, attributes: attributes)
    }

    public func warn(_ message: any LogConvertible, attributes: LogAttributes...) {
        guard shouldLogMessage(message) else { return }
        log(level: .warn, message: message, attributes: attributes)
    }

    public func error(_ message: any LogConvertible, attributes: LogAttributes...) {
        guard shouldLogMessage(message) else { return }
        log(level: .error, message: message, attributes: attributes)
    }

    public func critical(_ message: any LogConvertible, attributes: LogAttributes...) {
        guard shouldLogMessage(message) else { return }
        log(level: .critical, message: message, attributes: attributes)
    }

    private func shouldLogMessage(_ message: LogConvertible) -> Bool {
        return Self.provider != nil && !message.logDescription.isEmpty
    }

    private func log(
        level: LogLevel,
        message: LogConvertible,
        attributes: [LogAttributes]
    ) {
        var mergedAttributes = flattenArray(attributes)

        if !tag.isEmpty {
            mergedAttributes[.tag] = tag
        }

        switch level {
        case .debug:
            Self.provider?.debug(message, attributes: mergedAttributes)

        case .info:
            Self.provider?.info(message, attributes: mergedAttributes)

        case .notice:
            Self.provider?.notice(message, attributes: mergedAttributes)

        case .warn:
            Self.provider?.warn(message, attributes: mergedAttributes)

        case .error:
            Self.provider?.error(message, attributes: mergedAttributes)

        case .critical:
            Self.provider?.critical(message, attributes: mergedAttributes)
        }
    }

    private enum LogLevel {

        case debug
        case info
        case notice
        case warn
        case error
        case critical

    }
}

public typealias LogAttributes = [LogAttributesKey: Encodable]

public enum LogAttributesKey: String {
    case selfClientId = "self_client_id"
    case selfUserId = "self_user_id"
    case eventId = "event_id"
    case `public`
    case tag
}

public extension LogAttributes {
    static var safePublic = [LogAttributesKey.public: true]
}

public protocol LoggerProtocol {

    func debug(_ message: any LogConvertible, attributes: LogAttributes...)
    func info(_ message: any LogConvertible, attributes: LogAttributes...)
    func notice(_ message: any LogConvertible, attributes: LogAttributes...)
    func warn(_ message: any LogConvertible, attributes: LogAttributes...)
    func error(_ message: any LogConvertible, attributes: LogAttributes...)
    func critical(_ message: any LogConvertible, attributes: LogAttributes...)

    var logFiles: [URL] { get }

    /// Add an attribute, value to each logs - DataDog only
    func addTag(_ key: LogAttributesKey, value: String?)
}

extension LoggerProtocol {
    func attributesDescription(from attributes: [LogAttributes]) -> String {
        var logAttributes = flattenArray(attributes)

        // drop attributes used for visibility and category
        logAttributes.removeValue(forKey: LogAttributesKey.public)
        logAttributes.removeValue(forKey: LogAttributesKey.tag)
        return logAttributes.isEmpty == false ? " - \(logAttributes.description)" : ""
    }

    /// helper method to transform attributes array to single LogAttributes
    /// - note: if same key is contained accross multiple attributes, the latest one is taken
    public func flattenArray(_ attributes: [LogAttributes]) -> LogAttributes {
        var mergedAttributes: LogAttributes = [:]
        attributes.forEach {
            mergedAttributes.merge($0) { _, new in new }
        }
        return mergedAttributes
    }
}

public protocol LogConvertible {

    var logDescription: String { get }

}

extension String: LogConvertible {

    public var logDescription: String {
        return self
    }

}

public extension WireLogger {

    static let apiMigration = WireLogger(tag: "api-migration")
    static let appState = WireLogger(tag: "AppState")
    static let appDelegate = WireLogger(tag: "AppDelegate")
    static let appLock = WireLogger(tag: "AppLock")
    static let assets = WireLogger(tag: "assets")
    static let authentication = WireLogger(tag: "authentication")
    static let backgroundActivity = WireLogger(tag: "background-activity")
    static let badgeCount = WireLogger(tag: "badge-count")
    static let backend = WireLogger(tag: "backend")
    static let calling = WireLogger(tag: "calling")
    static let conversation = WireLogger(tag: "conversation")
    static let coreCrypto = WireLogger(tag: "core-crypto")
    static let e2ei = WireLogger(tag: "end-to-end-identity")
    static let ear = WireLogger(tag: "encryption-at-rest")
    static let environment = WireLogger(tag: "environment")
    static let featureConfigs = WireLogger(tag: "feature-configurations")
    static let keychain = WireLogger(tag: "keychain")
    static let localStorage = WireLogger(tag: "local-storage")
    static let messaging = WireLogger(tag: "messaging")
    static let mls = WireLogger(tag: "mls")
    static let notifications = WireLogger(tag: "notifications")
    static let performance = WireLogger(tag: "performance")
    static let push = WireLogger(tag: "push")
    static let proteus = WireLogger(tag: "proteus")
    static let session = WireLogger(tag: "session")
    static let sessionManager = WireLogger(tag: "SessionManager")
    static let shareExtension = WireLogger(tag: "share-extension")
    static let sync = WireLogger(tag: "sync")
    static let system = WireLogger(tag: "system")
    static let ui = WireLogger(tag: "UI")
    static let updateEvent = WireLogger(tag: "update-event")
    static let userClient = WireLogger(tag: "user-client")
    static let network = WireLogger(tag: "network")

}

/// Class to proxy WireLogger methods to Objective-C
@objcMembers
public final class WireLoggerObjc: NSObject {

    static func assertionDumpLog(_ message: String) {
        WireLogger.system.critical(message, attributes: .safePublic)
    }
}
