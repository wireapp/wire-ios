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

import WireSystem

#if canImport(WireAnalyticsTracker)

import WireAnalyticsTracker

extension WireAnalyticsTracker: WireSystem.LoggerProtocol {
    public func debug(_ message: LogConvertible, attributes: LogAttributes?) {
        log(message: message.logDescription, attributes: attributes, level: .debug)
    }

    public func info(_ message: LogConvertible, attributes: LogAttributes?) {
        log(message: message.logDescription, attributes: attributes, level: .info)
    }

    public func notice(_ message: LogConvertible, attributes: LogAttributes?) {
        log(message: message.logDescription, attributes: attributes, level: .notice)
    }

    public func warn(_ message: LogConvertible, attributes: LogAttributes?) {
        log(message: message.logDescription, attributes: attributes, level: .warn)
    }

    public func error(_ message: LogConvertible, attributes: LogAttributes?) {
        log(message: message.logDescription, attributes: attributes, level: .error)
    }

    public func critical(_ message: LogConvertible, attributes: LogAttributes?) {
        log(message: message.logDescription, attributes: attributes, level: .critical)
    }

    public func addTag(_ key: LogAttributesKey, value: String?) {
        if let value {
            logger?.addAttribute(forKey: key.rawValue, value: value)
        } else {
            logger?.removeAttribute(forKey: key.rawValue)
        }
    }
}

#else

extension WireAnalyticsVoidTracker: WireSystem.LoggerProtocol {
    public func debug(_ message: LogConvertible, attributes: LogAttributes?) { }
    public func info(_ message: LogConvertible, attributes: LogAttributes?) { }
    public func notice(_ message: LogConvertible, attributes: LogAttributes?) { }
    public func warn(_ message: LogConvertible, attributes: LogAttributes?) { }
    public func error(_ message: LogConvertible, attributes: LogAttributes?) { }
    public func critical(_ message: LogConvertible, attributes: LogAttributes?) { }

    public func addTag(_ key: LogAttributesKey, value: String?) { }
}

#endif
