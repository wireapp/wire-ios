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
import ZMUtilities
import MobileCoreServices;

class String_MIMETypeTests: XCTestCase {
    
    func testConformsToUTI() {
        // This test is only intended to validate that parameters are passed correctly to the underlaying 
        // function. No need to re-test UTTypeConformsTo from MobileCoreServices.
        
        XCTAssertTrue("video/mp4".zm_conforms(to: kUTTypeMPEG4))
        XCTAssertFalse("video/mp4".zm_conforms(to: kUTTypeQuickTimeMovie))
        
        XCTAssertTrue("video/mp4".zm_conforms(to: kUTTypeMovie))
        XCTAssertFalse("video/mp4".zm_conforms(to: kUTTypeAudio))
    }
}
