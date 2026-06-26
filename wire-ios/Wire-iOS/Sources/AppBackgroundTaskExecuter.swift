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

import os
import UIKit

import WireLogging
import WireSystem

// sourcery: AutoMockable
/// The subset of `UIApplication`'s background task APIs that `AppBackgroundTaskExecuter` depends on.
public protocol BackgroundTaskApplication: AnyObject, Sendable {

    nonisolated func beginBackgroundTask(
        withName taskName: String?,
        expirationHandler handler: (@MainActor @Sendable () -> Void)?
    ) -> UIBackgroundTaskIdentifier

    nonisolated func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier)

    var applicationState: UIApplication.State { get }
}

extension UIApplication: BackgroundTaskApplication {}

/// A `BackgroundTaskExecuter` that uses `UIApplication`'s background task APIs to execute the provided operation in
/// the background.
/// - warning: This executer should only be used from the main app.
public struct AppBackgroundTaskExecuter: BackgroundTaskExecuter {

    private final class OperationState<T>: Sendable {
        let _taskID = OSAllocatedUnfairLock(initialState: UIBackgroundTaskIdentifier.invalid)
        let _task = OSAllocatedUnfairLock(initialState: Optional<Task<T, any Error>>.none)

        var taskID: UIBackgroundTaskIdentifier {
            get { _taskID.withLock { $0 } }
            set { _taskID.withLock { $0 = newValue } }
        }

        var task: Task<T, any Error>? {
            get { _task.withLock { $0 } }
            set { _task.withLock { $0 = newValue } }
        }
    }

    private let application: any BackgroundTaskApplication

    public init(application: any BackgroundTaskApplication) {
        self.application = application
    }

    public func execute<T: Sendable>(
        name: String?,
        operation: sending @escaping () async throws -> T
    ) async throws -> T {
        let name = name ?? "unnamed"

        guard application.applicationState != .background else {
            WireLogger.backgroundActivity.debug("background task \(name) cannot begin in the background")
            throw CancellationError()
        }

        let operationState = OperationState<T>()
        operationState.taskID = application.beginBackgroundTask(withName: name) {
            WireLogger.backgroundActivity.warn("background task \(name) expiring soon. Cancelling...")

            operationState.task?.cancel()

            // Eagerly end the background task to avoid the app being killed in case that cancellation takes too long.
            endBackgroundTask(operationState)
        }

        if operationState.taskID == .invalid {
            WireLogger.backgroundActivity.error("begin background task returned .invalid ID for task: \(name)")
            throw CancellationError()
        }

        // Don't start the task until we have a valid background task ID.
        let task = Task {
            WireLogger.backgroundActivity.debug("will start background task: \(name)")
            let result = try await operation()
            WireLogger.backgroundActivity.debug("did end background task: \(name)")
            return result
        }
        operationState.task = task

        defer { endBackgroundTask(operationState) }
        return try await withTaskCancellationHandler {
            try await task.value
        } onCancel: {
            task.cancel()
        }
    }

    private nonisolated func endBackgroundTask<T>(_ operationState: OperationState<T>) {
        guard operationState.taskID != .invalid else { return }

        application.endBackgroundTask(operationState.taskID)
        operationState.taskID = .invalid
    }
}
