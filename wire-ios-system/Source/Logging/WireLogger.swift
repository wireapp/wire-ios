//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

    public static var provider: LoggerProtocol = AggregatedLogger(loggers: [SystemLogger(), CocoaLumberjackLogger()])

    public let tag: String

    public init(tag: String = "") {
        self.tag = tag
    }

    public var logFiles: [URL] {
        Self.provider.logFiles ?? []
    }

    public func addTag(_ key: LogAttributesKey, value: String?) {
        Self.provider.addTag(key, value: value)
    }

    public func debug(
        _ message: LogConvertible,
        attributes: LogAttributes? = nil
    ) {
        guard shouldLogMessage(message) else { return }
        log(level: .debug, message: message, attributes: attributes)
    }

    public func info(
        _ message: LogConvertible,
        attributes: LogAttributes? = nil
    ) {
        guard shouldLogMessage(message) else { return }
        log(level: .info, message: message, attributes: attributes)
    }

    public func notice(
        _ message: LogConvertible,
        attributes: LogAttributes? = nil
    ) {
        guard shouldLogMessage(message) else { return }
        log(level: .notice, message: message, attributes: attributes)
    }

    public func warn(
        _ message: LogConvertible,
        attributes: LogAttributes? = nil
    ) {
        guard shouldLogMessage(message) else { return }
        log(level: .warn, message: message, attributes: attributes)
    }

    public func error(
        _ message: LogConvertible,
        attributes: LogAttributes? = nil
    ) {
        guard shouldLogMessage(message) else { return }
        log(level: .error, message: message, attributes: attributes)
    }

    public func critical(
        _ message: LogConvertible,
        attributes: LogAttributes? = nil
    ) {
        guard shouldLogMessage(message) else { return }
        log(level: .critical, message: message, attributes: attributes)
    }

    public static var logFiles: [URL] {
        provider.logFiles
    }

    private func shouldLogMessage(_ message: LogConvertible) -> Bool {
        return !message.logDescription.isEmpty
    }

    private func log(
        level: LogLevel,
        message: LogConvertible,
        attributes: LogAttributes? = nil
    ) {
        var attributes = attributes ?? .init()

        if !tag.isEmpty {
            attributes["tag"] = tag
        }

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

public typealias LogAttributes = [String: Encodable]

public enum LogAttributesKey: String {
    case selfClientId = "self_client_id"
    case selfUserId = "self_user_id"
    case recipientID = "recipient_id"
    case eventId = "event_id"
    case senderUserId = "sender_user_id"
    case nonce = "message_nonce"
    case messageType = "message_type"
    case lastEventID = "last_event_id"
    case conversationId = "conversation_id"
    case syncPhase = "sync_phase"
    case eventSource = "event_source"
}

public extension LogAttributes {
    static var safePublic = ["public": true]
}

public protocol LoggerProtocol {

    func debug(_ message: LogConvertible, attributes: LogAttributes?)
    func info(_ message: LogConvertible, attributes: LogAttributes?)
    func notice(_ message: LogConvertible, attributes: LogAttributes?)
    func warn(_ message: LogConvertible, attributes: LogAttributes?)
    func error(_ message: LogConvertible, attributes: LogAttributes?)
    func critical(_ message: LogConvertible, attributes: LogAttributes?)

    var logFiles: [URL] { get }

    /// Add an attribute, value to each logs - DataDog only
    func addTag(_ key: LogAttributesKey, value: String?)
}

extension LoggerProtocol {
    func attributesDescription(from attributes: LogAttributes?) -> String {
        var logAttributes = attributes
        // drop attributes used for visibility and category
        logAttributes?.removeValue(forKey: "public")
        logAttributes?.removeValue(forKey: "tag")
        guard let logAttributes, !logAttributes.isEmpty else {
            return ""
        }
        var description = " - ["
        description += logAttributes.keys.sorted().map { key in
            "\(key): \(logAttributes[key] ?? "<nil>")"
        }.joined(separator: ", ")
        description += "]"

        return description
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
    static let network = WireLogger(tag: "network")
    static let performance = WireLogger(tag: "performance")
    static let push = WireLogger(tag: "push")
    static let proteus = WireLogger(tag: "proteus")
    static let session = WireLogger(tag: "session")
    static let shareExtension = WireLogger(tag: "share-extension")
    static let sync = WireLogger(tag: "sync")
    static let system = WireLogger(tag: "system")
    static let ui = WireLogger(tag: "UI")
    static let updateEvent = WireLogger(tag: "update-event")
    static let userClient = WireLogger(tag: "user-client")
    static let pushChannel = WireLogger(tag: "push-channel")
    static let eventProcessing = WireLogger(tag: "event-processing")
    static let safeFileContext = WireLogger(tag: "safe-file-context")
    static let messageProcessing = WireLogger(tag: "message-processing")
    static let supportedProtocols = WireLogger(tag: "supported-protocols")
}

/// Class to proxy WireLogger methods to Objective-C
@objcMembers
public final class WireLoggerObjc: NSObject {

    static func assertionDumpLog(_ message: String) {
        WireLogger.system.critical(message, attributes: .safePublic)
    }

    @objc(logReceivedUpdateEventWithId:)
    static func logReceivedUpdateEvent(eventId: String) {
        var mergedAttributes: LogAttributes = LogAttributes.safePublic

        mergedAttributes.merge([LogAttributesKey.eventId.rawValue: eventId], uniquingKeysWith: { _, new in new })

        WireLogger.updateEvent.info("received event", attributes: mergedAttributes)
    }

    static func updateEventError(_ message: String) {
        WireLogger.updateEvent.error(message, attributes: .safePublic)
    }

    @objc(logSaveCoreDataError:)
    static func logSaveCoreData(error: Error) {
        WireLogger.localStorage.error("Failed to save: \(error)", attributes: .safePublic)
    }
}
