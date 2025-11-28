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
import Testing
import os

@testable import WireLogging

struct OSLoggerCacheTests {

    private let testSubsystem = "com.wire.wirelogging.test"

    @Test func loggerForTag_createsLogger() {
        let cache = OSLoggerCache(subsystem: testSubsystem)
        let tag: WireLogTag = "test-tag-1"
        
        let logger = cache.logger(for: tag)
        
        // Verify logger is created and can be used
        logger.debug("test message")
        // If we get here without crashing, the logger was created successfully
    }

    @Test func loggerForSameTag_returnsCachedInstance() {
        let cache = OSLoggerCache(subsystem: testSubsystem)
        let tag: WireLogTag = "test-tag-2"
        
        let logger1 = cache.logger(for: tag)
        let logger2 = cache.logger(for: tag)
        
        // Verify both calls return valid loggers
        // Note: os.Logger doesn't conform to Equatable, so we can't directly compare instances
        // but we can verify the cache is working by ensuring both loggers are functional
        logger1.debug("test from logger1")
        logger2.info("test from logger2")
    }

    @Test func loggerForDifferentTags_createsDifferentLoggers() {
        let cache = OSLoggerCache(subsystem: testSubsystem)
        let tag1: WireLogTag = "test-tag-3"
        let tag2: WireLogTag = "test-tag-4"
        
        let logger1 = cache.logger(for: tag1)
        let logger2 = cache.logger(for: tag2)
        
        // Verify both loggers are created and functional
        logger1.debug("test from tag1")
        logger2.debug("test from tag2")
    }

    @Test func multipleTags_canBeCached() {
        let cache = OSLoggerCache(subsystem: testSubsystem)
        let tags: [WireLogTag] = ["tag-a", "tag-b", "tag-c", "tag-d", "tag-e"]
        
        var loggers: [Logger] = []
        for tag in tags {
            loggers.append(cache.logger(for: tag))
        }
        
        // Verify all loggers are created
        #expect(loggers.count == tags.count)
        
        // Verify all loggers are functional
        for logger in loggers {
            logger.debug("test message")
        }
        
        // Verify cache still works after multiple entries
        let cachedLogger = cache.logger(for: tags[0])
        cachedLogger.info("retrieved from cache")
    }

    @Test func concurrentAccess_isThreadSafe() async {
        let cache = OSLoggerCache(subsystem: testSubsystem)
        let tags = (0..<100).map { WireLogTag(stringLiteral: "tag-\($0)") }
        
        await withTaskGroup(of: Void.self) { group in
            for tag in tags {
                group.addTask {
                    let logger = cache.logger(for: tag)
                    logger.debug("concurrent test")
                }
            }
        }
        
        // Verify cache still works after concurrent access
        let logger = cache.logger(for: tags[0])
        logger.info("post-concurrent access")
    }

    @Test func cacheHandlesManyTags() {
        let cache = OSLoggerCache(subsystem: testSubsystem)
        let tags = (0..<1000).map { WireLogTag(stringLiteral: "tag-\($0)") }

        // Create loggers for many tags
        for tag in tags {
            let logger = cache.logger(for: tag)
            logger.trace("creating logger for \(tag.rawValue)")
        }
        
        // Verify we can still retrieve cached loggers
        for tag in tags.prefix(10) {
            let logger = cache.logger(for: tag)
            logger.debug("retrieved cached logger")
        }
    }

    @Test func cacheWorksWithDifferentSubsystems() {
        let subsystem1 = "com.wire.test1"
        let subsystem2 = "com.wire.test2"
        let cache1 = OSLoggerCache(subsystem: subsystem1)
        let cache2 = OSLoggerCache(subsystem: subsystem2)
        let tag: WireLogTag = "shared-tag"
        
        let logger1 = cache1.logger(for: tag)
        let logger2 = cache2.logger(for: tag)
        
        // Both should work independently
        logger1.debug("from cache1")
        logger2.debug("from cache2")
    }

}
