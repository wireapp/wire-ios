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

/// Convenience interface to the Wire logging systems.
public struct WireLogger: WireLoggerProtocol {
    public typealias Tag = WireLoggerTag
    private typealias Level = WireLogLevel

    public var tag: Tag
    private var loggingSystem: () -> any WireLoggingSystem

    public init(
        _ tag: Tag,
        _ loggingSystem: @escaping () -> any WireLoggingSystem
    ) {
        self.tag = tag
        self.loggingSystem = loggingSystem
    }

    public func debug(_ message: WireLogInterpolation) {
        log(.debug, message)
    }

    public func info(_ message: WireLogInterpolation) {
        log(.info, message)
    }

    public func notice(_ message: WireLogInterpolation) {
        log(.notice, message)
    }

    public func warn(_ message: WireLogInterpolation) {
        log(.warn, message)
    }

    public func error(_ message: WireLogInterpolation) {
        log(.error, message)
    }

    public func critical(_ message: WireLogInterpolation) {
        log(.critical, message)
    }

    private func log(_ level: Level, _ message: WireLogInterpolation) {
        loggingSystem()
            .log(tag: tag, level: level, message: message)
    }
}
