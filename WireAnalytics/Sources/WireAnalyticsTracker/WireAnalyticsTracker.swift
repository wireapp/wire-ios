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

    public let datadogUserIdentifier: String

    private let applicationID: String
    private let logLevel: DatadogLogs.LogLevel = .debug

    public private(set) var logger: (any DatadogLogs.LoggerProtocol)?

    public init(
        appID: String,
        clientToken: String,
        datadogUserID: String,
        environmentName: String
    ) {
        applicationID = appID
        datadogUserIdentifier = datadogUserID

        // set up datadog

        let configuration = Datadog.Configuration(
            clientToken: clientToken,
            env: environmentName,
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
            remoteLogThreshold: logLevel,
            consoleLogFormat: .shortWith(prefix: "[iOS App] ")
        )
        logger = Logger.create(with: loggerConfiguration)
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

        Datadog.setUserInfo(id: datadogUserIdentifier)

        logger?.log(
            level: logLevel,
            message: "Datadog startMonitoring for device: \(datadogUserIdentifier)",
            error: nil,
            attributes: nil
        )
    }
}
