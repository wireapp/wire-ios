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

import WireTesting
import XCTest

@testable import WireImages

final class ImagePreprocessorTests: ZMTBaseTest {

    private var processingQueue: OperationQueue!

    override func setUp() {
        super.setUp()

        processingQueue = OperationQueue()
        processingQueue.name = "\(name).processingQueue"

    }

    override func tearDown() {
        processingQueue = nil

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

    func testThatItReturnsTheRotatedSizeForImagesWithTIFFOrientation5() {
        let properties: [String: Any] = [
            "ColorModel": "RGB",
            "DPIHeight": 72,
            "DPIWidth": 72,
            "Depth": 8,
            "Orientation": 5,
            "PixelHeight": 600,
            "PixelWidth": 450,
            "ProfileName": "Generic RGB Profile",
            "{Exif}": [
                "PixelXDimension": 450,
                "PixelYDimension": 600
            ],
            "{JFIF}": [
                "DensityUnit": 1,
                "JFIFVersion": [1, 0, 1],
                "XDensity": 72,
                "YDensity": 72
            ],
            "{TIFF}": [
                "Orientation": 5,
                "ResolutionUnit": 2,
                "XResolution": 72,
                "YResolution": 72
            ]
        ]
        let expected = CGSize(width: 600, height: 450)
        XCTAssertEqual(ZMImagePreprocessor.imageSize(fromProperties: properties), expected)
    }

    func testThatItReturnsTheRotatedSizeForImagesWithTIFFOrientation7() {
        let properties: [String: Any] = [
            "ColorModel": "RGB",
            "DPIHeight": 72,
            "DPIWidth": 72,
            "Depth": 8,
            "Orientation": 7,
            "PixelHeight": 450,
            "PixelWidth": 600,
            "ProfileName": "Generic RGB Profile",
            "{Exif}": [
                "PixelXDimension": 600,
                "PixelYDimension": 450
            ],
            "{JFIF}": [
                "DensityUnit": 1,
                "JFIFVersion": [1, 0, 1],
                "XDensity": 72,
                "YDensity": 72
            ],
            "{TIFF}": [
                "Orientation": 7,
                "ResolutionUnit": 2,
                "XResolution": 72,
                "YResolution": 72
            ]
        ]
        let expected = CGSize(width: 450, height: 600)
        XCTAssertEqual(ZMImagePreprocessor.imageSize(fromProperties: properties), expected)
    }

    func testThatItReturnsZeroSizeIfFileDoesNotExist() {
        let imageURL = URL(fileURLWithPath: "/foo/bar")
        XCTAssertEqual(ZMImagePreprocessor.sizeOfPrerotatedImage(at: imageURL), CGSize.zero)
    }

    func testThatItCanCalculateTheSizeOfAnImageFromData() {
        let imageData = data(forResource: "unsplash_medium", extension: "jpg")
        XCTAssertEqual(ZMImagePreprocessor.sizeOfPrerotatedImage(with: imageData), CGSize(width: 531, height: 346))
    }

    func testThatItReturnsZeroSizeIfDataIsNotAnImage() {
        let imageData = data(forResource: "Lorem Ipsum", extension: "txt")
        XCTAssertEqual(ZMImagePreprocessor.sizeOfPrerotatedImage(with: imageData), CGSize.zero)
    }
}
