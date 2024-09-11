//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
    let api: ExpiringActivityInterface
    var task: Task<Void, Error>?

    init() {
        self.init(api: ProcessInfo.processInfo)
    }

    init(api: ExpiringActivityInterface) {
        self.api = api
    }

    func withExpiringActivity(reason: String, block: @escaping () async throws -> Void) async throws {
        try await withCheckedThrowingContinuation { continuation in
            api.performExpiringActivity(withReason: reason) { expiring in
                if !expiring {
                    let semaphore = DispatchSemaphore(value: 0)
                    Task {
                        do {
                            WireLogger.backgroundActivity.debug("Start of activity: \(reason)")
                            try await self.startWork(block: block, semaphore: semaphore).value
                            WireLogger.backgroundActivity.debug("Expiring activity completed: \(reason)")
                            continuation.resume()
                        } catch {
                            WireLogger.backgroundActivity.warn("Expiring activity ended with an error: \(error)")
                            continuation.resume(throwing: error)
                        }
                    }
                    semaphore.wait()
                } else {
                    WireLogger.backgroundActivity.warn("Background activity is expiring: \(reason)")
                    Task {
                        do {
                            try await self.stopWork()
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }
        }
    }

    func startWork(block: @escaping () async throws -> Void, semaphore: DispatchSemaphore) -> Task<Void, Error> {
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

    func stopWork() throws {
        guard let task else { throw ExpiringActivityNotAllowedToRun() }
        task.cancel()
        self.task = nil
    }
}
