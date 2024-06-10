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

import DatadogCore
import DatadogCrashReporting
import DatadogLogs
import DatadogRUM
import DatadogTrace
import UIKit

public final class WireAnalyticsTracker {

    /// SHA256 string to identify current Device across app and extensions.
    public var datadogUserId: String

    private let applicationID: String

    public let bundleVersion: String?

    public private(set) var logger: (any DatadogLogs.LoggerProtocol)?

    init(
        appID: String,
        clientToken: String,
        // environment: BackendEnvironmentProvider,
        level: LogLevel
    ) {
        // set up datadog

        let configuration = Datadog.Configuration(
            clientToken: clientToken,
            env: "environment.title.alphanumericString",
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

        datadogUserId = UIDevice.current.identifierForVendor?.uuidString.sha256String ?? "none"
    }

    public func enable() {
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

        logger?.log(
            level: .info,
            message: "Datadog startMonitoring for device: \(datadogUserId)",
            error: nil,
            attributes: nil
        )
    }
}

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
