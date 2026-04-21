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

private let logger = WireLogger.backgroundActivity

/// Coordinates multiple tasks under a single expiring activity so that only one
/// thread is ever blocked, regardless of how many tasks are tracked in parallel.
///
/// The actor serializes all state access, eliminating the need for explicit locks.
/// A semaphore bridges the synchronous `performExpiringActivity` callback with the
/// async world — it is signaled either when all tasks finish or when the system
/// revokes background time.
actor ExpiringActivityManager {

    private let performer: any ExpiringActivityPerformerProtocol

    /// Number of tasks currently being tracked.
    private var activeCount = 0

    /// Incremented when the system revokes background time to invalidate
    /// pending `taskDidFinish` calls from the previous registration cycle.
    private var generation = 0

    /// Closures that cancel each tracked task, invoked when the system revokes background time.
    private var cancellations: [@Sendable () -> Void] = []

    /// Signals the semaphore to unblock the expiring activity callback.
    /// Set when an activity is registered, cleared on reset.
    private var onAllTasksFinished: (@Sendable () -> Void)?

    init(performer: some ExpiringActivityPerformerProtocol) {
        self.performer = performer
    }

    /// Track a task under the shared expiring activity. If this is the first
    /// active task, an expiring activity is registered with the system.
    ///
    /// - Parameters:
    ///   - reason: A human-readable reason used for logging.
    ///   - task: The task to protect. It will be cancelled if the system reclaims background time.
    func track(reason: String, task: Task<some Sendable, some Error>) {
        activeCount += 1
        cancellations.append { task.cancel() }
        let trackGeneration = generation

        if activeCount == 1 {
            let semaphore = DispatchSemaphore(value: 0)
            onAllTasksFinished = { semaphore.signal() }

            logger.debug("Registering expiring activity [reason: \(reason)]")

            performer.performExpiringActivity(reason: "ExpiringActivityManager") { [self] isExpiring in
                if isExpiring {
                    logger.debug("System is revoking background time, cancelling all tasks [reason: \(reason)]")
                    Task { await self.cancelAll() }
                    semaphore.signal()
                } else {
                    logger.debug("System granted background time, blocking until all tasks finish [reason: \(reason)]")
                    semaphore.wait()
                    logger.debug("All tasks finished, releasing expiring activity [reason: \(reason)]")
                }
            }
        }

        Task.detached { [self] in
            _ = try? await task.value
            await taskDidFinish(generation: trackGeneration)
        }
    }

    private func cancelAll() {
        for cancel in cancellations {
            cancel()
        }
        generation += 1
        activeCount = 0
        cancellations.removeAll()
        onAllTasksFinished = nil
    }

    private func taskDidFinish(generation: Int) {
        guard generation == self.generation else { return }
        activeCount -= 1
        if activeCount == 0 {
            onAllTasksFinished?()
            onAllTasksFinished = nil
            cancellations.removeAll()
        }
    }

}
