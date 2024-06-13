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

import WireAnalytics
import WireSystem

// MARK: - Types

public enum WireAnalytics {
    public static func enable() {
        let tracker = WireAnalytics.shared

        #if canImport(WireDatadog)
        if let datadogTracker = tracker as? WireDatadog {
            datadogTracker.enable()
        }
        #endif

        if let aggregatedLogger = WireLogger.provider as? AggregatedLogger {
            aggregatedLogger.addLogger(tracker)
        } else {
            WireLogger.provider = tracker
        }
    }
}

public typealias WireAnalyticsProtocol = WireDatadogProtocol & LoggerProtocol

// MARK: - Singleton

#if canImport(WireDatadog)

import WireDatadog
import WireTransport

extension WireAnalytics {
    public static let shared: any WireAnalyticsProtocol = {
        let builder = WireDatadogTrackerBuilder()

        guard let tracker = builder.build() else {
            assertionFailure("building WireAnalyticsDatadogTracker failed - logging disabled")
            return WireAnalyticsVoidTracker()
        }

        return tracker
    }()
}

#else

extension WireAnalytics {
    public static let shared: any WireAnalyticsProtocol = WireDatadogVoid()
}

#endif
