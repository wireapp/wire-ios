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

public struct WireTaggedLogger: WireTaggedLoggerProtocol {
    public typealias Tag = WireLogTag

    public var tag: Tag
    public var providers: [any WireLoggingProvider]

    public func debug(_ message: WireLogMessage) {
        log(.debug, message)
    }

    public func info(_ message: WireLogMessage) {
        log(.info, message)
    }

    public func notice(_ message: WireLogMessage) {
        log(.notice, message)
    }

    public func warn(_ message: WireLogMessage) {
        log(.warn, message)
    }

    public func error(_ message: WireLogMessage) {
        log(.error, message)
    }

    public func critical(_ message: WireLogMessage) {
        log(.critical, message)
    }

    private func log(_ type: WireLogType, _ message: WireLogMessage) {
        providers.forEach { provider in
            provider.log(
                tag: tag,
                type: type,
                message: message
            )
        }
    }

}
