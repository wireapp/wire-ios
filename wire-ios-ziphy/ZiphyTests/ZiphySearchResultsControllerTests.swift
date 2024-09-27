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

class ZiphySearchResultsControllerTests: XCTestCase {
    // MARK: Internal

    var requester: MockPaginatedRequester!
    var downloadRequester: MockZiphyRequester!
    var searchController: ZiphySearchResultsController!

    override func setUp() {
        super.setUp()
        requester = MockPaginatedRequester()
        downloadRequester = MockZiphyRequester()

        let client = ZiphyClient(host: "localhost", requester: requester, downloadSession: downloadRequester)
        searchController = ZiphySearchResultsController(client: client, pageSize: 5, maxImageSize: 5)
    }

    override func tearDown() {
        searchController = nil
        requester = nil
        downloadRequester = nil
        super.tearDown()
    }

    func testThatItPerformsInitialSearch() {
        // GIVEN
        let ziphs = makeRandomZiphs(count: 10)
        requester.response = .success(ziphs)

        // WHEN
        let fetchExpectation = expectation(description: "Initial search results are fetched.")
        var fetchResult: ZiphyResult<[Ziph]>?

        _ = searchController.search(withTerm: "hello") { result in
            fetchResult = result
            fetchExpectation.fulfill()
        }

        sendResponse(afterDelay: 1)
        waitForExpectations(timeout: 5, handler: nil)

        // THEN

        guard let result = fetchResult else {
            XCTFail("No fetch result was provided.")
            return
        }

        guard case let .success(fetchedZiphs) = result else {
            XCTFail("An error was thrown: \(result.error!)")
            return
        }

        XCTAssertEqual(fetchedZiphs.count, 5)
        XCTAssertEqual(searchController.paginationController?.offset, 5)

        XCTAssertTrue(fetchedZiphs.contains(where: { $0.identifier == "0" }))
        XCTAssertTrue(fetchedZiphs.contains(where: { $0.identifier == "1" }))
        XCTAssertTrue(fetchedZiphs.contains(where: { $0.identifier == "2" }))
        XCTAssertTrue(fetchedZiphs.contains(where: { $0.identifier == "3" }))
        XCTAssertTrue(fetchedZiphs.contains(where: { $0.identifier == "4" }))
        XCTAssertFalse(fetchedZiphs.contains(where: { $0.identifier == "5" }))
    }

    func testThatItPerformsInitialTrending() {
        // GIVEN
        let ziphs = makeRandomZiphs(count: 10)
        requester.response = .success(ziphs)

        // WHEN
        let fetchExpectation = expectation(description: "Initial trending images are fetched.")
        var fetchResult: ZiphyResult<[Ziph]>?

        _ = searchController.trending { result in
            fetchResult = result
            fetchExpectation.fulfill()
        }

        sendResponse(afterDelay: 1)
        waitForExpectations(timeout: 5, handler: nil)

        // THEN

        guard let result = fetchResult else {
            XCTFail("No fetch result was provided.")
            return
        }

        guard case let .success(fetchedZiphs) = result else {
            XCTFail("An error was thrown: \(result.error!)")
            return
        }

        XCTAssertEqual(fetchedZiphs.count, 5)
        XCTAssertEqual(searchController.paginationController?.offset, 5)

        XCTAssertTrue(fetchedZiphs.contains(where: { $0.identifier == "0" }))
        XCTAssertTrue(fetchedZiphs.contains(where: { $0.identifier == "1" }))
        XCTAssertTrue(fetchedZiphs.contains(where: { $0.identifier == "2" }))
        XCTAssertTrue(fetchedZiphs.contains(where: { $0.identifier == "3" }))
        XCTAssertTrue(fetchedZiphs.contains(where: { $0.identifier == "4" }))
        XCTAssertFalse(fetchedZiphs.contains(where: { $0.identifier == "5" }))
    }

    func testThatItFetchesImageData() {
        // GIVEN
        let ziph = makeLocalZiph()
        downloadRequester.response = makeFileResponse()

        // WHEN
        let downloadExpectation = expectation(description: "The image is downloaded.")
        var downloadResult: ZiphyResult<Data>?

        searchController.fetchImageData(for: ziph, imageType: .downsized) { result in
            downloadResult = result
            downloadExpectation.fulfill()
        }

        sendDownloadResponse(afterDelay: 1)
        waitForExpectations(timeout: 5, handler: nil)

        // THEN

        guard let result = downloadResult else {
            XCTFail("No download result was provided.")
            return
        }

        guard case let .success(data) = result else {
            XCTFail("An error was thrown: \(result.error!)")
            return
        }

        XCTAssertFalse(data.isEmpty)
        XCTAssertEqual(data.prefix(6), Data([0x47, 0x49, 0x46, 0x38, 0x39, 0x61])) // GIF89a header
    }

