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
// along with this program. If not, see <http://www.gnu.org/licenses/>.
// 


import XCTest

class MimeTypeTests: XCTestCase {

    func testThatItParsesVideoMimeTypeCorrectly_Positive() {
        XCTAssertTrue(("video/mp4" as NSString).isVideoMimeType())
        XCTAssertTrue(("video/mpeg" as NSString).isVideoMimeType())
    }

    func testThatItParsesVideoMimeTypeCorrectly_Negative() {
        XCTAssertFalse(("foo" as NSString).isVideoMimeType())
        XCTAssertFalse(("" as NSString).isVideoMimeType())
        XCTAssertFalse(("text/plain" as NSString).isVideoMimeType())
        XCTAssertFalse(("application/octet-stream" as NSString).isVideoMimeType())
        XCTAssertFalse(("audio/mpeg" as NSString).isVideoMimeType())
        XCTAssertFalse((".mp4" as NSString).isVideoMimeType())
    }
    
    func testThatItParsesAudioMimeTypeCorrectly_Positive() {
        XCTAssertTrue(("audio/mp4" as NSString).isAudioMimeType())
        XCTAssertTrue(("audio/mpeg" as NSString).isAudioMimeType())
        XCTAssertTrue(("audio/x-m4a" as NSString).isAudioMimeType())
    }
    
    func testThatItParsesAudioMimeTypeCorrectly_Negative() {
        XCTAssertFalse(("foo" as NSString).isAudioMimeType())
        XCTAssertFalse(("" as NSString).isAudioMimeType())
        XCTAssertFalse(("text/plain" as NSString).isAudioMimeType())
        XCTAssertFalse(("application/octet-stream" as NSString).isAudioMimeType())
        XCTAssertFalse((".mp4" as NSString).isAudioMimeType())
        XCTAssertFalse(("video/mp4" as NSString).isAudioMimeType())
        XCTAssertFalse(("video/mpeg" as NSString).isAudioMimeType())
    }

}
