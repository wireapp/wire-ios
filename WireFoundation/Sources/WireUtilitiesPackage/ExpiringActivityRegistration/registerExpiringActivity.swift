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

public func registerExpiringActivity(
    reason: String,
    task: Task<some Sendable, some Error>
) {
    registerExpiringActivity(
        performer: ProcessInfo.processInfo.performExpiringActivity(withReason:using:),
        reason: reason,
        task: task
    )
}

// MARK: - Helpers for making the code testable

typealias ExpiringActivityPerformer = (
    _ reason: String,
    _ block: @escaping @Sendable (_ isExpiring: Bool) -> Void
) -> Void

func registerExpiringActivity(
    performer performExpiringActivity: ExpiringActivityPerformer,
    reason: String,
    task: Task<some Sendable, some Error>
) {

    performExpiringActivity(reason) { isExpiring in

        if isExpiring {

            // System is revoking background time — cancel the task.
            task.cancel()

        } else {

            // System granted time. Block this callback until the task finishes,
            // so the system knows we're still doing work.
            let semaphore = DispatchSemaphore(value: 0)
            defer { semaphore.wait() }

            Task<Void, Never> {
                // We only need to wait for the task to complete; the result is irrelevant.
                _ = try? await task.value
                semaphore.signal()
            }

        }
    }

}
