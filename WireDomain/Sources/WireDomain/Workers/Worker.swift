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
import Network
import UIKit

/// Performs a unit of work. Using triggers, allows work to be retried when it fails, or to be performed at specific
/// intervals or when specific events occur.
public actor Worker {

    private let work: @Sendable () async -> Bool
    private let interval: TimeInterval
    private let trigger: AsyncStream<Void>

    private var triggerTask: Task<Void, Never>?
    private var isRunning = false
    private var lastSuccess: Date?

    /// Creates a new Worker.
    ///
    /// - Parameters:
    ///   - work: The work to be performed. The work should return `true` if it succeeded, otherwise `false`.
    ///   - interval: The interval after which the work should be performed again if it succeeded.
    ///   - trigger: The trigger that will cause the work to be performed.
    public init(
        work: @escaping @Sendable () async -> Bool,
        interval: TimeInterval,
        trigger: AsyncStream<Void>
    ) {
        self.work = work
        self.interval = interval
        self.trigger = trigger
    }

    deinit {
        triggerTask?.cancel()
    }

    /// Starts the worker.
    public nonisolated func start() {
        Task { await self.startAndWait() }
    }

    // MARK: - Private

    func startAndWait() async {
        guard triggerTask == nil else { return }

        triggerTask = Task {
            for await _ in trigger {
                await self.performWorkIfNeeded()
            }
        }
        await triggerTask?.value
    }

    private func isStale() -> Bool {
        guard let lastSuccess else { return true }
        return lastSuccess.addingTimeInterval(interval) < Date()
    }

    private func performWorkIfNeeded() async {
        guard isStale(), !isRunning else { return }

        isRunning = true
        let succeeded = await work()
        if succeeded {
            lastSuccess = Date()
        }
        isRunning = false
    }

    // MARK: - Trigger

    public static func defaultTrigger() -> AsyncStream<Void> {
        AsyncStream { continuation in
            continuation.yield()

            let isOnlineTrigger = Task {
                let monitor = NWPathMonitor()
                for await path in monitor where path.status == .satisfied {
                    continuation.yield()
                }
            }

            let intervalTrigger = Task {
                while true {
                    try await Task.sleep(for: .seconds(60 * 30)) // 30 min
                    continuation.yield()
                }
            }

            let willEnterForegroundTrigger = Task {
                let notificationCenter = NotificationCenter.default
                for await _ in notificationCenter.notifications(named: UIApplication.willEnterForegroundNotification) {
                    continuation.yield()
                }
            }

            continuation.onTermination = { _ in
                isOnlineTrigger.cancel()
                intervalTrigger.cancel()
                willEnterForegroundTrigger.cancel()
            }
        }
    }

}
