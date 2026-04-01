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

public func withExpiringActivity(reason: String, block: @escaping () async throws -> Void) async throws {
    let manager = ExpiringActivityManager()
    try await manager.withExpiringActivity(reason: reason, block: block)
}

actor ExpiringActivityManager {

    let api: any ExpiringActivityInterface
    private var task: Task<Void, any Error>?

    init() {
        self.init(api: ProcessInfo.processInfo)
    }

    init(api: any ExpiringActivityInterface) {
        self.api = api
    }

    func withExpiringActivity(reason: String, block: @escaping () async throws -> Void) async throws {
        try await withTaskCancellationHandler {
        try await withCheckedThrowingContinuation { continuation in
            // Shared between both callback branches.
            let semaphore = DispatchSemaphore(value: 0)

            // Guards against double-resume: the expiring=true branch must resume the
            // continuation itself (in case block() ignores cancellation and Task A is
            // permanently stuck at .value). Without this guard, if Task A eventually
            // exits it would resume the continuation a second time.
            let once = OnceAction()
            let finish: @Sendable (Result<Void, any Error>) -> Void = { result in
                once.perform { continuation.resume(with: result) }
            }

            api.performExpiringActivity(withReason: reason) { expiring in
                if !expiring {
                    Task {
                        do {
                            WireLogger.backgroundActivity.debug("Start of activity: \(reason)")
                            try await self.startWork(block: block, semaphore: semaphore).value
                            WireLogger.backgroundActivity.debug("Expiring activity completed: \(reason)")
                            finish(.success(()))
                        } catch {
                            WireLogger.backgroundActivity.warn("Expiring activity ended with an error: \(error)")
                            finish(.failure(error))
                        }
                    }
                    semaphore.wait()
                } else {
                    WireLogger.backgroundActivity.warn("Background activity is expiring: \(reason)")
                    Task {
                        do {
                            try await self.stopWork()
                            // Task was running and is now cancelled. Resume the continuation
                            // immediately — we cannot rely on the task's defer to signal the
                            // semaphore if block() ignores cooperative cancellation.
                            finish(.failure(CancellationError()))
                        } catch {
                            finish(.failure(error))
                        }
                        // Unblock the callback thread regardless. A double-signal (if the
                        // task's defer also fires) is harmless.
                        semaphore.signal()
                    }
                }
            }
        } onCancel: {
            Task { try? await self.stopWork() }
        }
    }

    private func startWork(
        block: @escaping () async throws -> Void,
        semaphore: DispatchSemaphore
    ) -> Task<Void, any Error> {
        let task = Task {
            defer {
                WireLogger.backgroundActivity.debug("Releasing semaphore")
                semaphore.signal()
            }
            try await block()
        }
        self.task = task
        return task
    }

    private func stopWork() throws {
        guard let task else { throw ExpiringActivityNotAllowedToRun() }
        task.cancel()
        self.task = nil
    }
}

/// Ensures a closure is executed at most once, safe for concurrent callers.
private final class OnceAction: @unchecked Sendable {

    private let lock = NSLock()
    private var executed = false

    func perform(_ action: () -> Void) {
        lock.withLock {
            guard !executed else { return }
            executed = true
            action()
        }
    }
}
