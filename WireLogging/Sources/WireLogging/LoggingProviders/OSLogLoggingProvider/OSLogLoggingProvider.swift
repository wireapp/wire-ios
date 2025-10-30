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

import os

public struct OSLogLoggingProvider: WireLoggingProvider {

    public let tag: Tag

    private var logger: Logger

    public init(tag: Tag, subsystem: String) {
        self.tag = tag
        logger = .init(subsystem: subsystem, category: tag.rawValue)
    }

    public func log(level: Level, message: WireLogMessage) {
        let level = level.mappedToOSLogType()
        let attributes = message.interpolation.attributes.map { "[\($0)]" }
        let message = (attributes + [message.interpolation.content])
            .joined(separator: " ")
        logger.log(level: level, "\(message, privacy: .public)")
    }
}

extension WireLogLevel {

    fileprivate func mappedToOSLogType() -> OSLogType {
        /*
         Note:
         - levels are `default`, `info`, `debug`, `error` and `fault`
         - `trace` is an alias for `debug`
         - `notice` is an alias for `default`
         - `warning` is an alias for `error`
         - `critical` is an alias for `fault`
         */

        switch self {
        case .debug:
                .debug
        case .info:
                .info
        case .notice:
                .default
        case .warn:
                .error
        case .error:
                .error
        case .critical:
                .fault
        }
    }
}
