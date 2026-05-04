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

import UniformTypeIdentifiers
import WireTesting
import XCTest

@testable import WireImages

final class ImageLoadOperationTests: ZMTBaseTest {

    func testThatItLoadsJPEGData() throws {
        // given
        let imageData = try XCTUnwrap(data(forResource: "unsplash_medium_exif_2", extension: "jpg"))
        let sut = try XCTUnwrap(ZMImageLoadOperation(imageData: imageData))
        expectation(for: NSPredicate(format: "isFinished == YES"), evaluatedWith: sut, handler: nil)

        // when
        sut.start()
        waitForExpectations(timeout: 5)

        // then
        let tiffDictionary = try XCTUnwrap(
            sut.sourceImageProperties[kCGImagePropertyTIFFDictionary] as? [AnyHashable: Any]
        )
        XCTAssertNotNil(sut.cgImage)
        XCTAssertEqual(tiffDictionary[kCGImagePropertyTIFFOrientation] as? Int, 2)
        XCTAssertEqual(sut.sourceImageProperties[kCGImagePropertyOrientation] as? Int, 2)
        XCTAssertEqual(sut.sourceImageProperties[kCGImagePropertyPixelHeight] as? Double, 346)
        XCTAssertEqual(sut.sourceImageProperties[kCGImagePropertyPixelWidth] as? Double, 531)
        XCTAssertEqual(sut.originalImageData, imageData)
        XCTAssertEqual(sut.computedImageProperties.mimeType, UTType.jpeg.identifier)
        XCTAssertEqual(sut.tiffOrientation, 2)
        XCTAssertEqual(sut.computedImageProperties.size, CGSize(width: 531, height: 346))
    }

    func testThatItDoesNotLoadWhenCancelled() throws {
        // given
        let imageData = try XCTUnwrap(data(forResource: "unsplash_medium", extension: "jpg"))
        let sut = try XCTUnwrap(ZMImageLoadOperation(imageData: imageData))
        sut.cancel()
        expectation(for: NSPredicate(format: "isFinished == YES"), evaluatedWith: sut, handler: nil)

        // when
        sut.start()
        waitForExpectations(timeout: 5)

        // then
        XCTAssertNil(sut.cgImage)
        XCTAssertNil(sut.sourceImageProperties)
    }

    func testThatItDoesNotCrashOnInvalidData() throws {
        // given
        let imageData = try XCTUnwrap(data(forResource: "Lorem Ipsum", extension: "txt"))
        let sut = try XCTUnwrap(ZMImageLoadOperation(imageData: imageData))
        expectation(for: NSPredicate(format: "isFinished == YES"), evaluatedWith: sut, handler: nil)

        // when
        sut.start()
        waitForExpectations(timeout: 5)
    }

}
