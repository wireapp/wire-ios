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
import WireLogging

private typealias AggregatedLoggingProvider = WireLogging.AggregatedLoggingProvider

/// Namespace for analytics tools.
public enum WireAnalytics {

    private static let isSetUpLock = NSLock()
    private static var isSetUp = false

    public static func setup() {
        // Adding a lock here since some app extension might execute this setup in the same process as the main app.
        // https://stackoverflow.com/a/62674277
        isSetUpLock.lock()
        defer { isSetUpLock.unlock() }

        guard !isSetUp else {
            assertionFailure("WireAnalytics.setup() called more than once")
            return
        }
        isSetUp = true

        WireAnalytics.Datadog.shared.enable()

        let cocoaLumberjackLogger = CocoaLumberjackLogger()
        WireLogger.setup { tag in
            AggregatedLoggingProvider(tag: tag) { tag in
                var datadogLogger = NewWireDatadogLogger(tag: tag, logger: WireAnalytics.Datadog.shared)
                if tag == "system" {
                    datadogLogger.additionalAttributes = [
                        .processId: "\(ProcessInfo.processInfo.processIdentifier)",
                        .processName: ProcessInfo.processInfo.processName
                    ]
                }
                return [
                    OSLogLoggingProvider(logger: .init(subsystem: Bundle.main.bundleIdentifier!, category: tag.rawValue)),
                    NewCocoaLumberjackLogger(tag: tag, logger: cocoaLumberjackLogger),
                    datadogLogger
                ]
            }
        }
        OldWireLogger.initialize(
            loggers: [
                SystemLogger(),
                cocoaLumberjackLogger,
                WireAnalytics.Datadog.shared
            ]
        )

        // pass tags to Datadog through WireLogger
        OldWireLogger.system.addTag(.processId, value: "\(ProcessInfo.processInfo.processIdentifier)")
        OldWireLogger.system.addTag(.processName, value: ProcessInfo.processInfo.processName)
    }
}
