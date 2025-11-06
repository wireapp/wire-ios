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

import os
import Foundation

public struct OSLogHandler: WireLogHandlerProtocol {

    var subsystem: String
    private let cache: LoggerCache

    public init(subsystem: String) {
        self.subsystem = subsystem
        self.cache = LoggerCache(subsystem: subsystem)
    }

    public func log(
        tag: WireLogTag,
        type: WireLogType,
        message: WireLogMessage,
        additionalAttributes: [WireLogAttribute]
    ) {

        var attributes = [String: String]() // additionalAttributes overwrite message attributes
        for attribute in message.interpolation.attributes + additionalAttributes {
            attributes[attribute.key] = attribute.value
        }

        var attributesString = ""
        for attributesKey in attributes.keys.sorted() {
            attributesString += "[\(attributesKey)=\(attributes[attributesKey]!)]"
        }

        let message = "\(attributesString) \(message.interpolation.content)"

        let logger = cache.logger(for: tag)
        logger.log(
            level: type.mappedToOSLogType(),
            "\(message, privacy: .public)"
        )

    }

    // MARK: - Logger Caching

    /// Wrapper class to store Logger (a struct) in NSCache with last access tracking.
    private final class LoggerWrapper {
        let logger: Logger
        private(set) var lastAccessTime: Date
        
        init(_ logger: Logger) {
            self.logger = logger
            self.lastAccessTime = Date()
        }
        
        func updateAccessTime() {
            lastAccessTime = Date()
        }
    }

    /// Thread-safe cache manager for Logger instances.
    ///
    /// Uses `NSCache` to automatically evict unused Logger instances under memory pressure.
    /// Also evicts loggers that haven't been accessed recently (lazy eviction on access).
    private final class LoggerCache {
        private let subsystem: String
        private let cache: NSCache<NSString, LoggerWrapper>
        
        /// Time interval after which unused loggers are evicted (5 minutes).
        private static let evictionTimeout: TimeInterval = 5 * 60
        
        init(subsystem: String) {
            self.subsystem = subsystem
            self.cache = NSCache<NSString, LoggerWrapper>()
        }
        
        func logger(for tag: WireLogTag) -> Logger {
            let key = tag.rawValue as NSString
            
            // Try to get cached logger
            if let wrapper = cache.object(forKey: key) {
                // Check if entry is stale and should be evicted
                let age = Date().timeIntervalSince(wrapper.lastAccessTime)
                if age > Self.evictionTimeout {
                    // Entry is stale, remove it and create a new one
                    cache.removeObject(forKey: key)
                } else {
                    // Update access time and return cached logger
                    wrapper.updateAccessTime()
                    return wrapper.logger
                }
            }
            
            // Create new logger and cache it
            let logger = Logger(subsystem: subsystem, category: tag.rawValue)
            cache.setObject(LoggerWrapper(logger), forKey: key)
            return logger
        }
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