    func testThatItFetchesMoreSearchResults() {
        // GIVEN
        let ziphs = makeRandomZiphs(count: 10)
        requester.response = .success(ziphs)

        // WHEN
        let fetchExpectation = expectation(description: "Initial trending images are fetched.")

        _ = searchController.trending { _ in
            fetchExpectation.fulfill()
        }

        sendResponse(afterDelay: 1)
        waitForExpectations(timeout: 5, handler: nil)

        var fetchResult: ZiphyResult<[Ziph]>?
        let nextFetchExpectation = expectation(description: "Next trending images are fetched.")

        _ = searchController.fetchMoreResults { result in
            fetchResult = result
            nextFetchExpectation.fulfill()
        }

        sendResponse(afterDelay: 1)
        waitForExpectations(timeout: 5, handler: nil)

        // THEN

        guard let result = fetchResult else {
            XCTFail("No fetch result was provided.")
            return
        }

        guard case let .success(fetchedZiphs) = result else {
            XCTFail("An error was thrown: \(result.error!)")
            return
        }

        XCTAssertEqual(fetchedZiphs.count, 5)
        XCTAssertEqual(searchController.paginationController?.offset, 10)

        XCTAssertFalse(fetchedZiphs.contains(where: { $0.identifier == "4" }))
        XCTAssertTrue(fetchedZiphs.contains(where: { $0.identifier == "5" }))
        XCTAssertTrue(fetchedZiphs.contains(where: { $0.identifier == "6" }))
        XCTAssertTrue(fetchedZiphs.contains(where: { $0.identifier == "7" }))
        XCTAssertTrue(fetchedZiphs.contains(where: { $0.identifier == "8" }))
        XCTAssertTrue(fetchedZiphs.contains(where: { $0.identifier == "9" }))
    }

    func testThatItHandlesCancellation() {
        // GIVEN
        let ziphs = makeRandomZiphs(count: 10)
        requester.response = .success(ziphs)

        // WHEN
        let fetchExpectation = expectation(description: "Initial search results are fetched.")
        fetchExpectation.isInverted = true

        var fetchResult: ZiphyResult<[Ziph]>?

        let request = searchController.search(withTerm: "hello") { result in
            fetchResult = result
            fetchExpectation.fulfill()
        }

        request?.cancel()
        sendResponse(afterDelay: 1)
        waitForExpectations(timeout: 2, handler: nil)

        // THEN
        XCTAssertNil(fetchResult)
    }

    // MARK: Private

    // MARK: - Utilities

    private func makeRandomZiphs(count: Int) -> [Ziph] {
        var ziphs: [Ziph] = []

        for i in 0 ..< count {
            let id = String(i)
            let url = URL(string: "http://localhost/media/image\(id).gif")!
            let ziph = ZiphHelper.createZiph(id: id, url: url)
            ziphs.append(ziph)
        }

        return ziphs
    }

    private func sendResponse(afterDelay seconds: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(seconds)) {
            self.requester.respond()
        }
    }

    private func sendDownloadResponse(afterDelay seconds: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(seconds)) {
            self.downloadRequester.respond()
        }
    }

    private func makeLocalZiph() -> Ziph {
        let url = Bundle(for: ZiphySearchResultsControllerTests.self).url(forResource: "craig", withExtension: "gif")!

        let images: [ZiphyImageType: ZiphyAnimatedImage] = [
            .downsized: ZiphyAnimatedImage(url: url, width: 300, height: 200, fileSize: 5_000_000),
        ]

        return Ziph(identifier: "000000", images: ZiphyAnimatedImageList(images: images), title: "Craig dot GIF")
    }

    private func makeFileResponse() -> MockZiphyResponse {
        let url = Bundle(for: ZiphySearchResultsControllerTests.self).url(forResource: "craig", withExtension: "gif")!
        let data = try! Data(contentsOf: url)
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)!
        return .success(data, response)
    }
}
