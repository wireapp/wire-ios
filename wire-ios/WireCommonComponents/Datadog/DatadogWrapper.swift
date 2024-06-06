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
import WireSystem
import WireTransport

#if DATADOG_IMPORT

// MARK: - DATADOG ENABLED

import DatadogCore
import DatadogCrashReporting
import DatadogLogs
import DatadogRUM
import DatadogTrace
import UIKit

public final class DatadogWrapper {

    /// Get shared instance only if Developer Flag is on.

    public static var shared: DatadogWrapper? = {
        let bundle = Bundle(for: DatadogWrapper.self)

        guard
            let appID = bundle.infoForKey("DatadogAppId"),
            let clientToken = bundle.infoForKey("DatadogClientToken")
        else {
            print("missing Datadog appID and clientToken - logging disabled")
            return nil
        }

        return DatadogWrapper(appID: appID, clientToken: clientToken)
    }()

    /// SHA256 string to identify current Device across app and extensions.

    public var datadogUserId: String

    private let applicationID: String
    private let bundleVersion: String?

    var logger: (any DatadogLogs.LoggerProtocol)?
    var defaultLevel: LogLevel

    private init(
        appID: String,
        clientToken: String,
        environment: BackendEnvironmentProvider = BackendEnvironment.shared,
        level: LogLevel = .debug
    ) {
        // set up datadog

        let configuration = Datadog.Configuration(
            clientToken: clientToken,
            env: environment.title.alphanumericString,
            site: .eu1
        )
        Datadog.initialize(
            with: configuration,
            trackingConsent: .granted
        )

        CrashReporting.enable()

        let logsConfiguration = Logs.Configuration()
        Logs.enable(with: logsConfiguration)

        let loggerConfiguration = Logger.Configuration(
            name: "iOS Wire App",
            networkInfoEnabled: true,
            remoteLogThreshold: level,
            consoleLogFormat: .shortWith(prefix: "[iOS App] ")
        )
        logger = Logger.create(with: loggerConfiguration)

        // properties

        applicationID = appID

        bundleVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String

        defaultLevel = level

        datadogUserId = UIDevice.current.identifierForVendor?.uuidString.sha256String ?? "none"

        // system logger

        if let aggregatedLogger = WireLogger.provider as? AggregatedLogger {
            aggregatedLogger.addLogger(self)
        } else {
            WireLogger.provider = self
        }
    }

    public func startMonitoring() {
        let traceConfiguration = Trace.Configuration(
            sampleRate: 100,
            networkInfoEnabled: true
        )
        Trace.enable(with: traceConfiguration)

        let rumConfiguration = RUM.Configuration(
            applicationID: applicationID,
            sessionSampleRate: 100,
            uiKitViewsPredicate: DefaultUIKitRUMViewsPredicate(),
            uiKitActionsPredicate: DefaultUIKitRUMActionsPredicate(),
            trackBackgroundEvents: true
        )
        RUM.enable(with: rumConfiguration)

        Datadog.setUserInfo(id: datadogUserId)
        RemoteMonitoring.remoteLogger = self

        log(
            level: defaultLevel,
            message: "Datadog startMonitoring for device: \(datadogUserId)"
        )
    }

    public func log(
        level: LogLevel,
        message: String,
        error: Error? = nil,
        attributes: [String: Encodable]? = nil
    ) {
        var attributes = attributes ?? .init()
        attributes["build_number"] = bundleVersion

        logger?.log(
            level: level,
            message: message,
            error: error,
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
}

extension DatadogWrapper: RemoteLogger {

    public func log(
        message: String,
        error: Error?,
        attributes: [String: Encodable]?,
        level: RemoteMonitoring.Level
    ) {
        log(
            level: level.logLevel,
            message: message,
            error: error,
            attributes: attributes
        )
    }

}

// MARK: Crypto helper

import CryptoKit

private extension String {

    var sha256String: String {
        let inputData = Data(self.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    var alphanumericString: String {
        let pattern = "[^A-Za-z0-9]+"
        return self.replacingOccurrences(of: pattern, with: "", options: [.regularExpression])
    }
}

#else

// MARK: - DATADOG DISABLED

public enum LogLevel {

    case debug
    case info
    case notice
    case warn
    case error
    case critical

}
public final class DatadogWrapper {

    public static let shared: DatadogWrapper? = nil

    public init() {}

    public func log(
        level: LogLevel,
        message: String,
        error: Error? = nil,
        attributes: [String: Encodable]? = nil
    ) {}

    public func startMonitoring() {}
    public func addTag(_ key: LogAttributesKey, value: String?) {}

    public var datadogUserId: String = "NONE"
}
#endif

// MARK: - COMMON

extension RemoteMonitoring.Level {

    var logLevel: LogLevel {
        switch self {
        case .debug:
            return .debug

        case .info:
            return .info

        case .notice:
            return .notice

        case .warn:
            return .warn

        case .error:
            return .error

        case .critical:
            return .critical
        }
    }
}

extension DatadogWrapper: WireSystem.LoggerProtocol {
    public func debug(_ message: LogConvertible, attributes: LogAttributes?) {
        log(level: .debug, message: message.logDescription, attributes: attributes)
    }

    public func info(_ message: LogConvertible, attributes: LogAttributes?) {
        log(level: .info, message: message.logDescription, attributes: attributes)
    }

    public func notice(_ message: LogConvertible, attributes: LogAttributes?) {
        log(level: .notice, message: message.logDescription, attributes: attributes)
    }

    public func warn(_ message: LogConvertible, attributes: LogAttributes?) {
        log(level: .warn, message: message.logDescription, attributes: attributes)
    }

    public func error(_ message: LogConvertible, attributes: LogAttributes?) {
        log(level: .error, message: message.logDescription, attributes: attributes)
    }

    public func critical(_ message: LogConvertible, attributes: LogAttributes?) {
        log(level: .critical, message: message.logDescription, attributes: attributes)
    }
}
