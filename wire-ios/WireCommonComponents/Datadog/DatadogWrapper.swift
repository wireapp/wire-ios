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

public enum LogLevel {

    case debug
    case info
    case notice
    case warn
    case error
    case critical
}

// MARK: - RemoteMonitoring.Level

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

public protocol DatadogProtocol: WireSystem.LoggerProtocol {

    var datadogUserId: String { get }

    func startMonitoring()
    func addTag(_ key: LogAttributesKey, value: String?)
}

public final class DatadogWrapper {

    public static let shared: (any DatadogProtocol)? = {
        #if DATADOG_IMPORT
        return DatadogImplementation()
        #else
        return DatadogVoid()
        #endif
    }()
}
