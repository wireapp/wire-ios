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

    /// Cache entry containing a logger and its last access time.

    private struct CacheEntry {
        let logger: Logger
        var lastAccessTime: Date
    }

    /// Thread-safe cache manager for Logger instances.
    ///
    /// Evicts loggers that haven't been accessed recently (lazy eviction on access).
    ///
    /// Caching is necessary because `os.Logger` requires its category to be set at initialization time.
    /// Since each log tag maps to a different category, we need a separate `Logger` instance per tag.
    /// This cache stores `Logger` instances keyed by tag to avoid recreating them on every log call.

    private final class LoggerCache: @unchecked Sendable {
        private let subsystem: String
        private var dictionary: [WireLogTag: CacheEntry] = [:]
        private let queue = DispatchQueue(label: "com.wire.logging.oslogger.cache")

        /// Time interval after which unused loggers are evicted (5 minutes).
        private static let evictionTimeout: TimeInterval = 5 * 60

        init(subsystem: String) {
            self.subsystem = subsystem
        }

        func logger(for tag: WireLogTag) -> Logger {
            // Synchronously get or create logger and update access time
            let logger = queue.sync {
                let now = Date()

                // Check if we have a cached entry
                if var entry = dictionary[tag] {
                    // Always update access time if entry exists (even if it was stale)
                    entry.lastAccessTime = now
                    dictionary[tag] = entry
                    return entry.logger
                }

                // Create new logger and cache it
                let logger = Logger(subsystem: subsystem, category: tag.rawValue)
                dictionary[tag] = CacheEntry(logger: logger, lastAccessTime: now)
                return logger
            }

            // Asynchronously clean up stale entries (non-blocking)
            queue.async {
                self.evictStaleEntries()
            }

            return logger
        }

        private func evictStaleEntries() {
            let cutoffTime = Date().addingTimeInterval(-Self.evictionTimeout)
            var keysToRemove: [WireLogTag] = []

            for (tag, entry) in dictionary where entry.lastAccessTime < cutoffTime {
                keysToRemove.append(tag)
            }
            for key in keysToRemove {
                dictionary.removeValue(forKey: key)
            }
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
