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
import WireLogging

protocol ExpiringActivityInterface {

    func performExpiringActivity(withReason reason: String, using block: @escaping @Sendable (Bool) -> Void)

}

extension ProcessInfo: ExpiringActivityInterface {}

/// The expiring activity is not allowed to run possibly because the background execution time has already expired.

public struct ExpiringActivityNotAllowedToRun: Error {}

/// Execute an async function inside an [performExpiringActivity](https://developer.apple.com/documentation/foundation/processinfo/1617030-performexpiringactivity)
/// which cancels the task when the activity expires. It's up to the async function to handle the cancellation by for
/// example
/// calling [Task.checkCancellation](https://developer.apple.com/documentation/swift/task/checkcancellation()) at the
/// appropriate time.
///
/// - Parameters:
///   - reason: Description of what the activity does, helpful for debugging purposes.
///   - block: async operation which supports cancellation.

public func withExpiringActivity<Result: Sendable>(
    reason: String,
    block: @escaping @Sendable () async throws -> Result
) async throws -> Result {
    let manager = ExpiringActivityManager<Result>()
    return try await manager.withExpiringActivity(reason: reason, block: block)
}

/// Single-use: one instance per activity. The only entry point is the
/// `withExpiringActivity(reason:block:)` free function above, which creates a
/// fresh manager every call. Members below are `private` to enforce this — the
/// actor's idempotency tracking (`didStartWork`) is not designed to reset.
actor ExpiringActivityManager<Result: Sendable> {

    let api: any ExpiringActivityInterface
    private var task: Task<Result, any Error>?
    // Stored as actor state so resumeOnce() is serialised through the actor
    // executor — no lock required, no threads blocked.
    private var continuation: CheckedContinuation<Result, any Error>?
    // Distinguishes "work was never started" from "work started then stopped".
    // Without this, a second stopWork() (e.g. outer-task cancel followed by
    // OS expiry) misreports the latter as ExpiringActivityNotAllowedToRun.
    private var didStartWork = false

    init() {
        self.init(api: ProcessInfo.processInfo)
    }

    init(api: any ExpiringActivityInterface) {
        self.api = api
    }

    func withExpiringActivity(
        reason: String,
        block: @escaping @Sendable () async throws -> Result
    ) async throws -> Result {
        try await withTaskCancellationHandler {
            // withCheckedThrowingContinuation forwards the caller's actor
            // isolation to its body closure, so the body runs on this actor's
            // executor and may access isolated state directly.
            try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation

                api.performExpiringActivity(withReason: reason) { expiring in
                    if !expiring {
                        let semaphore = DispatchSemaphore(value: 0)
                        Task {
                            do {
                                WireLogger.backgroundActivity.debug(
                                    "Start of activity: \(reason)"
                                )

                                let result = try await self.startWork(
                                    block: block,
                                    semaphore: semaphore
                                ).value

                                WireLogger.backgroundActivity.debug(
                                    "Expiring activity completed: \(reason)"
                                )

                                await self.resumeOnce(returning: result)

                            } catch {
                                WireLogger.backgroundActivity.warn(
                                    "Expiring activity ended with an error: \(error)"
                                )

                                await self.resumeOnce(throwing: error)
                            }
                        }
                        semaphore.wait()

                    } else {
                        WireLogger.backgroundActivity.warn(
                            "Background activity is expiring: \(reason)"
                        )

                        Task {
                            do {
                                try await self.stopWork()
                            } catch {
                                await self.resumeOnce(throwing: error)
                            }
                        }
                    }
                }
            }
        } onCancel: {
            Task { try? await self.stopWork() }
        }
    }

    private func resumeOnce(returning result: Result) {
        continuation?.resume(returning: result)
        continuation = nil
    }

    private func resumeOnce(throwing error: any Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }

    private func startWork(
        block: @escaping @Sendable () async throws -> Result,
        semaphore: DispatchSemaphore
    ) -> Task<Result, any Error> {
        didStartWork = true
        let task = Task {
            defer {
                WireLogger.backgroundActivity.debug("Releasing semaphore")
                semaphore.signal()
            }
            return try await block()
        }
        self.task = task
        return task
    }

    private func stopWork() throws {
        if let task {
            task.cancel()
            self.task = nil
            return
        }
        if !didStartWork {
            throw ExpiringActivityNotAllowedToRun()
        }
    }
}
