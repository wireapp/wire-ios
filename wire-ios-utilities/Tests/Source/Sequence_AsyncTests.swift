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

final class Sequence_AsyncTests: XCTestCase {

    var array = Array(0..<5)

    // MARK: - AsyncCompactMap

    func testAsyncCompactMap() async throws {

        let result = await array.asyncCompactMap { element in
            element * 2
        }

        XCTAssertEqual(result, [0, 2, 4, 6, 8])
    }

    func testAsyncCompactMapReThrows() async throws {
        enum TestError: Error, Equatable {
            case isTwo
        }
        var result: [Int]?
        do {
            result = try await array.asyncCompactMap { element in
                if element == 2 {
                    throw TestError.isTwo
                }
                return element
            }
            XCTFail("should rethrow error")
        } catch TestError.isTwo {
            // do nothing
        } catch {
            XCTFail("should rethrow same error")

        }
        XCTAssertNil(result)
    }

    func testAsyncCompactMapIgnoreNilValues() async {
        let result: [Int] = await array.asyncCompactMap { element in
            if element == 2 {
                return nil
            }
            return element
        }
        XCTAssertEqual(result, [0, 1, 3, 4])
    }

    // MARK: asyncMap

    func testAsyncMap() async throws {

        let result = await array.asyncCompactMap { element in
            element * 2
        }

        XCTAssertEqual(result, [0, 2, 4, 6, 8])
    }

    func testAsyncMapReThrows() async throws {
        enum TestError: Error, Equatable {
            case isTwo
        }

        var result: [Int]?
        do {
            result = try await array.asyncMap { element in
                if element == 2 {
                    throw TestError.isTwo
                }
                return element
            }
            XCTFail("should rethrow error")
        } catch TestError.isTwo {
            // do nothing
        } catch {
            XCTFail("should rethrow same error")
        }

        XCTAssertNil(result)
    }
}
