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
import os
import WireLogging

private let logger = WireLogger.backgroundActivity

/// Coordinates multiple tasks under a single expiring activity so that only one
/// thread is ever blocked, regardless of how many tasks are tracked in parallel.
///
/// Uses a `DispatchGroup` to track active tasks: each task enters the group on
/// registration and leaves when it completes. A semaphore blocks the expiring
/// activity's callback and is signaled either by `group.notify` (all tasks
/// finished) or directly when the system revokes background time.
///
/// If the system revokes background time, all tracked tasks are cancelled and
/// the semaphore is signaled immediately so the callback can return without
/// waiting for the tasks to finish.
final class ExpiringActivityManager: Sendable {

    /// The underlying system API wrapper used to register expiring activities.
    private let performer: any ExpiringActivityPerformerProtocol

    /// Tracks active tasks via `enter()`/`leave()`. When the last task leaves,
    /// `notify` signals the semaphore to unblock the expiring activity callback.
    private let group = DispatchGroup()

    /// Thread-safe mutable state guarded by an unfair lock.
    private let state = OSAllocatedUnfairLock(initialState: State())

    private struct State {

        /// Whether an expiring activity is currently registered with the system.
        var isActive = false

        /// Closures that cancel each tracked task, invoked when the system revokes background time.
        var cancellations: [@Sendable () -> Void] = []

    }

    init(performer: some ExpiringActivityPerformerProtocol) {
        self.performer = performer
    }

    /// Track a task under the shared expiring activity. If this is the first
    /// active task, an expiring activity is registered with the system.
    ///
    /// - Parameters:
    ///   - reason: A human-readable reason used for logging. The system-level
    ///     expiring activity always uses a static reason since multiple tasks
    ///     share a single registration.
    ///   - task: The task to protect. It will be cancelled if the system reclaims background time.
    func track(reason: String, task: Task<some Sendable, some Error>) {

        group.enter()

        let shouldRegister = state.withLock {
            $0.cancellations.append { task.cancel() }
            let isFirst = !$0.isActive
            if isFirst { $0.isActive = true }
            return isFirst
        }

        if shouldRegister {
            logger.debug("Registering expiring activity [reason: \(reason)]")

            // Fresh semaphore per registration cycle to avoid stale signal
            // values from a previous cycle's double-signal (group.notify + expiration).
            let semaphore = DispatchSemaphore(value: 0)

            group.notify(queue: .global()) { [self] in
                semaphore.signal()
                state.withLock {
                    $0.isActive = false
                    $0.cancellations.removeAll()
                }
            }

            performer.performExpiringActivity(reason: "ExpiringActivityManager") { [self] isExpiring in
                if isExpiring {
                    logger.debug("System is revoking background time, cancelling all tasks [reason: \(reason)]")
                    cancelAll()
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
            group.leave()
        }
    }

    private func cancelAll() {
        let all = state.withLock { $0.cancellations }
        for cancel in all {
            cancel()
        }
    }

}
