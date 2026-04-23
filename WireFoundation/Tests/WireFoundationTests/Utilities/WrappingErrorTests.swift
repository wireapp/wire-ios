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

@testable import WireFoundation

final class WrappingErrorTests: XCTestCase {

    // MARK: - Helpers

    private enum Outer: WrappingError {
        case failed(any Error)
        var underlyingError: any Error {
            switch self { case .failed(let e): e }
        }
    }

    private enum Inner: WrappingError {
        case failed(any Error)
        var underlyingError: any Error {
            switch self { case .failed(let e): e }
        }
    }

    private struct SomeError: Error {}

    // MARK: - rootCause

    func test_rootCause_nonWrapping_returnsSelf() {
        let error = SomeError()
        XCTAssert(error.rootCause is SomeError)
    }

    func test_rootCause_singleWrapping_returnsInner() {
        let error = Outer.failed(SomeError())
        XCTAssert(error.rootCause is SomeError)
    }

    func test_rootCause_deeplyNested_returnsInnermostError() {
        let error = Outer.failed(Inner.failed(Outer.failed(SomeError())))
        XCTAssert(error.rootCause is SomeError)
    }

    // MARK: - isCancelledError

    func test_isCancelledError_CancellationError_direct() {
        XCTAssertTrue(CancellationError().isCancelledError)
    }

    func test_isCancelledError_URLError_cancelled_direct() {
        XCTAssertTrue(URLError(.cancelled).isCancelledError)
    }

    func test_isCancelledError_unrelatedError_isFalse() {
        XCTAssertFalse(SomeError().isCancelledError)
        XCTAssertFalse(URLError(.timedOut).isCancelledError)
    }

    func test_isCancelledError_CancellationError_wrappedOnce() {
        XCTAssertTrue(Outer.failed(CancellationError()).isCancelledError)
    }

    func test_isCancelledError_URLError_cancelled_wrappedOnce() {
        XCTAssertTrue(Outer.failed(URLError(.cancelled)).isCancelledError)
    }

    func test_isCancelledError_CancellationError_deeplyNested() {
        let error = Outer.failed(Inner.failed(CancellationError()))
        XCTAssertTrue(error.isCancelledError)
    }

    func test_isCancelledError_URLError_cancelled_deeplyNested() {
        let error = Outer.failed(Inner.failed(URLError(.cancelled)))
        XCTAssertTrue(error.isCancelledError)
    }

    func test_isCancelledError_unrelatedError_deeplyNested_isFalse() {
        let error = Outer.failed(Inner.failed(SomeError()))
        XCTAssertFalse(error.isCancelledError)
    }
}
