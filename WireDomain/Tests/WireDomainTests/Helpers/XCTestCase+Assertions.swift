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

    /// Assert that a collection is of a certain size.
    ///
    /// - Parameters:
    ///   - collection: The collection to assert.
    ///   - count: The expected number of elements.
    ///   - message: The error message to show when the assertion fails.
    ///   - file: The file name of the invoking test.
    ///   - line: The line number when this assertion is made.

    func XCTAssertCount(
        _ collection: some Collection,
        count: Int,
        _ message: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let actualCount = collection.count
        guard actualCount == count else {
            let message = message ?? "expected count \(count), but got \(actualCount)"

            XCTFail(
                message,
                file: file,
                line: line
            )

            throw message
        }
    }

    /// Assert that an error is thrown when a block is performed.
    ///
    /// - Parameters:
    ///   - expectedError: The expected error.
    ///   - expression: The expression that should throw the error.
    ///   - message: The error message to show when no error is thrown.
    ///   - file: The file name of the invoking test.
    ///   - line: The line number when this assertion is made.

    func XCTAssertThrowsError<E: Error & Equatable>(
        _ expectedError: E,
        when expression: @escaping () async throws -> some Any,
        _ message: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        await XCTAssertThrowsError(
            expression,
            message,
            file: file,
            line: line
        ) { error in
            if let error = error as? E {
                XCTAssertEqual(
                    error,
                    expectedError,
                    file: file,
                    line: line
                )
            } else {
                XCTFail(
                    "unexpected error: \(error)",
                    file: file,
                    line: line
                )
            }
        }
    }

    /// Assert that an error is thrown when a block is performed.
    ///
    /// - Parameters:
    ///   - expression: The expression that should throw the error.
    ///   - message: The error message to show when no error is thrown.
    ///   - file: The file name of the invoking test.
    ///   - line: The line number when this assertion is made.
    ///   - errorHandler: A handler for the thrown error.

    func XCTAssertThrowsError(
        _ expression: () async throws -> some Any,
        _ message: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ errorHandler: (_ error: any Error) -> Void = { _ in }
    ) async {
        do {
            _ = try await expression()
            XCTFail(
                message ?? "expected an error but none was thrown",
                file: file,
                line: line
            )
        } catch {
            errorHandler(error)
        }
    }

}
