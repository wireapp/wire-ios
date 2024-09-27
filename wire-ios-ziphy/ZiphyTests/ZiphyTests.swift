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

import XCTest
@testable import Ziphy

final class ZiphTests: XCTestCase {
    // MARK: Internal

    var sut: Ziph!

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testThatPreviewImageReturnsPreviewValue() {
        // GIVEN
        let id = String(1)
        let url = URL(string: "http://localhost/media/image\(id).gif")!
        sut = ZiphHelper.createZiph(id: id, url: url)

        // WHEN & THEN
        let previewImage = sut.images[.preview]
        XCTAssertEqual(sut.previewImage?.description, previewImage?.description)
    }

    func testThatPreviewImageReturnsFallbackIfNoPreviewValue() {
        // GIVEN
        let id = String(1)
        let url = URL(string: "http://localhost/media/image\(id).gif")!

        let imagesList: [ZiphyImageType: ZiphyAnimatedImage] = [
            .fixedWidthDownsampled: ZiphyAnimatedImage(url: url, width: 300, height: 200, fileSize: 204_800),
            .original: ZiphyAnimatedImage(url: url, width: 300, height: 200, fileSize: 2_048_000),
            .downsized: ZiphyAnimatedImage(url: url, width: 300, height: 200, fileSize: 5_000_000),
        ]

        sut = ZiphHelper.createZiph(id: id, url: url, imagesList: imagesList)

        // WHEN & THEN
        let previewImage = sut.images[.fixedWidthDownsampled]
        XCTAssertEqual(sut.previewImage?.description, previewImage?.description)
    }

    func testThatPreviewImageReturnsOriginalCase() {
        // GIVEN
        let id = String(1)
        let url = URL(string: "http://localhost/media/image\(id).gif")!

        let imagesList: [ZiphyImageType: ZiphyAnimatedImage] = [
            .original: ZiphyAnimatedImage(url: url, width: 300, height: 200, fileSize: 2_048_000),
        ]

        sut = ZiphHelper.createZiph(id: id, url: url, imagesList: imagesList)

        // WHEN & THEN
        let previewImage = sut.images[.original]
        XCTAssertEqual(sut.previewImage?.description, previewImage?.description)
    }

    func testThatPreviewImageReturnsNilCase() {
        // GIVEN
        let id = String(1)
        let url = URL(string: "http://localhost/media/image\(id).gif")!

        let imagesList: [ZiphyImageType: ZiphyAnimatedImage] = [:]

        sut = ZiphHelper.createZiph(id: id, url: url, imagesList: imagesList)

        // WHEN & THEN
        let nilImage: ZiphyAnimatedImage? = nil
        XCTAssertEqual(sut.previewImage?.description, nilImage?.description)
    }

    // MARK: Fileprivate

    /// Example checker method which can be reused in different tests
    fileprivate func checkerExample(file: StaticString = #file, line: UInt = #line) {
        XCTAssert(true, file: file, line: line)
    }
}
