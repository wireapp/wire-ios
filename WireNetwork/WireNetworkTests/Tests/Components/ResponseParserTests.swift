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

import XCTest

@testable import WireNetwork

final class ResponseParserTests: XCTestCase {

    private var sut: ResponseParser<String>!

    override func setUp() {
        sut = ResponseParser()
    }

    override func tearDown() {
        sut = nil
    }

    func testFailure_prioritizesLabeledFailure() throws {
        enum Failure: Error, Equatable {
            case a
            case b
            case c
        }

        // given
        let code = HTTPStatusCode.badRequest
        let data = try JSONEncoder().encode(FailureResponseV0(code: code.rawValue, label: "b", message: "message"))

        // when
        XCTAssertThrowsError(
            try sut
                .failure(code: code, error: Failure.a)
                .failure(code: code, label: "b", error: Failure.b)
                .failure(code: code, error: Failure.c)
                .parse(code: code.rawValue, data: data)
        ) { error in
            // then
            XCTAssertEqual(error as? Failure, Failure.b)
        }
    }

}
