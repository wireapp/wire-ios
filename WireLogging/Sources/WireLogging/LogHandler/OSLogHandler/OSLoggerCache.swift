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

/// Thread-safe cache manager for Logger instances.
///
/// Evicts loggers that haven't been accessed recently (lazy eviction on access).
///
/// Caching is necessary because `os.Logger` requires its category to be set at initialization time.
/// Since each log tag maps to a different category, we need a separate `Logger` instance per tag.
/// This cache stores `Logger` instances keyed by tag to avoid recreating them on every log call.

final class OSLoggerCache: @unchecked Sendable {

    private let loggerFactory: (String) -> any OSLoggerProtocol
    private var dictionary: [WireLogTag: CacheEntry] = [:]
    private let queue = DispatchQueue(label: "com.wire.logging.oslogger.cache")
    private var lastEvictionTime: Date = .init()

    /// Time interval after which unused loggers are evicted (5 minutes).
    private static let evictionTimeout: TimeInterval = 5 * 60
    /// Minimum time between eviction checks (30 seconds) to avoid excessive cleanup
    private static let evictionCheckInterval: TimeInterval = 30

    init(
        loggerFactory: @escaping (String) -> any OSLoggerProtocol
    ) {
        self.loggerFactory = loggerFactory
    }

    func logger(for tag: WireLogTag) -> any OSLoggerProtocol {
        queue.sync {
            let now = Date()

            // Check if we have a cached entry (fast path - most common case)
            if var entry = dictionary[tag] {
                // Only update access time if significant time has passed to reduce writes
                let timeSinceAccess = now.timeIntervalSince(entry.lastAccessTime)
                if timeSinceAccess > 1.0 {
                    entry.lastAccessTime = now
                    dictionary[tag] = entry
                }
                return entry.logger
            }

            // Create new logger and cache it
            let logger = loggerFactory(tag.rawValue)
            dictionary[tag] = CacheEntry(logger: logger, lastAccessTime: now)

            // Throttle eviction checks to avoid excessive cleanup
            let timeSinceLastEviction = now.timeIntervalSince(lastEvictionTime)
            if timeSinceLastEviction > Self.evictionCheckInterval {
                lastEvictionTime = now
                // Trigger async eviction only when needed
                queue.async {
                    self.evictStaleEntries(now: now)
                }
            }

            return logger
        }
    }

    private func evictStaleEntries(now: Date) {
        queue.sync {
            let cutoffTime = now.addingTimeInterval(-Self.evictionTimeout)
            var keysToRemove: [WireLogTag] = []
            for (tag, entry) in dictionary where entry.lastAccessTime < cutoffTime {
                keysToRemove.append(tag)
            }
            if !keysToRemove.isEmpty {
                for key in keysToRemove {
                    dictionary.removeValue(forKey: key)
                }
            }
        }
    }

    /// Cache entry containing a logger and its last access time.
    private struct CacheEntry {
        let logger: any OSLoggerProtocol
        var lastAccessTime: Date
    }

}
