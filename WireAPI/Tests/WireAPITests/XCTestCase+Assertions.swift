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

extension XCTestCase {

    /// Assert that a error is thrown when a block is performed.
    /// - Parameters:
    ///   - expectedError: The expected error.
    ///   - block: The block that should throw the error.
    ///   - file: The file name of the invoking test.
    ///   - line: The line number when this assertion is made.

    func assertAPIError<E: Error & Equatable>(
        _ expectedError: E,
        when block: () async throws -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        do {
            // When
            try await block()
            XCTFail(
                "expected an error but none was thrown",
                file: file,
                line: line
            )
        } catch let error as E {
            // Then
            XCTAssertEqual(
                error,
                expectedError,
                file: file,
                line: line
            )
        } catch {
            XCTFail(
                "unexpected error: \(error)",
                file: file,
                line: line
            )
        }
    }

}
