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

final class DecodeImageOperationTests: XCTestCase {
    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper!
    private var operationQueue: OperationQueue!
    private var sut: UIImageView!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        operationQueue = OperationQueue()
        sut = UIImageView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        sut.contentMode = .scaleAspectFit
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        operationQueue = nil
        super.tearDown()
    }

    // MARK: - Snapshot Test

    func testThatItDecodedValidImageData() {
        // GIVEN
        let decodeOperation = DecodeImageOperation(imageData: loadTestImageData())
        let completionExpectation = expectation(description: "The image is decoded")

        var image: UIImage?

        // WHEN

        decodeOperation.completionBlock = {
            image = decodeOperation.decodedImage
            completionExpectation.fulfill()
        }

        operationQueue.addOperation(decodeOperation)
        waitForExpectations(timeout: 5, handler: nil)

        // THEN
        sut.image = image
        snapshotHelper.verify(matching: sut)
    }

    // MARK: - Unit Test

    func testThatItDoesNotDecodeInvalidImageData() {
        // GIVEN
        let decodeOperation = DecodeImageOperation(imageData: loadTestFileData())
        let completionExpectation = expectation(description: "The image is decoded")

        var image: UIImage?

        // WHEN

        decodeOperation.completionBlock = {
            image = decodeOperation.decodedImage
            completionExpectation.fulfill()
        }

        operationQueue.addOperation(decodeOperation)
        waitForExpectations(timeout: 5, handler: nil)

        // THEN
        XCTAssertNil(image)
    }

    // MARK: - Utilities

    private func loadTestImageData() -> Data {
        let url = Bundle(for: DecodeImageOperationTests.self).url(forResource: "identicon", withExtension: "png")!
        return try! Data(contentsOf: url)
    }

    private func loadTestFileData() -> Data {
        let url = Bundle(for: DecodeImageOperationTests.self).url(forResource: "0x0", withExtension: "pdf")!
        return try! Data(contentsOf: url)
    }
}
