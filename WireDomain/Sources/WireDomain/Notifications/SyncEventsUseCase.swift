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

import WireLogging
import WireNetwork

// sourcery: AutoMockable
protocol SyncEventsUseCaseProtocol {
    func invoke() async throws
}

struct SyncEventsUseCase: SyncEventsUseCaseProtocol {
    enum Failure: Error {
        case timedOut
        case pendingEventsSyncFailed(Error)
    }

    let pendingEventsSync: PullPendingUpdateEventsSyncV2Protocol
    let timeout: Duration
    init(
        pendingEventsSync: PullPendingUpdateEventsSyncV2Protocol,
        timeout: Duration = .seconds(25)
    ) {
        self.pendingEventsSync = pendingEventsSync
        self.timeout = timeout
    }

    func invoke() async throws {
        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await pendingEventsSync.pull()
                }

                group.addTask {
                    try await Task.sleep(for: timeout)
                    // we're almost out of time better to stop the pulling
                    throw CancellationError()
                }

                defer { group.cancelAll() }
                // get the first task to finish
                try await group.next()
            }
        } catch is CancellationError {
            throw Failure.timedOut
        } catch {
            throw Failure.pendingEventsSyncFailed(error)
        }
    }

}
