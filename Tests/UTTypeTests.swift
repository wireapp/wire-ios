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
import WireUtilities
#if os(iOS)
import MobileCoreServices;
#endif

class UTTypeTests: XCTestCase {

    func testThatItConvertsFromMIMEType() {
        // MIME to UTType
        guard let mp4Type = UTType(mimeType: "video/mp4") else {
            return XCTFail("Could not decode from MIME type.")
        }

        XCTAssertNotNil(mp4Type)
        XCTAssertEqual(mp4Type, UTType(kUTTypeMPEG4))
        XCTAssertTrue(mp4Type == kUTTypeMPEG4)
        XCTAssertTrue(mp4Type.conformsTo(kUTTypeMovie))
        XCTAssertFalse(mp4Type.conformsTo(UTType(kUTTypeAudio)))

        // Details
        XCTAssertNotNil(mp4Type.localizedDescription)

        // UTType to file extension
        XCTAssertEqual(mp4Type.mimeType, "video/mp4")
    }

    func testThatItConvertsFromFileExtension() {
        // File extension to UTType
        guard let mp4Type = UTType(fileExtension: "mp4") else {
            return XCTFail("Could not decode from file extension.")
        }

        XCTAssertNotNil(mp4Type)
        XCTAssertEqual(mp4Type, UTType(kUTTypeMPEG4))
        XCTAssertTrue(mp4Type == kUTTypeMPEG4)
        XCTAssertTrue(mp4Type.conformsTo(kUTTypeMPEG4))
        XCTAssertFalse(mp4Type.conformsTo(UTType(kUTTypeAudio)))

        // Details
        XCTAssertNotNil(mp4Type.localizedDescription)

        // UTType to file extension
        XCTAssertEqual(mp4Type.fileExtension, "mp4")
    }

}
