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

class ZiphyRequestGeneratorTests: XCTestCase {
    // MARK: Internal

    var generator: ZiphyRequestGenerator!

    override func setUp() {
        super.setUp()
        generator = ZiphyRequestGenerator(host: "localhost")
    }

    override func tearDown() {
        generator = nil
        super.tearDown()
    }

    func testThatItGeneratesSearchRequestWithEscaping() {
        // GIVEN
        let searchTerm = "ryan gosling"

        // WHEN
        let request = generator.makeSearchRequest(term: searchTerm, resultsLimit: 10, offset: 5)

        // THEN
        verifyURL(request, expected: "https://localhost/v1/gifs/search?limit=10&offset=5&q=ryan%20gosling")
    }

    func testThatItGeneratesTrendingRequest() {
        let request = generator.makeTrendingImagesRequest(resultsLimit: 10, offset: 5)
        verifyURL(request, expected: "https://localhost/v1/gifs/trending?limit=10&offset=5")
    }

    func testThatItGeneratesRandomRequest() {
        let request = generator.makeRandomImageRequest()
        verifyURL(request, expected: "https://localhost/v1/gifs/random")
    }

    // MARK: Private

    // MARK: - Utilities

    private func verifyURL(_ potentialResult: ZiphyResult<URLRequest>, expected: String) {
        switch potentialResult {
        case let .success(request):
            guard let url = request.url else {
                XCTFail("The generated requests did not contain a URL.")
                return
            }

            XCTAssertEqual(url.absoluteString, expected)

        case let .failure(error):
            XCTFail("URL generation failed with error: \(error)")
        }
    }
}
