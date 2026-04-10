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

// sourcery: AutoMockable
protocol ExpiringActivityPerformer {

    func performExpiringActivity(
        reason: String,
        using block: @escaping @Sendable (_ isExpiring: Bool) -> Void
    )

}

extension ExpiringActivityPerformer {

    func performTaskCancellationAsExpiringActivity(
        reason: String,
        task: Task<some Sendable, some Error>
    ) {

        let semaphore = DispatchSemaphore(value: 0)
        performExpiringActivity(reason: reason) { isExpiring in

            if isExpiring {

                // System is revoking background time — cancel the task.
                task.cancel()
                // Calling signal() here in order to unblock the first invocation of this closure and prevent the system
                // from killing the app. The execution of the task however, might be suspended.
                semaphore.signal()

            } else {

                // System granted time. Block this callback until the task finishes,
                // so the system knows we're still doing work.
                Task.detached {
                    // We only need to wait for the task to complete; the result is irrelevant.
                    _ = try? await task.value
                    semaphore.signal()
                }
                semaphore.wait()

            }
        }

    }

}
