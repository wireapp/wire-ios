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
        let sut = ExpiringActivityManager(api: api)

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
        let sut = ExpiringActivityManager(api: api)

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
        let sut = ExpiringActivityManager(api: api)

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

    // MARK: - Double-resume regression tests (crash: EXC_BREAKPOINT on CheckedContinuation.resume)

    /// Regression test for the crash where outer-task cancellation and the expiry callback
    /// both tried to resume the continuation:
    ///   1. `onCancel` fires → `stopWork()` cancels the inner task, sets `self.task = nil`
    ///   2. Inner task throws `CancellationError` → first resume
    ///   3. `expiring = true` fires → `stopWork()` finds `self.task == nil`, throws,
    ///      and previously tried to resume the continuation a second time → crash
    func testNoCrash_WhenExpiryFires_AfterOuterTaskCancellation() async throws {
        let api = MockExpiringActivityAPI()
        let sut = ExpiringActivityManager(api: api)

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

        // Must not crash (EXC_BREAKPOINT) regardless of which error is thrown.
        do { try await outerTask.value } catch {}
    }

    /// Regression test for the race where the expiry callback fires *before* the
    /// `expiring = false` callback has had a chance to call `startWork` on the actor:
    ///   1. `expiring = true` reaches the actor first → `stopWork()` finds `task == nil`,
    ///      throws, and previously resumed the continuation with that error
    ///   2. `expiring = false` then runs `startWork`, work completes, and previously
    ///      tried to resume the continuation a second time → crash
    func testNoCrash_WhenExpiryCallbackFiresBeforeWorkStarts() async throws {
        let api = MockExpiringActivityAPI()
        let sut = ExpiringActivityManager(api: api)

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
        let sut = ExpiringActivityManager(api: api)

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
