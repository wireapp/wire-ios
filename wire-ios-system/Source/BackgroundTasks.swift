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

public protocol BackgroundTaskExecuter: Sendable {
    func execute<T: Sendable>(
        name: String?,
        operation: @escaping @isolated(any) () async throws -> T
    ) async throws -> T
}

public enum BackgroundTaskContext {
    @TaskLocal public static var isBackgroundTask = false
}

public func withBackgroundTask<T: Sendable>(
    name: String? = nil,
    executer: any BackgroundTaskExecuter,
    operation: @escaping @isolated(any) () async throws -> T
) async throws -> T {
    // If we are already in a background task, just execute the operation directly
    if BackgroundTaskContext.isBackgroundTask {
        try await operation()
    } else {
        try await BackgroundTaskContext.$isBackgroundTask.withValue(true) {
            try await executer.execute(name: name, operation: operation)
        }
    }
}

/// A ``BackgroundTaskExecuter`` that simply executes the operation without any background task management.
public struct PassthroughTaskExecuter: BackgroundTaskExecuter {

    public init() {}

    public func execute<T: Sendable>(
        name: String?,
        operation: @escaping @isolated(any) () async throws -> T
    ) async throws -> T {
        try await operation()
    }

}
