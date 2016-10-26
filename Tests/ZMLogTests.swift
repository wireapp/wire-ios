// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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


import XCTest
@testable import ZMCSystem

class ZMLogTests: XCTestCase {

    override func setUp() {
        super.setUp()
        ZMSLog.debug_resetAllLevels();
    }
    
    override func tearDown() {
        ZMSLog.debug_resetAllLevels();
        ZMSLog.stopRecording()
        ZMSLog.removeAllLogHooks()
        super.tearDown()
    }
    
    func testThatTheLoggerRegistersATag() {
        
        // given
        let tag = "Foo"
        
        // when
        let _ = ZMSLog(tag: tag)
        
        // then
        let allTags = ZMSLog.allTags
        XCTAssertTrue(allTags.contains(tag))
    }
    
    func testThatTheLoggerRegistersTheRightLevel() {
        
        // given
        let tag = "Test11"
        
        // when
        let _ = ZMSLog(tag: tag)
        
        // then
        XCTAssertEqual(ZMSLog.getLevel(tag: tag), ZMLogLevel_t.warn)
    }
    
    func testThatTheLevelIsDebug() {
        
        // given
        let tag = "22test"
        let sut = ZMSLog(tag: tag)
        ZMSLog.set(level: .debug, tag: tag)
        
        // when
        var isDebug = false
        var isWarn = false
        var isInfo = false
        sut.ifDebug { isDebug = true }
        sut.ifInfo { isInfo = true }
        sut.ifWarn { isWarn = true }
        
        // then
        XCTAssertTrue(isDebug)
        XCTAssertTrue(isInfo)
        XCTAssertTrue(isWarn)
    }
    
    func testThatTheLevelIsWarn() {
        
        // given
        let tag = "22test"
        let sut = ZMSLog(tag: tag)
        ZMSLog.set(level: .warn, tag: tag)
        
        // when
        var isDebug = false
        var isWarn = false
        var isInfo = false
        sut.ifDebug { isDebug = true }
        sut.ifInfo { isInfo = true }
        sut.ifWarn { isWarn = true }
        
        // then
        XCTAssertFalse(isDebug)
        XCTAssertFalse(isInfo)
        XCTAssertTrue(isWarn)
    }
    
    func testThatTheLevelIsInfo() {
        
        // given
        let tag = "22test"
        let sut = ZMSLog(tag: tag)
        ZMSLog.set(level: .info, tag: tag)
        
        // when
        var isDebug = false
        var isWarn = false
        var isInfo = false
        sut.ifDebug { isDebug = true }
        sut.ifInfo { isInfo = true }
        sut.ifWarn { isWarn = true }
        
        // then
        XCTAssertFalse(isDebug)
        XCTAssertTrue(isInfo)
        XCTAssertTrue(isWarn)
    }
    
    func testThatTheLevelIsError() {
        
        // given
        let tag = "22test"
        let sut = ZMSLog(tag: tag)
        ZMSLog.set(level: .error, tag: tag)
        
        // when
        var isDebug = false
        var isWarn = false
        var isInfo = false
        sut.ifDebug { isDebug = true }
        sut.ifInfo { isInfo = true }
        sut.ifWarn { isWarn = true }
        
        // then
        XCTAssertFalse(isDebug)
        XCTAssertFalse(isInfo)
        XCTAssertFalse(isWarn)
    }
}

// MARK: - Log level management
extension ZMLogTests {
    
    func testThatLogIsNotRegisteredIfNoLogIsCalled() {
        XCTAssertEqual(ZMSLog.allTags.count, 0);
    }

    func testThatLogIsRegistered() {
        
        // GIVEN
        let tag = "Async"
        
        // WHEN
        ZMSLog.register(tag: tag)
        
        // THEN
        XCTAssertTrue(ZMSLog.allTags.contains(tag));
    }
    
    func testThatTheLogTagIsRegisteredAfterInitializingLog() {
        
        // GIVEN
        let tag = "Network"
        
        // WHEN
        let _ = ZMSLog(tag: tag)
        
        // THEN
        XCTAssertTrue(ZMSLog.allTags.contains(tag))
    }
    
    func testThatTheDefaultLogLevelIsWarning() {
        XCTAssertEqual(ZMSLog.getLevel(tag: "1234"), .warn)
    }

    func testThatTheLogLevelCanBeChanged() {
        
        // GIVEN
        let tag = "Draw"
        
        // WHEN
        ZMSLog.set(level: .debug, tag: tag)
        
        // THEN
        XCTAssertEqual(ZMSLog.getLevel(tag: tag), .debug)
    }
}

// MARK: - Debug hook
extension ZMLogTests {
    
    func testThatLogHookIsCalledWithError() {
        
        // GIVEN
        let tag = "Network"
        let level = ZMLogLevel_t.error
        let message = "PANIC!"
        
        let expectation = self.expectation(description: "Log received")
        let token = ZMSLog.addHook { (_level, _tag, _message) in
            XCTAssertEqual(level, _level)
            XCTAssertEqual(tag, _tag)
            XCTAssertEqual(message, _message)
            expectation.fulfill()
        }
        
        // WHEN
        ZMSLog(tag: tag).error(message)
        
        // THEN
        self.waitForExpectations(timeout: 0.5)
        
        // AFTER
        ZMSLog.removeLogHook(token: token)
    }
    
    func testThatLogHookIsNotCalledWithInfo() {
        
        // GIVEN
        let tag = "Network"
        let level = ZMLogLevel_t.info
        let message = "PANIC!"
        
        let token = ZMSLog.addHook { (_level, _tag, _message) in
            XCTAssertEqual(level, _level)
            XCTAssertEqual(tag, _tag)
            XCTAssertEqual(message, _message)
        }
        
        // WHEN
        ZMSLog(tag: tag).info(message)
        
        // THEN
        Thread.sleep(forTimeInterval: 0.2)
        
        // AFTER
        ZMSLog.removeLogHook(token: token)
    }
    
