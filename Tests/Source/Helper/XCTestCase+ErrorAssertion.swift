//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

extension XCTestCase {
    typealias AsyncThrowingBlock = () async throws -> Void
    typealias ThrowingBlock = () throws -> Void
    typealias EquatableError = Error & Equatable

    func assertItThrows<T: EquatableError>(error expectedError: T, block: AsyncThrowingBlock) async {
        do {
            try await block()
            XCTFail("No error was thrown")
        } catch {
            assertError(error, equals: expectedError)
        }
    }

    func assertItThrows<T: EquatableError>(error expectedError: T, block: ThrowingBlock) {
        XCTAssertThrowsError(try block()) { error in
            assertError(error, equals: expectedError)
        }
    }

    func assertError<T: EquatableError>(_ error: Error, equals expectedError: T) {
        guard let error = error as? T else {
            return XCTFail("Unexpected error: \(String(describing: error))")
        }

        XCTAssertEqual(error, expectedError)
    }
}
