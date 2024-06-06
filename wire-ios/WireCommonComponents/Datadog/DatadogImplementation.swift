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

final class DatadogImplementation: DatadogProtocol {

    /// SHA256 string to identify current Device across app and extensions.
    public var datadogUserId: String

    private let applicationID: String
    private let bundleVersion: String?

    var logger: (any DatadogLogs.LoggerProtocol)?
    var defaultLevel: LogLevel

    convenience init?() {
        let bundle = Bundle(for: Self.self)

        guard
            let appID = bundle.infoForKey("DatadogAppId"),
            let clientToken = bundle.infoForKey("DatadogClientToken")
        else {
            print("missing Datadog appID and clientToken - logging disabled")
            return nil
        }

        self.init(
            appID: appID,
            clientToken: clientToken,
            environment: BackendEnvironment.shared,
            level: .debug
        )
    }

    private init(
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

        // RemoteMonitoring.remoteLogger = self

        log(
            level: defaultLevel,
            message: "Datadog startMonitoring for device: \(datadogUserId)"
        )
    }

    // MARK: Logging

    func debug(_ message: any WireSystem.LogConvertible, attributes: WireSystem.LogAttributes?) {

    }

    func info(_ message: any WireSystem.LogConvertible, attributes: WireSystem.LogAttributes?) {

    }

    func notice(_ message: any WireSystem.LogConvertible, attributes: WireSystem.LogAttributes?) {

    }

    func warn(_ message: any WireSystem.LogConvertible, attributes: WireSystem.LogAttributes?) {

    }

    func error(_ message: any WireSystem.LogConvertible, attributes: WireSystem.LogAttributes?) {

    }

    func critical(_ message: any WireSystem.LogConvertible, attributes: WireSystem.LogAttributes?) {

    }

    func log(
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

    func addTag(_ key: LogAttributesKey, value: String?) {
        if let value {
            logger?.addAttribute(forKey: key.rawValue, value: value)
        } else {
            logger?.removeAttribute(forKey: key.rawValue)
        }
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
