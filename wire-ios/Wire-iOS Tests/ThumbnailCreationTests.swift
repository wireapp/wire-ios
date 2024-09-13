//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

import WireTestingPackage
import XCTest

@testable import Wire

final class ThumbnailCreationTests: XCTestCase {
    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper!
    private var squareImage: UIImage!
    private var verticalPanoramaImage: UIImage!
    private var horizontalPanoramaImage: UIImage!
    private var squareImageData: Data!
    private var verticalPanoramaImageData: Data!
    private var horizontalPanoramaImageData: Data!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        squareImage = image(inTestBundleNamed: "unsplash_square.jpg")
        verticalPanoramaImage = image(inTestBundleNamed: "unsplash_vertical_pano.jpg")
        horizontalPanoramaImage = image(inTestBundleNamed: "unsplash_pano.jpg")

        guard let squareData = squareImage?.imageData,
              let verticalData = verticalPanoramaImage?.imageData,
              let horizontalData = horizontalPanoramaImage?.imageData else {
            XCTFail("Failed to create image data")
            return
        }

        squareImageData = squareData
        verticalPanoramaImageData = verticalData
        horizontalPanoramaImageData = horizontalData
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        squareImage = nil
        verticalPanoramaImage = nil
        horizontalPanoramaImage = nil
        squareImageData = nil
        verticalPanoramaImageData = nil
        horizontalPanoramaImageData = nil

        super.tearDown()
    }

    // MARK: - Snapshot Tests

    func testThatItCreatesThumbnailForSquareImage() {
        // GIVEN
        guard let data = squareImageData else {
            return XCTFail("Failed to create image data")
        }

        // WHEN
        guard let thumbnail = UIImage(from: data, withShorterSideLength: 100 * UIScreen.main.scale) else {
            return XCTFail("Failed to create thumbnail")
        }

        // THEN
        XCTAssertEqual(thumbnail.size.width, 100, accuracy: 1)
        XCTAssertEqual(thumbnail.size.height, 100, accuracy: 1)
        snapshotHelper.verify(matching: thumbnail.wrappedInImageView())
    }

    func testThatItCreatesThumbnailForVerticalPanorama() {
        // GIVEN
        guard let data = verticalPanoramaImageData else {
            return XCTFail("Failed to create image data")
        }

        // WHEN
        guard let thumbnail = UIImage(from: data, withShorterSideLength: 100 * UIScreen.main.scale) else {
            return XCTFail("Failed to create thumbnail")
        }

        // THEN
        XCTAssertEqual(thumbnail.size.width, 100, accuracy: 1)
        snapshotHelper.verify(matching: thumbnail.wrappedInImageView())
    }

    func testThatItCreatesThumbnailForHorizontalPanorama() {
        // GIVEN
        guard let data = horizontalPanoramaImageData else {
            return XCTFail("Failed to create image data")
        }

        // WHEN
        guard let thumbnail = UIImage(from: data, withShorterSideLength: 100 * UIScreen.main.scale) else {
            return XCTFail("Failed to create a thumbnail")
        }

        // THEN
        XCTAssertEqual(thumbnail.size.height, 100, accuracy: 1)
        snapshotHelper.verify(matching: thumbnail.wrappedInImageView())
    }

    // MARK: - Unit Test

    func testThatItReturnsEarlyForInvalidImage() {
        // GIVEN & WHEN
        let thumbnail = UIImage(from: Data(), withShorterSideLength: 100 * UIScreen.main.scale)

        // THEN
        XCTAssertNil(thumbnail)
    }
}

// MARK: - Helper

extension UIImage {
    fileprivate func wrappedInImageView() -> UIImageView {
        let view = UIImageView()
        view.frame = CGRect(origin: .zero, size: size)
        view.image = self
        view.contentMode = .center
        return view
    }
}
