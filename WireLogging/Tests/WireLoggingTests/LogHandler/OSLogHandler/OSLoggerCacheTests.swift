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

    @Test func loggerForTag_createsLoggerWithCorrectProperties() {
        let cache = OSLoggerCache(subsystem: testSubsystem)
        let tag: WireLogTag = "test-tag-1"
        
        let logger = cache.logger(for: tag)
        
        // Now we can verify the properties!
        #expect(logger.subsystem == testSubsystem)
        #expect(logger.category == tag.rawValue)
    }

    @Test func loggerForSameTag_returnsCachedInstance() {
        let cache = OSLoggerCache(subsystem: testSubsystem)
        let tag: WireLogTag = "test-tag-2"
        
        let logger1 = cache.logger(for: tag)
        let logger2 = cache.logger(for: tag)
        
        // Verify caching works - same subsystem and category
        #expect(logger1.subsystem == logger2.subsystem)
        #expect(logger1.category == logger2.category)
        #expect(logger1.category == tag.rawValue)
        
        // Verify both loggers are functional
        logger1.log(level: .debug, "test from logger1")
        logger2.log(level: .info, "test from logger2")
    }

    @Test func loggerForDifferentTags_createsDifferentLoggers() {
        let cache = OSLoggerCache(subsystem: testSubsystem)
        let tag1: WireLogTag = "test-tag-3"
        let tag2: WireLogTag = "test-tag-4"
        
        let logger1 = cache.logger(for: tag1)
        let logger2 = cache.logger(for: tag2)
        
        // Verify different categories
        #expect(logger1.category == tag1.rawValue)
        #expect(logger2.category == tag2.rawValue)
        #expect(logger1.category != logger2.category)
        #expect(logger1.subsystem == logger2.subsystem)
    }

    @Test func loggerUsesCorrectSubsystem() {
        let customSubsystem = "com.wire.custom"
        let cache = OSLoggerCache(subsystem: customSubsystem)
        let tag: WireLogTag = "test-tag-5"
        
        let logger = cache.logger(for: tag)
        
        #expect(logger.subsystem == customSubsystem)
        #expect(logger.category == tag.rawValue)
    }

    @Test func multipleTags_canBeCached() {
        let cache = OSLoggerCache(subsystem: testSubsystem)
        let tags: [WireLogTag] = ["tag-a", "tag-b", "tag-c", "tag-d", "tag-e"]
        
        var loggers: [any OSLoggerProtocol] = []
        for tag in tags {
            loggers.append(cache.logger(for: tag))
        }
        
        // Verify all loggers are created
        #expect(loggers.count == tags.count)
        
        // Verify all loggers have correct properties
        for (index, tag) in tags.enumerated() {
            #expect(loggers[index].subsystem == testSubsystem)
            #expect(loggers[index].category == tag.rawValue)
        }
        
        // Verify cache still works after multiple entries
        let cachedLogger = cache.logger(for: tags[0])
        #expect(cachedLogger.subsystem == testSubsystem)
        #expect(cachedLogger.category == tags[0].rawValue)
    }

    @Test func concurrentAccess_isThreadSafe() async {
        let cache = OSLoggerCache(subsystem: testSubsystem)
        let tags = (0..<100).map { WireLogTag(stringLiteral: "tag-\($0)") }
        
        await withTaskGroup(of: Void.self) { group in
            for tag in tags {
                group.addTask {
                    let logger = cache.logger(for: tag)
                    #expect(logger.subsystem == testSubsystem)
                    #expect(logger.category == tag.rawValue)
                    logger.log(level: .debug, "concurrent test")
                }
            }
        }
        
        // Verify cache still works after concurrent access
        let logger = cache.logger(for: tags[0])
        #expect(logger.subsystem == testSubsystem)
        #expect(logger.category == tags[0].rawValue)
    }

    @Test func cacheHandlesManyTags() {
        let cache = OSLoggerCache(subsystem: testSubsystem)
        let tags = (0..<1000).map { WireLogTag(stringLiteral: "tag-\($0)") }

        // Create loggers for many tags
        for tag in tags {
            let logger = cache.logger(for: tag)
            #expect(logger.category == tag.rawValue)
        }
        
        // Verify we can still retrieve cached loggers
        for tag in tags.prefix(10) {
            let logger = cache.logger(for: tag)
            #expect(logger.category == tag.rawValue)
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
        
        // Verify different subsystems
        #expect(logger1.subsystem == subsystem1)
        #expect(logger2.subsystem == subsystem2)
        #expect(logger1.subsystem != logger2.subsystem)
        #expect(logger1.category == logger2.category) // Same category
    }

    @Test func cacheCanUseMockLogger() {
        // Create a mock logger factory
        var createdLoggers: [(subsystem: String, category: String)] = []
        let mockFactory: (String, String) -> any OSLoggerProtocol = { subsystem, category in
            createdLoggers.append((subsystem, category))
            return MockLogger(subsystem: subsystem, category: category)
        }
        
        let cache = OSLoggerCache(subsystem: testSubsystem, loggerFactory: mockFactory)
        let tag: WireLogTag = "mock-tag"
        
        // First call should create a logger
        let logger1 = cache.logger(for: tag)
        #expect(createdLoggers.count == 1)
        #expect(createdLoggers[0].subsystem == testSubsystem)
        #expect(createdLoggers[0].category == tag.rawValue)
        
        // Second call should use cached logger (no new creation)
        let logger2 = cache.logger(for: tag)
        #expect(createdLoggers.count == 1) // Still only one creation
        #expect(logger1.subsystem == logger2.subsystem)
        #expect(logger1.category == logger2.category)
    }

}

// MARK: - Mock Logger for Testing

private struct MockLogger: OSLoggerProtocol, Equatable {
    let subsystem: String
    let category: String
    var loggedMessages: [(level: OSLogType, message: String)] = []
    
    func log(level: OSLogType, _ message: String) {
        // In a real mock, you might want to store this for verification
        // For now, we just verify it can be called
    }
    
    static func == (lhs: MockLogger, rhs: MockLogger) -> Bool {
        lhs.subsystem == rhs.subsystem && lhs.category == rhs.category
    }
}
