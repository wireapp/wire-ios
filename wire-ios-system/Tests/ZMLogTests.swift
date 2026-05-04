//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

@testable import WireSystem

final class ZMLogTests: XCTestCase {

    override func setUp() {
        ZMSLog.debug_resetAllLevels()
        ZMSLog.clearLogs()
    }

    override func tearDown() {
        ZMSLog.debug_resetAllLevels()
        ZMSLog.removeAllLogHooks()
    }

    func testNumberOfPreviousZipLogURLs() {
        // given
        let count = ZMSLog.previousZipLogURLs.count

        // when
        // then
        XCTAssertEqual(count, 5)
    }

    func testThatTheLoggerRegistersATag() {

        // given
        let tag = "Foo"

        // when
        _ = ZMSLog(tag: tag)

        // then
        let allTags = ZMSLog.allTags
        XCTAssertTrue(allTags.contains(tag))
    }

    func testThatTheLoggerRegistersTheRightLevel() {

        // given
        let tag = "Test11"

        // when
        _ = ZMSLog(tag: tag)

        // then
        XCTAssertEqual(ZMSLog.getLevel(tag: tag), .warn)
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
        XCTAssertEqual(ZMSLog.allTags.count, 0)
    }

    func testThatLogIsRegistered() {

        // GIVEN
        let tag = "Async"

        // WHEN
        ZMSLog.register(tag: tag)

        // THEN
        XCTAssertTrue(ZMSLog.allTags.contains(tag))
    }

