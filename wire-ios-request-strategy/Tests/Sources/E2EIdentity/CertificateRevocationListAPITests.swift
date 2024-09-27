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

import Foundation
import XCTest
@testable import WireRequestStrategy

final class CertificateRevocationListAPITests: XCTestCase {
    // MARK: Internal

    override func setUp() {
        mockHttpClient = MockHttpClient()
        sut = CertificateRevocationListAPI(httpClient: mockHttpClient)
        super.setUp()
    }

    override func tearDown() {
        mockHttpClient = nil
        sut = nil
        super.tearDown()
    }

    func test_getRevocationList_SucceedsWithData() async throws {
        // GIVEN
        let url = try XCTUnwrap(URL(string: "dp.example.com"))

        let response = try XCTUnwrap(
            HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
        )
        let responseData = Data.random()

        mockHttpClient.mockResponse = (responseData, response)

        // WHEN
        let data = try await sut.getRevocationList(from: url)

        // THEN
        XCTAssertEqual(responseData, data)
    }

    func test_getRevocationList_FailsWithNetworkError_NotAnHTTPResponse() async throws {
        // GIVEN
        let url = try XCTUnwrap(URL(string: "dp.example.com"))

        let response = URLResponse()
        let responseData = Data.random()

        mockHttpClient.mockResponse = (responseData, response)

        // WHEN / THEN
        await assertItThrows(error: CertificateRevocationListAPI.NetworkError.notAnHTTPResponse) {
            _ = try await sut.getRevocationList(from: url)
        }
    }

    func test_getRevocationList_FailsWithNetworkError_InvalidStatusCode() async throws {
        // GIVEN
        let url = try XCTUnwrap(URL(string: "dp.example.com"))

        let response = try XCTUnwrap(
            HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil)
        )
        let responseData = Data.random()

        mockHttpClient.mockResponse = (responseData, response)

        // WHEN / THEN
        await assertItThrows(error: CertificateRevocationListAPI.NetworkError.invalidStatusCode(404)) {
            _ = try await sut.getRevocationList(from: url)
        }
    }

    // MARK: Private

    private var sut: CertificateRevocationListAPI!
    private var mockHttpClient: MockHttpClient!
}
