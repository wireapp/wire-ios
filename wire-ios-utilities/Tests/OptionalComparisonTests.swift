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

import WireUtilities
import XCTest

// MARK: - OptionalComparisonTests

final class OptionalComparisonTests: XCTestCase {
    // MARK: OptionalComparison

    func testPrependingNilAscending_given0And1() {
        // given
        let lhs = 0
        let rhs = 1

        // when
        let result = OptionalComparison.prependingNilAscending(lhs: lhs, rhs: rhs)

        // then
        XCTAssertTrue(result)
    }

    func testPrependingNilAscending_given1And1() {
        // given
        let lhs = 1
        let rhs = 1

        // when
        let result = OptionalComparison.prependingNilAscending(lhs: lhs, rhs: rhs)

        // then
        XCTAssertFalse(result)
    }

    func testPrependingNilAscending_given1And0() {
        // given
        let lhs = 1
        let rhs = 0

        // when
        let result = OptionalComparison.prependingNilAscending(lhs: lhs, rhs: rhs)

        // then
        XCTAssertFalse(result)
    }

    func testPrependingNilAscending_givenNilAnd0() {
        // given
        let lhs: Int? = nil
        let rhs: Int? = 0

        // when
        let result = OptionalComparison.prependingNilAscending(lhs: lhs, rhs: rhs)

        // then
        XCTAssertTrue(result)
    }

    func testPrependingNilAscending_givenNilAndNil() {
        // given
        let lhs: Int? = nil
        let rhs: Int? = nil

        // when
        let result = OptionalComparison.prependingNilAscending(lhs: lhs, rhs: rhs)

        // then
        XCTAssertFalse(result)
    }

    func testPrependingNilAscending_given0AndNil() {
        // given
        let lhs: Int? = 0
        let rhs: Int? = nil

        // when
        let result = OptionalComparison.prependingNilAscending(lhs: lhs, rhs: rhs)

        // then
        XCTAssertFalse(result)
    }

    // MARK: Collection

    func testSortedAscendingPrependingNilByKeyPath() {
        // given
        let values = [
            MockBook(title: "B"),
            MockBook(title: "A"),
            MockBook(title: nil),
        ]

        // when
        let result = values.sortedAscendingPrependingNil(by: \.title)

        // then
        XCTAssertEqual(
            result,
            [
                MockBook(title: nil),
                MockBook(title: "A"),
                MockBook(title: "B"),
            ]
        )
    }

    func testsortedAscendingPrependingNilByClosure() {
        // given
        let values = [
            MockBook(title: "B"),
            MockBook(title: "A"),
            MockBook(title: nil),
        ]

        // when
        let result = values.sortedAscendingPrependingNil { $0.title }

        // then
        XCTAssertEqual(
            result,
            [
                MockBook(title: nil),
                MockBook(title: "A"),
                MockBook(title: "B"),
            ]
        )
    }
}

// MARK: - MockBook

private struct MockBook: Equatable {
    let title: String?
}
