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

    // MARK: - Bug regression tests

    func testBug1_ActivityCompletesAfterExpiry_WhenBlockIgnoresCancellation() async throws {

        // Regression test for watchdog kill (0xBAADCA11).
        //
        // When expiring=true fires, stopWork() cancels the Swift Task. However if block()
        // never calls Task.checkCancellation() (non-cooperative), the Task keeps running
        // and defer { semaphore.signal() } never executes. This causes semaphore.wait()
        // to block the performExpiringActivity callback thread indefinitely, eventually
        // triggering the iOS watchdog and killing the app.
        //
        // Expected (after fix): withExpiringActivity throws promptly when expiry fires.
        // Actual   (before fix): withExpiringActivity hangs indefinitely.

        // given
        let api = MockExpiringActivityAPI()
        let sut = ExpiringActivityManager(api: api)

        api.method = { _, block in
            self.concurrentQueue.async { block(false) }
            self.concurrentQueue.asyncAfter(deadline: .now() + 0.05) { block(true) }
        }

        let activityCompleted = expectation(description: "activity completes after expiry")

        // when
        Task {
            do {
                try await sut.withExpiringActivity(reason: "bug1") {
                    // Simulates work that ignores cooperative cancellation.
                    // Task.yield() suspends but does NOT propagate CancellationError,
                    // so task.cancel() has no effect here.
                    while true { await Task.yield() }
                }
            } catch {
                // Any error is acceptable; we just need the call to return.
            }
            activityCompleted.fulfill()
        }

        // then
        // BUG: this fails — semaphore.wait() blocks the callback thread forever.
        // After fix (expire directly signals semaphore): completes promptly.
        await fulfillment(of: [activityCompleted], timeout: 2.0)
    }

    func testBug2_NoContinuationDoubleResume_WhenExpiryRacesBeforeStartWork() async throws {

        // Regression test for double-resume of CheckedContinuation.
        //
        // Race condition: if expiring=true fires and stopWork() runs on the actor
        // BEFORE startWork() (from expiring=false), self.task is nil, stopWork()
        // throws ExpiringActivityNotAllowedToRun, and continuation.resume(throwing:)
        // is called. Later startWork() runs, block() completes, and continuation.resume()
        // is called again. Resuming a CheckedContinuation twice is undefined behavior
        // (assertion failure / crash in debug builds).
        //
        // This test triggers the race deterministically by enqueuing the expiring=true
        // Task on the actor before the expiring=false Task.
        //
        // Expected (after fix): OnceAction prevents double-resume; no crash.
        // Actual   (before fix): undefined behavior / crash.

        // given
        let api = MockExpiringActivityAPI()
        let sut = ExpiringActivityManager(api: api)

        // Fire block(true) synchronously before block(false) so the actor
        // processes stopWork (Task B) before startWork (Task A).
        api.method = { _, block in
            DispatchQueue.global().async {
                block(true)  // Task B → enqueued to actor first
                block(false) // Task A → enqueued to actor second
            }
        }

        // when / then
        // BUG: crashes or prints a runtime warning due to double-resume of
        // CheckedContinuation. After fix: completes cleanly without double-resume.
        do {
            try await sut.withExpiringActivity(reason: "bug2") {
                try Task.checkCancellation()
            }
        } catch {
            // Any error is acceptable.
        }
    }

    // MARK: -

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
