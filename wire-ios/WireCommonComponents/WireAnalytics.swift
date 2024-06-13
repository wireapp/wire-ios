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

/// Namespace for analytics tools.
public enum WireAnalytics {
    public static func enable() {
        let tracker = WireAnalytics.shared
        tracker.enable()

        if let aggregatedLogger = WireLogger.provider as? AggregatedLogger {
            aggregatedLogger.addLogger(tracker)
        } else {
            WireLogger.provider = tracker
        }
    }
}

/// Composes the requirements for Datadog in Wire Analytics.
public typealias WireAnalyticsDatadogProtocol = WireDatadogProtocol & LoggerProtocol

// MARK: - Singleton

#if canImport(WireDatadog)

import WireDatadog

extension WireAnalytics {
    public static let shared: any WireAnalyticsDatadogProtocol = {
        let builder = WireDatadogBuilder()
        return builder.build()
    }()
}

#else

extension WireAnalytics {
    public static let shared: any WireAnalyticsDatadogProtocol = WireDatadogVoid()
}

#endif
