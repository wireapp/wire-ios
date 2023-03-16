//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

final class CurryingTests: XCTestCase {

    func testThatItCurries_1ParameterFunction() {
        // Given
        let foo: (Int) -> Int = { $0 }

        // When
        let curried = curry(foo)

        // Then
        XCTAssertEqual(curried(4), 4)
    }

    func testThatItCurries_2ParameterFunction() {
        // Given
        let add: (String, String) -> String = { $0 + $1 }

        // When
        let curried = curry(add)

        // Then
        XCTAssertEqual(curried("Hello")(" World"), "Hello World")
    }

    func testThatItCurries_3ParameterFunction() {
        // Given
        let foo: (String, String, String) -> String = { $0 + $1 + $2 }

        // When
        let curried = curry(foo)

        // Then
        XCTAssertEqual(curried("1")("2")("3"), "123")
    }

    func testThatItCurries_4ParameterFunction() {
        // Given
        let foo: (String, String, String, String) -> String = { $0 + $1 + $2 + $3 }

        // When
        let curried = curry(foo)

        // Then
        XCTAssertEqual(curried("1")("2")("3")("4"), "1234")
    }

    func testThatItCurries_5ParameterFunction() {
        // Given
        let foo: (String, String, String, String, String) -> String = { $0 + $1 + $2 + $3 + $4 }

        // When
        let curried = curry(foo)

        // Then
        XCTAssertEqual(curried("1")("2")("3")("4")("5"), "12345")
    }

    func testThatItCurries_6ParameterFunction() {
        // Given
        let foo: (String, String, String, String, String, String) -> String = { $0 + $1 + $2 + $3 + $4 + $5 }

        // When
        let curried = curry(foo)

        // Then
        XCTAssertEqual(curried("1")("2")("3")("4")("5")("6"), "123456")
    }

}
