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

/// An object that facilitates non-reentrant calls to an async block.
///
/// Use this object to ensure that an async block is executed only once
/// at any given time, regardless how many times the block is enqueued.
/// Repeated invocations don't result in repeated executions.

public actor NonReentrantTaskManager {

    private var state: TaskState = .idle

    public init() {}

    public func performIfNeeded(block: @escaping @Sendable () async throws -> Void) async throws {
        defer {
            state = .idle
        }

        switch state {
        case let .inFlight(task):
            // Wait for existing task.
            try await task.value

        case .idle:
            // Create a new task.
            let task = Task {
                try await block()
            }

            state = .inFlight(task)
            try await task.value
        }
    }

    private enum TaskState {

        case idle
        case inFlight(Task<Void, any Error>)

    }

}
