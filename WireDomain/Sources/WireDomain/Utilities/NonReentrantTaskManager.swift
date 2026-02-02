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

public actor NonReentrantTaskManager<Success, Failure>: Sendable where Success: Sendable, Failure: Error {

    private var state: TaskState = .idle

    public init() {}

    private enum TaskState {

        case idle
        case inFlight(Task<Success, Failure>)

    }

}

public extension NonReentrantTaskManager where Failure == any Error {

    /// Perform a non-reentrant async block that cannot throw.
    ///
    /// - Parameter block: The async block to perform.
    /// - Returns: The result of the async block.
    /// - Throws: Rethrows any error thrown by the async block.

    func performIfNeeded(block: @escaping @Sendable () async throws -> Success) async throws -> Success {
        defer {
            state = .idle
        }

        switch state {
        case let .inFlight(task):
            // Wait for existing task.
            return try await task.value

        case .idle:
            // Create a new task.
            let task = Task {
                try await block()
            }

            state = .inFlight(task)
            return try await task.value
        }
    }

}

public extension NonReentrantTaskManager where Failure == Never {

    /// Perform a non-reentrant async block that cannot throw.
    ///
    /// - Parameter block: The async block to perform.
    /// - Returns: The result of the async block.

    func performIfNeeded(block: @escaping @Sendable () async -> Success) async -> Success {
        defer {
            state = .idle
        }

        switch state {
        case let .inFlight(task):
            // Wait for existing task.
            return await task.value

        case .idle:
            // Create a new task.
            let task = Task {
                await block()
            }

            state = .inFlight(task)
            return await task.value
        }
    }

}
