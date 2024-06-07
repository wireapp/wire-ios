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

import WireTransport

#if canImport(WireAnalyticsTracker)

import DatadogLogs
import WireAnalyticsTracker

extension WireAnalyticsTracker: WireTransport.RemoteLogger {
    public func log(
        message: String,
        error: (any Error)? = nil,
        attributes: [String: any Encodable]? = nil,
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

        logger?.log(
            level: logLevel,
            message: message,
            error: error,
            attributes: attributes
        )
    }
}

#else

extension WireAnalyticsVoidTracker: WireTransport.RemoteLogger {
    public func log(
        message: String,
        error: (any Error)?,
        attributes: [String: any Encodable]?,
        level: WireTransport.RemoteMonitoring.Level
    ) { }
}

#endif
