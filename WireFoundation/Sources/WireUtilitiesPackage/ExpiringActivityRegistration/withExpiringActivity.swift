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

private let sharedManager = ExpiringActivityManager(
    performer: ExpiringActivityProcessInfoWrapper()
)

// MARK: - Non-throwing

public func withExpiringActivity(
    reason: String,
    block: @escaping @Sendable () async -> Void
) async {
    await withExpiringActivity(
        manager: sharedManager,
        reason: reason,
        block: block
    )
}

func withExpiringActivity(
    manager: ExpiringActivityManager,
    reason: String,
    block: @escaping @Sendable () async -> Void
) async {
    let task = Task(operation: block)
    await manager.track(reason: reason, task: task)
    await withTaskCancellationHandler {
        await task.value
    } onCancel: {
        task.cancel()
    }
}

// MARK: - Throwing

public func withExpiringActivity(
    reason: String,
    block: @escaping @Sendable () async throws -> Void
) async throws {
    try await withExpiringActivity(
        manager: sharedManager,
        reason: reason,
        block: block
    )
}

func withExpiringActivity(
    manager: ExpiringActivityManager,
    reason: String,
    block: @escaping @Sendable () async throws -> Void
) async throws {
    let task = Task(operation: block)
    await manager.track(reason: reason, task: task)
    try await withTaskCancellationHandler {
        try await task.value
    } onCancel: {
        task.cancel()
    }
}
