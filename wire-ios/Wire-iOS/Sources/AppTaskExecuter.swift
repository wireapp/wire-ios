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

public struct AppTaskExecuter: BackgroundTaskExecuter {

    private final class TaskID: Sendable {
        let state = OSAllocatedUnfairLock(initialState: UIBackgroundTaskIdentifier.invalid)

        var value: UIBackgroundTaskIdentifier {
            get { state.withLock { $0 } }
            set { state.withLock { $0 = newValue } }
        }
    }

    private let application: UIApplication

    public init(application: UIApplication) {
        self.application = application
    }

    public func execute<T: Sendable>(
        name: String?,
        operation: sending @escaping () async throws -> T
    ) async throws -> T {
        let task = Task { try await operation() }

        let taskID = TaskID()
        taskID.value = application.beginBackgroundTask(withName: name) { [application] in
            WireLogger.backgroundActivity.warn(
                "Background task \(name ?? "unnamed") expiring soon. Cancelling...",
                attributes: .safePublic
            )

            task.cancel()

            // Eagerly end the background task to avoid the app being killed in case that cancellation takes too long.
            application.endBackgroundTask(taskID.value)
            taskID.value = .invalid
        }

        let result = try await withTaskCancellationHandler {
            try await task.value
        } onCancel: {
            task.cancel()
        }
        application.endBackgroundTask(taskID.value)

        return result
    }

}
