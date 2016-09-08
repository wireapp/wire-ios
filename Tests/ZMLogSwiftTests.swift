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


import UIKit
import XCTest
import ZMCSystem

class ZMLogSwiftTests: XCTestCase {

    override func tearDown() {
        resetLogLevels();
    }
    
    func testThatTheLoggerRegistersATag() {
        
        // given
        let tag = "Foo"
        
        // when
        let _ = ZMSLog(tag: tag)
        
        // then
        let allTags = ZMLogGetAllTags() as! Set<String>
        XCTAssert(allTags.contains(tag))
    }
    
    func testThatTheLoggerRegistersTheRightLevel() {
        
        // given
        let tag = "Test11"
        
        // when
        let _ = ZMSLog(tag: tag)
        
        // then
        XCTAssertEqual(ZMLogGetLevelForTag(tag), ZMLogLevel_t.warn)
    }
    
    func testThatTheLevelIsDebug() {
        
        // given
        let tag = "22test"
        let sut = ZMSLog(tag: tag)
        ZMLogSetLevelForTag(.debug, tag)
        
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
        ZMLogSetLevelForTag(.warn, tag)
        
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
        ZMLogSetLevelForTag(.info, tag)
        
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
        ZMLogSetLevelForTag(.error, tag)
        
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
