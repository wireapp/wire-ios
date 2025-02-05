//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireLogging
import WireSystem
import WireLogging
import WireLegacyLogging

/// Namespace for analytics tools.
public enum WireAnalytics {

    private typealias WireLogger = WireLogging.WireLogger
    private typealias LegacyLogger = WireLegacyLogging.WireLogger

    private static let isSetUpLock = NSLock()
    private static var isSetUp = false

    public static func setup() {
        // Adding a lock here since some app extension might execute this setup in the same process as the main app.
        // https://stackoverflow.com/a/62674277
        isSetUpLock.lock()
        defer { isSetUpLock.unlock() }

        guard !isSetUp else {
            return
        }
        isSetUp = true

        WireAnalytics.Datadog.shared.enable()

        let cocoaLumberjackLogger = CocoaLumberjackLogger()
        let subsystem = Bundle.main.bundleIdentifier!
        WireLogger.setup { tag in
            var datadogLogger = NewWireDatadogLogger(tag: tag, logger: WireAnalytics.Datadog.shared)
            if tag == WireLogger.system.tag {
                datadogLogger.additionalAttributes = [
                    .processId: "\(ProcessInfo.processInfo.processIdentifier)",
                    .processName: ProcessInfo.processInfo.processName
                ]
            }
            return [
                OSLogLoggingProvider(tag: tag, subsystem: subsystem),
                NewCocoaLumberjackLogger(tag: tag, logger: cocoaLumberjackLogger),
                datadogLogger
            ]
        }

        // TODO: clean up
        LegacyLogger.initialize(
            loggers: [
                SystemLogger(),
                cocoaLumberjackLogger,
                WireAnalytics.Datadog.shared
            ]
        )

        // pass tags to Datadog through WireLogger
        LegacyLogger.system.addTag(.processId, value: "\(ProcessInfo.processInfo.processIdentifier)")
        LegacyLogger.system.addTag(.processName, value: ProcessInfo.processInfo.processName)
    }
}
