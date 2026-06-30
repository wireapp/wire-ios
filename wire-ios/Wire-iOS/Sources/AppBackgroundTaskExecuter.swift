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
}

extension UIApplication: BackgroundTaskApplication {}

/// A `BackgroundTaskExecuter` that uses `UIApplication`'s background task APIs to execute the provided operation in
/// the background.
/// - warning: This executer should only be used from the main app.
public struct AppBackgroundTaskExecuter: BackgroundTaskExecuter {

    private final class TaskID: Sendable {
        let state = OSAllocatedUnfairLock(initialState: UIBackgroundTaskIdentifier.invalid)

        var value: UIBackgroundTaskIdentifier {
            get { state.withLock { $0 } }
            set { state.withLock { $0 = newValue } }
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

        let task = Task {
            WireLogger.backgroundActivity.debug("will start background task: \(name)")
            let result = try await operation()
            WireLogger.backgroundActivity.debug("did end background task: \(name)")
            return result
        }

        let taskID = TaskID()
        taskID.value = application.beginBackgroundTask(withName: name) {
            WireLogger.backgroundActivity.warn("background task \(name) expiring soon. Cancelling...")

            task.cancel()

            // Eagerly end the background task to avoid the app being killed in case that cancellation takes too long.
            endBackgroundTask(taskID)
        }
        if taskID.value == .invalid {
            WireLogger.backgroundActivity.error("begin background task returned .invalid ID for task: \(name)")
        }

        defer { endBackgroundTask(taskID) }
        return try await withTaskCancellationHandler {
            try await task.value
        } onCancel: {
            task.cancel()
        }
    }

    private nonisolated func endBackgroundTask(_ identifier: TaskID) {
        guard identifier.value != .invalid else { return }

        application.endBackgroundTask(identifier.value)
        identifier.value = .invalid
    }
}
