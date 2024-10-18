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

    private static var provider = AggregatedLogger(loggers: [
        SystemLogger(),
        CocoaLumberjackLogger()
    ])

    public let tag: String

    // MARK: - Initialization

    public init(tag: String) {
        self.tag = tag
    }

    // MARK: - LoggerProtocol

    public var logFiles: [URL] {
        Self.provider.logFiles
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

    // MARK: - Private Helpers

    private func shouldLogMessage(_ message: LogConvertible) -> Bool {
        return !message.logDescription.isEmpty
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
        provider.logFiles
    }

<<<<<<< HEAD
    public static func addLogger(_ logger: LoggerProtocol) {
        provider.addLogger(logger)
=======
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
>>>>>>> 309e5a3aaa (fix: cannot start conversation - WPB-11572 (#2037))
    }
}
