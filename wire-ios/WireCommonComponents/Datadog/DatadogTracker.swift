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

#if DATADOG_IMPORT

import DatadogCore
import DatadogCrashReporting
import DatadogLogs
import DatadogRUM
import DatadogTrace
import UIKit
import WireTransport

final class DatadogTracker: DatadogTrackerProtocol {

    /// SHA256 string to identify current Device across app and extensions.
    var datadogUserId: String

    private let applicationID: String
    private let bundleVersion: String?

    var logger: (any DatadogLogs.LoggerProtocol)?
    var defaultLevel: LogLevel

    init(
        appID: String,
        clientToken: String,
        environment: BackendEnvironmentProvider,
        level: LogLevel
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

    func startMonitoring() {
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

    // MARK: Logging

    func addTag(_ key: LogAttributesKey, value: String?) {
        if let value {
            logger?.addAttribute(forKey: key.rawValue, value: value)
        } else {
            logger?.removeAttribute(forKey: key.rawValue)
        }
    }

    func debug(_ message: any LogConvertible, attributes: LogAttributes?) {
        log(
            level: .debug,
            message: message.logDescription,
            attributes: attributes
        )
    }

    func info(_ message: any LogConvertible, attributes: LogAttributes?) {
        log(
            level: .info,
            message: message.logDescription,
            attributes: attributes
        )
    }

    func notice(_ message: any LogConvertible, attributes: LogAttributes?) {
        log(
            level: .notice,
            message: message.logDescription,
            attributes: attributes
        )
    }

    func warn(_ message: any LogConvertible, attributes: LogAttributes?) {
        log(
            level: .warn,
            message: message.logDescription,
            attributes: attributes
        )
    }

    func error(_ message: any LogConvertible, attributes: LogAttributes?) {
        log(
            level: .error,
            message: message.logDescription,
            attributes: attributes
        )
    }

    func critical(_ message: any LogConvertible, attributes: LogAttributes?) {
        log(
            level: .critical,
            message: message.logDescription,
            attributes: attributes
        )
    }

    private func log(
        level: LogLevel,
        message: String,
        error: Error? = nil,
        attributes: [String: any Encodable]? = nil
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
}

extension DatadogTracker: WireTransport.RemoteLogger {
    func log(
        message: String,
        error: (any Error)?,
        attributes: [String: any Encodable]?,
        level: WireTransport.RemoteMonitoring.Level
    ) {
        let logLevel: DatadogLogs.LogLevel = switch level {
        case .debug: .debug
        case .info: .info
        case .notice: .notice
        case .warn: .warn
        case .error: .error
        case .critical: .critical
        }

        log(
            level: logLevel,
            message: message,
            error: error,
            attributes: attributes
        )
    }
}

// MARK: - Crypto helper

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

#endif
