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
@preconcurrency import WireTransport

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

    private final class OperationState<T>: Sendable {
        let _taskID = OSAllocatedUnfairLock(initialState: UIBackgroundTaskIdentifier.invalid)
        let _task = OSAllocatedUnfairLock(initialState: Task<T, any Error>?.none)
        let _isExpired = OSAllocatedUnfairLock(initialState: false)

        var taskID: UIBackgroundTaskIdentifier {
            get { _taskID.withLock { $0 } }
            set { _taskID.withLock { $0 = newValue } }
        }

        var task: Task<T, any Error>? {
            get { _task.withLock { $0 } }
            set { _task.withLock { $0 = newValue } }
        }

        var isExpired: Bool {
            get { _isExpired.withLock { $0 } }
            set { _isExpired.withLock { $0 = newValue } }
        }
    }

    private let application: any BackgroundTaskApplication
    private let applicationState: ApplicationState
    private let backgroundActivityFactory: BackgroundActivityFactory

    @MainActor
    public init(
        application: any BackgroundTaskApplication,
        isInBackground: Bool,
        backgroundActivityFactory: BackgroundActivityFactory = BackgroundActivityFactory.shared
    ) {
        self.application = application
        self.applicationState = ApplicationState(isInBackground: isInBackground)
        self.backgroundActivityFactory = backgroundActivityFactory
    }

    @MainActor
    public func startObservingLifecycleNotifications() {
        applicationState.startObservingLifecycleNotifications()
    }

    // MARK: - Private

    public func execute<T: Sendable>(
        name: String?,
        operation: @escaping @isolated(any) () async throws -> T
    ) async throws -> T {
        if DeveloperFlag.useBackgroundTaskAPIInAppBackgroundTaskExecuter.isOn {
            try await executeUsingBackgroundTaskAPI(name: name, operation: operation)
        } else {
            try await executeUsingBackgroundActivityFactory(name: name, operation: operation)
        }
    }

    // MARK: BackgroundTaskAPI implementation

    private func executeUsingBackgroundTaskAPI<T: Sendable>(
        name: String?,
        operation: @escaping @isolated(any) () async throws -> T
    ) async throws -> T {
        let name = name ?? "unnamed"

        guard applicationState.isInBackground != true else {
            WireLogger.backgroundActivity.debug("background task \(name) cannot begin in the background")
            throw CancellationError()
        }

        let operationState = OperationState<T>()
        operationState.taskID = application.beginBackgroundTask(withName: name) {
            operationState.isExpired = true

            WireLogger.backgroundActivity.warn("background task \(name) expiring soon. Cancelling...")
            operationState.task?.cancel()

            // Eagerly end the background task to avoid the app being killed in case that cancellation takes too long.
            endBackgroundTask(operationState)
        }
        defer { endBackgroundTask(operationState) }

        if operationState.taskID == .invalid || operationState.isExpired {
            WireLogger.backgroundActivity.warn("begin background task \(name) failed or expired before starting")
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

        return try await withTaskCancellationHandler {
            try await task.value
        } onCancel: {
            task.cancel()
        }
    }

    private nonisolated func endBackgroundTask(_ operationState: OperationState<some Any>) {
        guard operationState.taskID != .invalid else { return }

        application.endBackgroundTask(operationState.taskID)
        operationState.taskID = .invalid
    }

    // MARK: BackgroundActivityFactory implementation

    private func executeUsingBackgroundActivityFactory<T: Sendable>(
        name: String?,
        operation: @escaping @isolated(any) () async throws -> T
    ) async throws -> T {
        let name = name ?? "unnamed"

        guard let activity = backgroundActivityFactory.startBackgroundActivity(name: name) else {
            WireLogger.backgroundActivity.debug("background task \(name) cannot begin")
            throw CancellationError()
        }

        let task = Task {
            WireLogger.backgroundActivity.debug("will start background task: \(name)")

            do {
                let result = try await operation()
                WireLogger.backgroundActivity.debug("did end background task: \(name)")
                return result
            } catch {
                if error is CancellationError {
                    WireLogger.backgroundActivity.debug("did cancel background task: \(name)")
                } else {
                    WireLogger.backgroundActivity.warn("did fail background task: \(name)")
                }
                throw error
            }
        }

        activity.expirationHandler = {
            WireLogger.backgroundActivity.warn(
                "background task \(name) expiring soon. Cancelling..."
            )
            task.cancel()
        }

        defer { backgroundActivityFactory.endBackgroundActivity(activity) }

        return try await withTaskCancellationHandler {
            try await task.value
        } onCancel: {
            task.cancel()
        }
    }
}

@MainActor
private final class ApplicationState: AnyObject {

    private nonisolated let _isInBackground: OSAllocatedUnfairLock<Bool>

    init(isInBackground: Bool) {
        self._isInBackground = OSAllocatedUnfairLock(initialState: isInBackground)
    }

    func startObservingLifecycleNotifications() {
        let center = NotificationCenter.default
        center.addObserver(
            self,
            selector: #selector(didEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(willEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    nonisolated var isInBackground: Bool {
        _isInBackground.withLock { $0 }
    }

    // MARK: - Notification Handling

    @objc
    private func didEnterBackground() {
        _isInBackground.withLock { $0 = true }
    }

    @objc
    private func willEnterForeground() {
        _isInBackground.withLock { $0 = false }
    }
}
