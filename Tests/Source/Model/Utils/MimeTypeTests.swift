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

class MimeTypeTests: XCTestCase {

    func testThatItParsesVideoMimeTypeCorrectly_Positive() {
        XCTAssertTrue("video/mp4".isVideoMimeType())
        XCTAssertTrue("video/mpeg".isVideoMimeType())
        // WebM can be considered the video MIME type if the appropriate video player is installed on the operating system.
        XCTAssertFalse("video/webm".isVideoMimeType())
    }

    func testThatItParsesVideoMimeTypeCorrectly_Negative() {
        XCTAssertFalse("foo".isVideoMimeType())
        XCTAssertFalse("".isVideoMimeType())
        XCTAssertFalse("text/plain".isVideoMimeType())
        XCTAssertFalse("application/octet-stream".isVideoMimeType())
        XCTAssertFalse("audio/mpeg".isVideoMimeType())
        XCTAssertFalse(".mp4".isVideoMimeType())
    }
    
    func testThatItParsesAudioMimeTypeCorrectly_Positive() {
        XCTAssertTrue("audio/mp4".isAudioMimeType())
        XCTAssertTrue("audio/mpeg".isAudioMimeType())
        XCTAssertTrue("audio/x-m4a".isAudioMimeType())
    }
    
    func testThatItParsesAudioMimeTypeCorrectly_Negative() {
        XCTAssertFalse("foo".isAudioMimeType())
        XCTAssertFalse("".isAudioMimeType())
        XCTAssertFalse("text/plain".isAudioMimeType())
        XCTAssertFalse("application/octet-stream".isAudioMimeType())
        XCTAssertFalse(".mp4".isAudioMimeType())
        XCTAssertFalse("video/mp4".isAudioMimeType())
        XCTAssertFalse("video/mpeg".isAudioMimeType())
    }
    
    func testPlayableMimeType() {
        XCTAssertFalse("video/webm".isPlayableVideoMimeType())
    }

}
