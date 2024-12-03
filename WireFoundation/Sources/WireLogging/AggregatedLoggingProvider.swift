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

public struct AggregatedLoggingProvider: WireLoggingProvider {

    let loggingSystems: @Sendable (Tag) -> [any WireLoggingProvider]

    public let tag: Tag

    public init(
        tag: Tag,
        loggingSystems: @escaping @Sendable (Tag) -> [any WireLoggingProvider]
    ) {
        self.tag = tag
        self.loggingSystems = loggingSystems
    }

    public func log(level: Level, message: WireLogMessage) {
        loggingSystems(tag).forEach { loggingSystem in
            loggingSystem.log(level: level, message: message)
        }
    }
}
