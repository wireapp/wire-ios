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

import Foundation

extension XCTestCase {

    public func waitForGroupsToBeEmpty(_ groups: [DispatchGroup], timeout: TimeInterval = 5) -> Bool {

        let timeoutDate = Date(timeIntervalSinceNow: timeout)
        var groupCounter = groups.count

        groups.forEach { (group) in
            group.notify(queue: DispatchQueue.main, execute: {
                groupCounter -= 1
            })
        }

        while groupCounter > 0 && timeoutDate.timeIntervalSinceNow > 0 {
            if !RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.002)) {
                Thread.sleep(forTimeInterval: 0.002)
            }
        }

        return groupCounter == 0
    }

    public func createTempFolder() -> URL {
        let url = URL(fileURLWithPath: [NSTemporaryDirectory(), UUID().uuidString].joined(separator: "/"))
        try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: [:])
        return url
    }

    public typealias AsyncThrowingBlock = () async throws -> Void
    public typealias ThrowingBlock = () throws -> Void
    public typealias EquatableError = Error & Equatable

    public func assertItThrows<T: EquatableError>(
        error expectedError: T,
        block: AsyncThrowingBlock,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        do {
            try await block()
            XCTFail(
                "No error was thrown",
                file: file,
                line: line
            )
        } catch {
            assertError(
                error,
                equals: expectedError,
                file: file,
                line: line
            )
        }
    }

    public func assertItThrows<T: EquatableError>(
        error expectedError: T,
        block: ThrowingBlock,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertThrowsError(try block(), file: file, line: line) { error in
            assertError(
                error,
                equals: expectedError,
                file: file,
                line: line
            )
        }
    }

    public func assertError<T: EquatableError>(
        _ error: Error,
        equals expectedError: T,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard let error = error as? T else {
            return XCTFail(
                "Unexpected error: \(String(describing: error))",
                file: file,
                line: line
            )
        }

        XCTAssertEqual(
            error,
            expectedError,
            file: file,
            line: line
        )
    }

    public func assertMethodCompletesWithError<Success, Error: EquatableError>(
        _ expectedError: Error,
        method: (@escaping (Result<Success, Error>) -> Void) -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        assertMethodCompletesWithValidation(method: method) { result in
            guard case .failure(let error) = result else {
                return XCTFail("expected failure", file: file, line: line)
            }

            XCTAssertEqual(
                error,
                expectedError,
                file: file,
                line: line
            )
        }
    }

    public func assertMethodCompletesWithSuccess<Success, Error: EquatableError>(
        method: (@escaping (Result<Success, Error>) -> Void) -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        assertMethodCompletesWithValidation(method: method, validation: { result in
            guard case .success = result else {
                return XCTFail("expected success", file: file, line: line)
            }
        })
    }

    public func assertMethodCompletesWithValidation<Success, Error: EquatableError>(
        method: (@escaping (Result<Success, Error>) -> Void) -> Void,
        validation: @escaping (Result<Success, Error>) -> Void
    ) {
        let expectation = XCTestExpectation(description: "completion called")

        // WHEN
        method { result in
            validation(result)
            expectation.fulfill()
        }

        // THEN
        wait(for: [expectation], timeout: 0.5)
    }

    public func assertSuccess<Value, Failure>(
        result: Swift.Result<Value, Failure>,
        message: (Failure) -> String = { "Expected to be a success but got a failure with \($0) "},
        file: StaticString = #filePath,
        line: UInt = #line) {
            switch result {
            case .success:
                break
            case .failure(let error):
                XCTFail(message(error), file: file, line: line)
            }
        }

    public func assertFailure<Value, Failure: Equatable>(
        result: Swift.Result<Value, Failure>,
        expectedFailure: Failure,
        file: StaticString = #filePath,
        line: UInt = #line) {
            switch result {
            case .success:
                XCTFail("Expected a failure of type \(expectedFailure) but got a success", file: file, line: line)
            case .failure(let failure):
                XCTAssertEqual(expectedFailure, failure, file: file, line: line)
            }
        }

}
