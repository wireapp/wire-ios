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

class ZiphyClientTests: XCTestCase {
    // MARK: Internal

    var requester: MockZiphyRequester!
    var client: ZiphyClient!

    override func setUp() {
        super.setUp()
        requester = MockZiphyRequester()
        client = ZiphyClient(host: "localhost", requester: requester, downloadSession: requester)
    }

    override func tearDown() {
        client = nil
        requester = nil
        super.tearDown()
    }

    func testThatItDecodesRandomGIFResponse() {
        // GIVEN
        requester.response = makeSuccessResponse(forMockFile: "single_gif")

        // WHEN
        let fetchExpectation = expectation(description: "The resource can be fetched and decoded.")
        var result: ZiphyResult<Ziph>?

        client.fetchRandomPost {
            result = $0
            fetchExpectation.fulfill()
        }

        sendResponse(afterDelay: 1)
        waitForExpectations(timeout: 5, handler: nil)

        // THEN

        guard let fetchResult = result else {
            XCTFail("The client did not provide a result.")
            return
        }

        guard case let .success(ziph) = fetchResult else {
            XCTFail("The client returned an error: \(fetchResult.error!)")
            return
        }

        XCTAssertEqual(ziph.identifier, "26BoEYiOXxggduqtO")
        XCTAssertEqual(ziph.title, "summer lol GIF by Justin Gammon")
        XCTAssertEqual(ziph.images.count, 11)
    }

    func testThatItDecodesSearchList() {
        // GIVEN
        requester.response = makeSuccessResponse(forMockFile: "search_page1")

        // WHEN
        let fetchExpectation = expectation(description: "The resource can be fetched and decoded.")
        var result: ZiphyResult<[Ziph]>?

        client.search(term: "judge judy") {
            result = $0
            fetchExpectation.fulfill()
        }

        sendResponse(afterDelay: 1)
        waitForExpectations(timeout: 5, handler: nil)

        // THEN

        guard let fetchResult = result else {
            XCTFail("The client did not provide a result.")
            return
        }

        guard case let .success(ziphs) = fetchResult else {
            XCTFail("The client returned an error: \(fetchResult.error!)")
            return
        }

        XCTAssertEqual(ziphs.count, 25)
    }

    func testThatItDecodesSearchListEnd() {
        // GIVEN
        requester.response = makeSuccessResponse(forMockFile: "search_end")

        // WHEN
        let fetchExpectation = expectation(description: "The resource can be fetched and decoded.")
        var result: ZiphyResult<[Ziph]>?

        client.search(term: "judge judy") {
            result = $0
            fetchExpectation.fulfill()
        }

        sendResponse(afterDelay: 1)
        waitForExpectations(timeout: 5, handler: nil)

        // THEN

        guard let fetchResult = result else {
            XCTFail("The client did not provide a result.")
            return
        }

        guard case let .failure(error) = fetchResult else {
            XCTFail("The client returned elements, but the search is finished.")
            return
        }

        guard case .noMorePages = error else {
            XCTFail("Expecting 'noMorePages' error, but \(error) was returned.")
            return
        }
    }

    // MARK: Private

    // MARK: - Utilities

    private func makeSuccessResponse(forMockFile mockFile: String) -> MockZiphyResponse {
        let url = Bundle(for: ZiphyClientTests.self).url(forResource: "mock_\(mockFile)", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)!
        return .success(data, response)
    }

    private func sendResponse(afterDelay seconds: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(seconds)) {
            self.requester.respond()
        }
    }
}
