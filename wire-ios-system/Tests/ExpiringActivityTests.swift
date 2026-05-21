//
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

import Foundation
import XCTest
@testable import WireSystem

class ExpiringActivityTests: XCTestCase {

    let concurrentQueue = DispatchQueue(label: "activity queue", attributes: [.concurrent])

    func testThatTaskIsCancelled_WhenActivityExpires() async throws {

        // given
        let api = MockExpiringActivityAPI()
        let sut = ExpiringActivityManager<Void>(api: api)

        api.method = { _, block in
            self.concurrentQueue.async {
                block(false)
            }
            self.concurrentQueue.async {
                block(true)
            }
        }

        // when
        do {
            try await sut.withExpiringActivity(reason: "Expiring test activity") {
                while true {
                    await Task.yield()
                    try Task.checkCancellation()
                }
            }
            XCTFail("Expected a cancellation error to be thrown")
        } catch {}
    }

    func testThatTaskIsCancelled_WhenActivityIsNotAllowedToBegin() async throws {

        // given
        let api = MockExpiringActivityAPI()
        let sut = ExpiringActivityManager<Void>(api: api)

        api.method = { _, block in
            self.concurrentQueue.async {
                block(true)
            }
        }

        // when
        do {
            try await sut.withExpiringActivity(reason: "Expiring test activity") {
                while true {
                    await Task.yield()
                    try Task.checkCancellation()
                }
            }
            XCTFail("Expected an expiring activity not allowed to run error to be thrown")
        } catch {}
    }

    func testThatWorkIsCancelled_WhenOuterTaskIsCancelled() async throws {

        // given
        let api = MockExpiringActivityAPI()
        let sut = ExpiringActivityManager<Void>(api: api)

        api.method = { _, block in
            self.concurrentQueue.async {
                block(false)
            }
        }

        let workStarted = expectation(description: "work started")

        // when
        let outerTask = Task {
            try await sut.withExpiringActivity(reason: "test activity") {
                workStarted.fulfill()
                while true {
                    await Task.yield()
                    try Task.checkCancellation()
                }
            }
        }

        await fulfillment(of: [workStarted], timeout: 1)
        outerTask.cancel()

        // then
        do {
            try await outerTask.value
            XCTFail("Expected a cancellation error to be thrown")
        } catch {}
    }

    // MARK: - Regression tests for stop/expiry races

    /// When outer-task cancellation and OS expiry both fire, `stopWork()` is
    /// invoked twice. The caller must see the inner task's `CancellationError`
    /// (not `ExpiringActivityNotAllowedToRun` from the late expiry), and the
    /// continuation must not be resumed twice.
    func testCancellationErrorIsThrown_WhenExpiryFiresAfterOuterTaskCancellation() async throws {
        let api = MockExpiringActivityAPI()
        let sut = ExpiringActivityManager<Void>(api: api)

        let workStarted = expectation(description: "work started")
        let expiryFired = expectation(description: "expiry fired")

        api.method = { _, block in
            self.concurrentQueue.async { block(false) }
            // Expiry fires after work has started, racing with the outer cancellation below.
            self.concurrentQueue.asyncAfter(deadline: .now() + 0.05) {
                expiryFired.fulfill()
                block(true)
            }
        }

        let outerTask = Task {
            try await sut.withExpiringActivity(reason: "regression test") {
                workStarted.fulfill()
                while true {
                    await Task.yield()
                    try Task.checkCancellation()
                }
            }
        }

        await fulfillment(of: [workStarted], timeout: 1)
        outerTask.cancel()
        await fulfillment(of: [expiryFired], timeout: 1)

        do {
            try await outerTask.value
            XCTFail("Expected CancellationError to be thrown")
        } catch is CancellationError {
            // expected
        } catch {
            XCTFail("Expected CancellationError, got \(error)")
        }
    }

    /// When the expiry callback reaches the actor before `startWork` has run,
    /// the subsequent successful completion of `startWork` must not resume the
    /// continuation a second time. Both `ExpiringActivityNotAllowedToRun` and
    /// `CancellationError` are valid outcomes of the race — the only failure
    /// mode being guarded against here is a crash.
    func testNoCrash_WhenExpiryCallbackFiresBeforeWorkStarts() async throws {
        let api = MockExpiringActivityAPI()
        let sut = ExpiringActivityManager<Void>(api: api)

        api.method = { _, block in
            // Deliver expiry before start to maximise the chance of the race.
            self.concurrentQueue.async { block(true) }
            self.concurrentQueue.async { block(false) }
        }

        // Must not crash. The error (ExpiringActivityNotAllowedToRun or
        // CancellationError) is an expected outcome of the race.
        do { try await sut.withExpiringActivity(reason: "regression test") {} } catch {}
    }

    func testThatTaskEndsWithoutError_WhenActivityCompletes() async throws {

        // given
        let api = MockExpiringActivityAPI()
        let sut = ExpiringActivityManager<Void>(api: api)

        api.method = { _, block in
            self.concurrentQueue.async {
                block(false)
            }
        }

        // when
        do {
            try await sut.withExpiringActivity(reason: "Expiring test activity") {
                try Task.checkCancellation()
            }
        } catch {
            XCTFail("Expected the activity to end without any error thrown")
        }
    }

}

private class MockExpiringActivityAPI: ExpiringActivityInterface {

    typealias MethodCall = (_ reason: String, _ block: @escaping @Sendable (Bool) -> Void) -> Void

    var method: MethodCall?

    func performExpiringActivity(withReason reason: String, using block: @escaping @Sendable (Bool) -> Void) {
        if let method {
            method(reason, block)
        } else {
            fatalError("no mock for `performExpiringActivity(withReason:using:)`")
        }
    }

}
