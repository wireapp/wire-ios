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

/// Coordinates multiple tasks under a single expiring activity so that only one
/// thread is ever blocked, regardless of how many tasks are tracked in parallel.
///
/// - When the first task is tracked, a single expiring activity is registered,
///   blocking one thread via a semaphore.
/// - Subsequent tasks join the same activity without blocking additional threads.
/// - When the last task completes, the semaphore is signaled and the activity ends.
/// - If the system revokes background time, all tracked tasks are cancelled and
///   the semaphore is signaled so the blocked thread is released.
final class ExpiringActivityManager: @unchecked Sendable {

    private let performer: any ExpiringActivityPerformerProtocol
    private let lock = NSLock()

    // Protected by `lock`.
    private var cancellations: [UUID: @Sendable () -> Void] = [:]
    private var activeSemaphore: DispatchSemaphore?

    init(performer: some ExpiringActivityPerformerProtocol) {
        self.performer = performer
    }

    /// Track a task under the shared expiring activity. If this is the first
    /// active task, an expiring activity is registered with the system.
    ///
    /// - Parameters:
    ///   - reason: A human-readable reason passed to the system for debugging.
    ///   - task: The task to protect. It will be cancelled if the system reclaims background time.
    func track(reason: String, task: Task<some Sendable, some Error>) {
        let id = UUID()
        let logger = WireLogger.backgroundActivity

        lock.lock()
        cancellations[id] = { task.cancel() }
        let shouldRegister = activeSemaphore == nil
        if shouldRegister {
            activeSemaphore = DispatchSemaphore(value: 0)
        }
        let semaphore = activeSemaphore!
        lock.unlock()

        if shouldRegister {
            logger.debug("Registering expiring activity [reason: \(reason)]")

            performer.performExpiringActivity(reason: reason) { [self] isExpiring in
                if isExpiring {
                    logger.debug("System is revoking background time, cancelling all tasks [reason: \(reason)]")
                    cancelAllAndSignal()
                } else {
                    logger.debug("System granted background time, blocking until all tasks finish [reason: \(reason)]")
                    semaphore.wait()
                    logger.debug("All tasks finished, releasing expiring activity [reason: \(reason)]")
                }
            }
        }

        Task.detached { [self] in
            // We only need to wait for the task to complete; the result is irrelevant.
            _ = try? await task.value
            removeAndSignalIfEmpty(id: id)
        }
    }

    private func cancelAllAndSignal() {
        lock.lock()
        let allCancellations = Array(cancellations.values)
        cancellations.removeAll()
        let semaphore = activeSemaphore
        activeSemaphore = nil
        lock.unlock()

        for cancel in allCancellations {
            cancel()
        }
        semaphore?.signal()
    }

    private func removeAndSignalIfEmpty(id: UUID) {
        lock.lock()
        cancellations.removeValue(forKey: id)
        let isEmpty = cancellations.isEmpty
        let semaphore = isEmpty ? activeSemaphore : nil
        if isEmpty {
            activeSemaphore = nil
        }
        lock.unlock()

        semaphore?.signal()
    }

}
