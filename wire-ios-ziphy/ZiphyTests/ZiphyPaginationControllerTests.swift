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

class ZiphyPaginationControllerTests: XCTestCase {
    // MARK: Internal

    var paginationController: ZiphyPaginationController!

    override func setUp() {
        super.setUp()
        paginationController = ZiphyPaginationController()
    }

    override func tearDown() {
        paginationController = nil
        super.tearDown()
    }

    func testThatItUpdatesPaginationState() {
        // GIVEN
        let page1 = makePage1()

        // WHEN
        paginationController.updatePagination(page1, filter: { $0.title?.contains("GIF") == false })

        // THEN
        XCTAssertEqual(paginationController.offset, 2)
        XCTAssertTrue(paginationController.ziphs.contains(where: { $0.identifier == "2WifJGUWMwGTdbcY15" }))
        XCTAssertTrue(paginationController.ziphs.contains(where: { $0.identifier == "3oz8xEqn8AGAQbR0yY" }))
        XCTAssertFalse(paginationController.ziphs.contains(where: { $0.identifier == "8qFOTu7r79Bzt7zMfT" }))
    }

    func testThatItReturnsOnlyNewItemsAfterAddedPaginationState() {
        // GIVEN
        let page1 = makePage1()
        let page2 = makePage2()

        paginationController.updatePagination(page1, filter: { _ in true })

        // WHEN
        var updateResult: ZiphyResult<[Ziph]>?
        let updateExpectation = expectation(description: "The update block should be called.")

        paginationController.updateBlock = { result in
            updateResult = result
            updateExpectation.fulfill()
        }

        paginationController.updatePagination(page2, filter: nil)
        waitForExpectations(timeout: 5, handler: nil)

        // THEN

        guard let result = updateResult else {
            XCTFail("The update block was not called.")
            return
        }

        guard case let .success(insertedZiphs) = result else {
            XCTFail("The update returned an error: \(result.error!)")
            return
        }

        XCTAssertEqual(insertedZiphs.count, 1)
        XCTAssertTrue(insertedZiphs.contains(where: { $0.identifier == "JzOyy8vKMCwvK" }))

        XCTAssertEqual(paginationController.offset, 4)
        XCTAssertTrue(paginationController.ziphs.contains(where: { $0.identifier == "2WifJGUWMwGTdbcY15" }))
        XCTAssertTrue(paginationController.ziphs.contains(where: { $0.identifier == "3oz8xEqn8AGAQbR0yY" }))
        XCTAssertTrue(paginationController.ziphs.contains(where: { $0.identifier == "8qFOTu7r79Bzt7zMfT" }))
        XCTAssertTrue(paginationController.ziphs.contains(where: { $0.identifier == "JzOyy8vKMCwvK" }))
    }

    func testThatItDetectsEnd() {
        // WHEN
        var updateResult: ZiphyResult<[Ziph]>?
        let updateExpectation = expectation(description: "The update block should be called.")

        paginationController.updateBlock = { result in
            updateResult = result
            updateExpectation.fulfill()
        }

        paginationController.updatePagination(.failure(.noMorePages), filter: nil)
        waitForExpectations(timeout: 5, handler: nil)

        // THEN

        guard let result = updateResult else {
            XCTFail("The update block was not called.")
            return
        }

        guard case let .failure(updateError) = result else {
            XCTFail("The update returned a value, but an error was expected.")
            return
        }

        guard case .noMorePages = updateError else {
            XCTFail("Expected 'noMorePages' error, but \(updateError) was returned.")
            return
        }

        XCTAssertTrue(paginationController.isAtEnd)
    }

    func testThatItDoesNotCallFetchBlockWhenAtEnd() {
        // GIVEN
        paginationController.updatePagination(.failure(.noMorePages), filter: nil)

        // WHEN
        let noFetchExpectation = expectation(description: "The fetch block is not called.")
        noFetchExpectation.isInverted = true

        paginationController.fetchBlock = { _ in
            noFetchExpectation.fulfill()
            return nil
        }

        _ = paginationController.fetchNewPage()

        // THEN
        waitForExpectations(timeout: 1, handler: nil)
    }

    // MARK: Private

    // MARK: - Utilities

    private func makePage1() -> ZiphyResult<[Ziph]> {
        let image1 = Ziph(
            identifier: "2WifJGUWMwGTdbcY15",
            images: ZiphyAnimatedImageList(images: [:]),
            title: "neil patrick harris"
        )
        let image2 = Ziph(
            identifier: "8qFOTu7r79Bzt7zMfT",
            images: ZiphyAnimatedImageList(images: [:]),
            title: "tired monday GIF"
        )
        let image3 = Ziph(
            identifier: "3oz8xEqn8AGAQbR0yY",
            images: ZiphyAnimatedImageList(images: [:]),
            title: "roxxxy andrews yes"
        )

        return .success([image1, image2, image3])
    }

    private func makePage2() -> ZiphyResult<[Ziph]> {
        let image1 = Ziph(
            identifier: "JzOyy8vKMCwvK",
            images: ZiphyAnimatedImageList(images: [:]),
            title: "judge judy bored over it"
        )
        return .success([image1])
    }
}
