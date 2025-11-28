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
import os

public struct OSLogHandler: WireLogHandlerProtocol {

    var subsystem: String
    private let cache: OSLoggerCache

    public init(subsystem: String) {
        self.subsystem = subsystem
        self.cache = OSLoggerCache(subsystem: subsystem)
    }

    public func log(
        tag: WireLogTag,
        type: WireLogType,
        message: WireLogMessage,
        additionalAttributes: [WireLogAttribute]
    ) {
        var attributes = [String: String]()
        attributes.reserveCapacity(message.interpolation.attributes.count + additionalAttributes.count)
        
        // Add message attributes first
        for attribute in message.interpolation.attributes {
            attributes[attribute.key] = attribute.value
        }
        // Overwrite with additional attributes
        for attribute in additionalAttributes {
            attributes[attribute.key] = attribute.value
        }

        // Build attributes string efficiently using joined()
        let attributesString = attributes.keys.sorted().map { key in
            "[\(key)=\(attributes[key] ?? "")]"
        }.joined()

        let finalMessage = attributesString.isEmpty 
            ? message.interpolation.content
            : "\(attributesString) \(message.interpolation.content)"

        let logger = cache.logger(for: tag)
        logger.log(
            level: type.mappedToOSLogType(),
            finalMessage
        )
    }

}

private extension WireLogType {

    func mappedToOSLogType() -> OSLogType {

        // Note:
        // - OSLogTypes are `default`, `info`, `debug`, `error` and `fault`
        // - `trace` is an alias for `debug`
        // - `notice` is an alias for `default`
        // - `warning` is an alias for `error`
        // - `critical` is an alias for `fault`

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
