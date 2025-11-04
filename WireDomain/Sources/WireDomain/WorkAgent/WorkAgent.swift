//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireLogging

actor WorkAgent {

    // MARK: - Properties

    /// Whether the agent is currently dequeuing work tickets.

    var isRunning: Bool {
        task != nil
    }

    /// Whether dequeuing should begin after ticket submission.

    private var shouldAutoStart = false
    func setAutoStartEnabled(_ enabled: Bool) async {
        shouldAutoStart = enabled
    }

    // MARK: - Life cycle

    private var task: Task<Void, Never>?
    private let scheduler: any WorkItemScheduler
    private let nonReentrantTaskManager = NonReentrantTaskManager()

    init(scheduler: any WorkItemScheduler) {
        self.scheduler = scheduler
    }

    // MARK: - Operation

    func submitItem(_ item: any WorkItem) {
        WireLogger.workAgent.debug(
            "item submitted: \(item)",
            attributes: .init(item)
        )

        Task {
            await scheduler.enqueueItem(item)

            if shouldAutoStart, !isRunning {
                await start()
            }
        }
    }

    func start() async {
        try? await nonReentrantTaskManager.performIfNeeded { [weak self] in
            await self?.internalStart()
        }
    }

    private func internalStart() async {
        guard task == nil else {
            return
        }

        WireLogger.workAgent.info(
            "starting",
            attributes: .safePublic
        )

        task = Task {
            let startTime = Date()
            var completedItems = 0

            while let item = await scheduler.dequeueNextItem() {
                do {
                    try Task.checkCancellation()
                } catch {
                    WireLogger.workAgent.debug(
                        "task has been cancelled, aborting...",
                        attributes: .init(item)
                    )
                    break
                }

                WireLogger.workAgent.debug(
                    "dequeued item",
                    attributes: .init(item)
                )

                do {
                    try await item.start()
                    completedItems += 1
                    WireLogger.workAgent.debug(
                        "item complete",
                        attributes: .init(item)
                    )
                } catch {
                    WireLogger.workAgent.error(
                        "item failed, dropping",
                        attributes: .init(item)
                    )
                    continue
                }
            }

            let duration = Date().timeIntervalSince(startTime)
            let durationString = String(format: "%.2f seconds", duration)
            WireLogger.workAgent.info(
                "completed \(completedItems) tickets in \(durationString)",
                attributes: .safePublic
            )
        }

        await task?.value
        task = nil
    }

    func stop() {
        WireLogger.workAgent.info(
            "stopping",
            attributes: .safePublic
        )
        task?.cancel()
        task = nil
    }

}

private extension LogAttributes {

    init(_ item: any WorkItem) {
        self = [
            .public: true,
            .workItemID: "\(item.id)"
        ]
    }

}
