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

import WireTesting
import XCTest

@testable import WireImages

final class ImagePreprocessorTests: ZMTBaseTest {

    private var processingQueue: OperationQueue!

    override func setUp() {
        super.setUp()

        self.processingQueue = OperationQueue()
        self.processingQueue.name = "\(name).processingQueue"

    }

    override func tearDown()  {
        self.processingQueue = nil

        super.tearDown()
    }

    func testThatItCanCalculateTheSizeOfAnImage() {
        let imageURL = fileURL(forResource: "unsplash_medium", extension: "jpg")
        XCTAssertEqual(ZMImagePreprocessor.sizeOfPrerotatedImage(at: imageURL), CGSize(width: 531, height: 346))
    }

    func testThatItReturnsZeroSizeIfFileIsNotAnImage() {
        let imageURL = fileURL(forResource: "Lorem Ipsum", extension: "txt")
        XCTAssertEqual(ZMImagePreprocessor.sizeOfPrerotatedImage(at: imageURL), CGSize.zero)
    }

    func testThatItReturnsTheRotatedSizeForImagesWithATIFFOrientation() {
        let imageURL = fileURL(forResource: "unsplash_medium_exif_3", extension: "jpg")
        XCTAssertEqual(ZMImagePreprocessor.sizeOfPrerotatedImage(at: imageURL), CGSize(width: 531, height: 346))

        let imageURL2 = fileURL(forResource: "unsplash_medium_exif_6", extension: "jpg")
        XCTAssertEqual(ZMImagePreprocessor.sizeOfPrerotatedImage(at: imageURL2), CGSize(width: 531, height: 346))

        let imageURL3 = fileURL(forResource: "unsplash_medium_exif_8", extension: "jpg")
        XCTAssertEqual(ZMImagePreprocessor.sizeOfPrerotatedImage(at: imageURL3), CGSize(width: 531, height: 346))
    }
}
