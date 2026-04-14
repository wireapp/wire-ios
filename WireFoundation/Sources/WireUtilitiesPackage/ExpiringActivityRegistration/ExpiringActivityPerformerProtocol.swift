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
// import WireLogging // TODO: find solution for dependency

// sourcery: AutoMockable
protocol ExpiringActivityPerformerProtocol: Sendable {

    func performExpiringActivity(
        reason: String,
        using block: @escaping @Sendable (_ isExpiring: Bool) -> Void
    )

}

// private let logger = WireLogger.backgroundActivity

extension ExpiringActivityPerformerProtocol {

    /// Registers an expiring activity that keeps the system from suspending the app
    /// while the given task is running. If the system revokes background time, the task
    /// is cancelled.
    ///
    /// This method returns immediately. The expiring activity's callback is kept blocked
    /// (via a semaphore) until either the task completes or the system signals expiration.
    ///
    /// - Parameters:
    ///   - reason: A human-readable reason for the activity, used for debugging.
    ///   - task: The task to protect. It will be cancelled if the system reclaims background time.
    func performTaskCancellationAsExpiringActivity(
        reason: String,
        task: Task<some Sendable, some Error>
    ) {

        // logger.debug("Setting up expiring activity for task cancellation [reason: \(reason)]")

        let semaphore = DispatchSemaphore(value: 0)
        performExpiringActivity(reason: reason) { isExpiring in

            if isExpiring {

                // logger.debug("Activity is expiring, cancelling task and signaling semaphore … [reason: \(reason)]")

                // System is revoking background time — cancel the task.
                task.cancel()

                // Calling signal() here in order to unblock the first invocation of this closure and prevent the system
                // from killing the app. The execution of the task however, might be suspended.
                semaphore.signal()

            } else {

                // logger.debug("Starting expiring activity, waiting on semaphore … [reason: \(reason)]")

                // System granted time. Block this callback until the task finishes,
                // so the system knows we're still doing work.
                Task.detached {

                    // logger.debug("Awaiting task … [reason: \(reason)]")

                    // We only need to wait for the task to complete; the result is irrelevant.
                    _ = try? await task.value

                    // logger.debug("… task ended, signaling semaphore … [reason: \(reason)]")

                    semaphore.signal()

                }

                semaphore.wait()

                // logger.debug("Waiting on semaphore finished [reason: \(reason)]")

            }
        }

    }

}
