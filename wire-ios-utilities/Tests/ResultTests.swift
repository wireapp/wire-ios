//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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
import WireUtilities

class ResultTests: XCTestCase {
    func testThatItCanMapAResult_Success() {
        // Given
        let sut = Result<Int>.success(42)

        // When
        let transformed = sut.map(String.init) as ZMResult<String>

        // Then
        XCTAssertEqual(transformed.value, "42")
    }

    func testThatItCanMapAResult_Throwing() {
        // Given
        let error = NSError(domain: "", code: 0, userInfo: nil)
        let sut = Result<Int>.success(42)

        // When
        let transformed: ZMResult<Int> = sut.map { _ in throw error }

        // Then
        XCTAssertEqual(transformed.error as NSError?, error)
    }

    func testThatItCanMapAResult_Error() {
        // Given
        let error = NSError(domain: "", code: 0, userInfo: nil)
        let sut = Result<Int>.failure(error)

        // When
        let transformed: ZMResult<String> = sut.map(String.init)

        // Then
        XCTAssertEqual(transformed.error as NSError?, error)
    }

}
