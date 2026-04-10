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
        performer: ProcessInfoWrapper(),
        reason: reason,
        task: task
    )
}

func registerExpiringActivity(
    performer: some ExpiringActivityPerformer,
    reason: String,
    task: Task<some Sendable, some Error>
) {

    performer.performExpiringActivity(reason: reason) { isExpiring in

        if isExpiring {

            // System is revoking background time — cancel the task.
            task.cancel()

        } else {

            // System granted time. Block this callback until the task finishes,
            // so the system knows we're still doing work.
            let semaphore = DispatchSemaphore(value: 0)
            Task.detached {
                // We only need to wait for the task to complete; the result is irrelevant.
                _ = try? await task.value
                semaphore.signal()
            }
            semaphore.wait()

        }
    }

}

private struct ProcessInfoWrapper: ExpiringActivityPerformer {

    var processInfo: ProcessInfo

    init(processInfo: ProcessInfo = .processInfo) {
        self.processInfo = processInfo
    }

    func performExpiringActivity(reason: String, using block: @escaping @Sendable (Bool) -> Void) {
        processInfo.performExpiringActivity(withReason: reason, using: block)
    }

}
