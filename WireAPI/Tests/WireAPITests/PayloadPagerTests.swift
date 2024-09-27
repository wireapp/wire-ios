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
@testable import WireAPI

// MARK: - PayloadPagerTests

final class PayloadPagerTests: XCTestCase {
    func test_PagerIteratesThroughPages() async throws {
        // Given
        let sut = PayloadPager<String>(start: "first") { index in
            switch index {
            case "first":
                return PayloadPager.Page(
                    element: ["A", "B", "C"],
                    hasMore: true,
                    nextStart: "second"
                )

            case "second":
                return PayloadPager.Page(
                    element: ["D", "E", "F"],
                    hasMore: true,
                    nextStart: "third"
                )

            case "third":
                return PayloadPager.Page(
                    element: ["G", "H", "I"],
                    hasMore: false,
                    nextStart: ""
                )

            default:
                throw TestError(message: "unknown index: \(String(describing: index))")
            }
        }

        // When
        var iterator = sut.makeAsyncIterator()

        // Then
        let page1 = try await iterator.next()
        XCTAssertEqual(page1, ["A", "B", "C"])

        let page2 = try await iterator.next()
        XCTAssertEqual(page2, ["D", "E", "F"])

        let page3 = try await iterator.next()
        XCTAssertEqual(page3, ["G", "H", "I"])

        let page4 = try await iterator.next()
        XCTAssertNil(page4)
    }

    func test_PagerStopIteratesThroughPagesIfThrowingError() async throws {
        // Given
        let expectedError = TestError(message: "unexpected error from api")
        let sut = PayloadPager<String>(start: "first") { index in
            switch index {
            case "first":
                return PayloadPager.Page(
                    element: ["A", "B", "C"],
                    hasMore: true,
                    nextStart: "second"
                )

            default:
                throw expectedError
            }
        }

        // When
        var iterator = sut.makeAsyncIterator()

        // Then
        let page1 = try await iterator.next()
        XCTAssertEqual(page1, ["A", "B", "C"])

        let page2 = try? await iterator.next()
        XCTAssertNil(page2)

        do {
            _ = try await iterator.next()
            XCTFail("expected error thrown")
        } catch {
            XCTAssertEqual(expectedError, error as? TestError)
        }
    }
}

// MARK: - TestError

private struct TestError: Error, Equatable {
    let message: String
}