    func testThatLogHookIsCalledWithWarning() {
        
        // GIVEN
        let tag = "Network"
        let level = ZMLogLevel_t.warn
        let message = "PANIC!"
        
        let expectation = self.expectation(description: "Log received")
        let token = ZMSLog.addHook { (_level, _tag, _message) in
            XCTAssertEqual(level, _level)
            XCTAssertEqual(tag, _tag)
            XCTAssertEqual(message, _message)
            expectation.fulfill()
        }
        
        // WHEN
        ZMSLog(tag: tag).warn(message)
        
        // THEN
        self.waitForExpectations(timeout: 0.5)
        
        // AFTER
        ZMSLog.removeLogHook(token: token)
    }
    
    func testThatLogHookIsNotCalledWithDebug() {
        
        // GIVEN
        let tag = "Network"
        let level = ZMLogLevel_t.debug
        let message = "PANIC!"
        
        let token = ZMSLog.addHook { (_level, _tag, _message) in
            XCTAssertEqual(level, _level)
            XCTAssertEqual(tag, _tag)
            XCTAssertEqual(message, _message)
            XCTFail()
        }
        
        // WHEN
        ZMSLog(tag: tag).debug(message)
        
        // THEN
        Thread.sleep(forTimeInterval: 0.2)
        
        // AFTER
        ZMSLog.removeLogHook(token: token)
    }
    
    func testThatLogHookIsCalledWithDebugIfEnabled() {
        
        // GIVEN
        let tag = "Network"
        let level = ZMLogLevel_t.debug
        let message = "PANIC!"
        
        let expectation = self.expectation(description: "Log received")
        let token = ZMSLog.addHook { (_level, _tag, _message) in
            XCTAssertEqual(level, _level)
            XCTAssertEqual(tag, _tag)
            XCTAssertEqual(message, _message)
            expectation.fulfill()
        }
        
        // WHEN
        ZMSLog.set(level: .debug, tag: tag)
        ZMSLog(tag: tag).debug(message)
        
        // THEN
        self.waitForExpectations(timeout: 0.5)
        
        // AFTER
        ZMSLog.removeLogHook(token: token)
    }
    
    func testThatLogHookIsNotCalledWhenRemoved() {
        
        // GIVEN
        let tag = "Network"
        let message = "PANIC!"

        let token = ZMSLog.addHook { (_level, _tag, _message) in
            XCTFail()
        }
        ZMSLog.removeLogHook(token: token)
        
        // WHEN
        ZMSLog(tag: tag).error(message)
        Thread.sleep(forTimeInterval: 0.2)
    }
    
    
    func testThatLogHookIsNotCalledWhenRemovedAll() {
        
        // GIVEN
        let tag = "Network"
        let message = "PANIC!"
        
        let _ = ZMSLog.addHook { (_level, _tag, _message) in
            XCTFail()
        }
        ZMSLog.removeAllLogHooks()
        
        // WHEN
        ZMSLog(tag: tag).error(message)
        Thread.sleep(forTimeInterval: 0.2)
    }
    
    func testThatCallsMultipleLogHook() {
        
        // GIVEN
        let tag = "Network"
        let level = ZMLogLevel_t.error
        let message = "PANIC!"
        
        let expectation1 = self.expectation(description: "Log received")
        let expectation2 = self.expectation(description: "Log received")

        let token1 = ZMSLog.addHook { (_level, _tag, _message) in
            XCTAssertEqual(level, _level)
            XCTAssertEqual(tag, _tag)
            XCTAssertEqual(message, _message)
            expectation1.fulfill()
        }
        let token2 = ZMSLog.addHook { (_level, _tag, _message) in
            XCTAssertEqual(level, _level)
            XCTAssertEqual(tag, _tag)
            XCTAssertEqual(message, _message)
            expectation2.fulfill()
        }
        
        // WHEN
        ZMSLog(tag: tag).error(message)
        
        // THEN
        self.waitForExpectations(timeout: 0.5)
        
        // AFTER
        ZMSLog.removeLogHook(token: token1)
        ZMSLog.removeLogHook(token: token2)
    }
}

extension ZMLogTests {
    
    func testThatRecordedLogsAreEmptyWhenNotStarted() {
        
        // GIVEN
        let sut = ZMSLog(tag: "foo")
        
        // WHEN
        sut.error("PANIC")
        
        // THEN
        XCTAssertEqual(ZMSLog.recordedContent, [])
        
    }
    
    func testThatItRecordsLogs() {
        
        // GIVEN
        let sut = ZMSLog(tag: "foo")
        ZMSLog.startRecording()
        
        // WHEN
        sut.error("PANIC")
        sut.error("HELP")
        
        // THEN
        guard let logLine = ZMSLog.recordedContent.first else {
            XCTFail()
            return
        }
        XCTAssertTrue(logLine.hasSuffix("[0] [foo] PANIC"))
        XCTAssertEqual(ZMSLog.recordedContent.count, 2)
    }
    
    func testThatItDiscardsLogsWhenStopped() {
        
        // GIVEN
        let sut = ZMSLog(tag: "foo")
        ZMSLog.startRecording()
        
        // WHEN
        sut.error("PANIC")
        sut.error("HELP")
        ZMSLog.stopRecording()
        
        // THEN
        XCTAssertTrue(ZMSLog.recordedContent.isEmpty)
    }
}