    func testThatTheLogTagIsRegisteredAfterInitializingLog() {

        // GIVEN
        let tag = "Network"

        // WHEN
        _ = ZMSLog(tag: tag)

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

    @MainActor
    func testThatLogHookIsCalledWithError() {

        // GIVEN
        let tag = "Network"
        let level = ZMLogLevel.error
        let message = "PANIC!"

        let expectation = expectation(description: "Log received")
        let token = ZMSLog.addEntryHook { _level, _tag, entry, _ in
            XCTAssertEqual(level, _level)
            XCTAssertEqual(tag, _tag)
            XCTAssertEqual(entry.text, message)
            expectation.fulfill()
        }

        // WHEN
        ZMSLog(tag: tag).error(message)

        // THEN
        waitForExpectations(timeout: 1)

        // AFTER
        ZMSLog.removeLogHook(token: token)
    }

    func testThatLogHookIsNotCalledWithInfo() {

        // GIVEN
        let tag = "Network"
        let level = ZMLogLevel.info
        let message = "PANIC!"

        let token = ZMSLog.addEntryHook { _level, _tag, entry, _ in
            XCTAssertEqual(level, _level)
            XCTAssertEqual(tag, _tag)
            XCTAssertEqual(entry.text, message)
        }

        // WHEN
        ZMSLog(tag: tag).info(message)

        // THEN
        Thread.sleep(forTimeInterval: 0.2)

        // AFTER
        ZMSLog.removeLogHook(token: token)
    }

    @MainActor
    func testThatLogHookIsCalledWithWarning() {

        // GIVEN
        let tag = "Network"
        let level = ZMLogLevel.warn
        let message = "PANIC!"

        let expectation = expectation(description: "Log received")
        let token = ZMSLog.addEntryHook { _level, _tag, entry, _ in
            XCTAssertEqual(level, _level)
            XCTAssertEqual(tag, _tag)
            XCTAssertEqual(entry.text, message)
            expectation.fulfill()
        }

        // WHEN
        ZMSLog(tag: tag).warn(message)

        // THEN
        waitForExpectations(timeout: 1)

        // AFTER
        ZMSLog.removeLogHook(token: token)
    }

    func testThatLogHookIsNotCalledWithDebug() {

        // GIVEN
        let tag = "Network"
        let level = ZMLogLevel.debug
        let message = "PANIC!"

        let token = ZMSLog.addEntryHook { _level, _tag, entry, _ in
            XCTAssertEqual(level, _level)
            XCTAssertEqual(tag, _tag)
            XCTAssertEqual(entry.text, message)
            XCTFail()
        }

        // WHEN
        ZMSLog(tag: tag).debug(message)

        // THEN
        Thread.sleep(forTimeInterval: 0.2)

        // AFTER
        ZMSLog.removeLogHook(token: token)
    }

    @MainActor
    func testThatLogHookIsCalledWithDebugIfEnabled() {

        // GIVEN
        let tag = "Network"
        let level = ZMLogLevel.debug
        let message = "PANIC!"

        let expectation = expectation(description: "Log received")
        let token = ZMSLog.addEntryHook { _level, _tag, entry, _ in
            XCTAssertEqual(level, _level)
            XCTAssertEqual(tag, _tag)
            XCTAssertEqual(entry.text, message)
            expectation.fulfill()
        }

        // WHEN
        ZMSLog.set(level: .debug, tag: tag)
        ZMSLog(tag: tag).debug(message)

        // THEN
        waitForExpectations(timeout: 1)

        // AFTER
        ZMSLog.removeLogHook(token: token)
    }

    func testThatLogHookIsNotCalledWhenRemoved() {

        // GIVEN
        let tag = "Network"
        let message = "PANIC!"

        let token = ZMSLog.addEntryHook { _, _, _, _ in
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

        _ = ZMSLog.addEntryHook { _, _, _, _ in
            XCTFail()
        }
        ZMSLog.removeAllLogHooks()

        // WHEN
        ZMSLog(tag: tag).error(message)
        Thread.sleep(forTimeInterval: 0.2)
    }

    @MainActor
    func testThatCallsMultipleLogHook() {

        // GIVEN
        let tag = "Network"
        let level = ZMLogLevel.error
        let message = "PANIC!"

        let expectation1 = expectation(description: "Log received")
        let expectation2 = expectation(description: "Log received")

        let token1 = ZMSLog.addEntryHook { _level, _tag, entry, _ in
            XCTAssertEqual(level, _level)
            XCTAssertEqual(tag, _tag)
            XCTAssertEqual(entry.text, message)
            expectation1.fulfill()
        }
        let token2 = ZMSLog.addEntryHook { _level, _tag, entry, _ in
            XCTAssertEqual(level, _level)
            XCTAssertEqual(tag, _tag)
            XCTAssertEqual(entry.text, message)
            expectation2.fulfill()
        }

        // WHEN
        ZMSLog(tag: tag).error(message)

        // THEN
        waitForExpectations(timeout: 1)

        // AFTER
        ZMSLog.removeLogHook(token: token1)
        ZMSLog.removeLogHook(token: token2)
    }
}

extension ZMLogTests {

    func testThatRecordedLogsAreNotWritedWhenNotStarted() {

        // GIVEN
        let sut = ZMSLog(tag: "foo")
        let currentLogBefore = FileManager.default.zipData(from: ZMSLog.currentLogURL)

        // WHEN
        sut.error("PANIC")

        // THEN
        let currentLogAfter = FileManager.default.zipData(from: ZMSLog.currentLogURL)
        XCTAssertEqual(currentLogBefore, currentLogAfter)

    }

}

extension ZMLogTests {

    func getLinesFromCurrentLog(file: StaticString = #filePath, line: UInt = #line) -> [String] {

        guard
            let currentLog = ZMSLog.currentLogURL,
            let data = FileManager.default.contents(atPath: currentLog.path)
        else {
            XCTFail(file: file, line: line)
            return []
        }

        var lines: [String] = []
        let logContent = String(decoding: data, as: UTF8.self)
        logContent.enumerateLines { str, _ in
            lines.append(str)
        }

        return lines
    }
}

private extension FileManager {

    func zipData(from url: URL?) -> Data? {
        guard
            let url,
            fileExists(atPath: url.path)
        else {
            return nil
        }

        var tmpURL = url.deletingLastPathComponent()
        tmpURL.appendPathComponent("\(UUID().uuidString).zip")

        try? zipItem(
            at: url,
            to: tmpURL,
            shouldKeepParent: false,
            compressionMethod: .deflate
        )

        defer {
            // clean up
            try? self.removeItem(at: tmpURL)
        }

        return try? Data(contentsOf: tmpURL, options: [.uncached])
    }
}
