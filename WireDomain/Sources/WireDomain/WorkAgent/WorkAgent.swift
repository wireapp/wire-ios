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

final class WorkAgent {

    // MARK: - Properties

    /// Whether the agent is currently dequeuing work tickets.

    var isRunning: Bool {
        task != nil
    }

    /// Whether dequeuing should begin after ticket submission.

    var shouldAutoStart = false

    // MARK: - Life cycle

    private var task: Task<Void, Never>?
    private let scheduler: any WorkScheduler
    private var workers: [any Worker] = []
    private let nonReentrantTaskManager = NonReentrantTaskManager()

    init(scheduler: any WorkScheduler) {
        self.scheduler = scheduler
    }

    deinit {
        stop()
    }

    // MARK: - Operation

    func registerWorker(_ worker: any Worker) {
        workers.append(worker)
    }

    func submitTicket(_ ticket: any WorkTicket) {
        WireLogger.workAgent.debug("ticket submitted: \(ticket)", attributes: .safePublic)
        scheduler.enqueueTicket(ticket)

        if shouldAutoStart {
            Task {
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

        WireLogger.workAgent.info("starting", attributes: .safePublic)

        task = Task {
            let startTime = Date()
            var completedTickets = 0

            while let ticket = scheduler.dequeueNextTicket() {
                WireLogger.workAgent.debug("dequeued ticket: \(ticket)", attributes: .safePublic)

                guard let worker = workers.first(where: {
                    $0.id == ticket.workerID
                }) else {
                    WireLogger.workAgent.warn("didn't find worker for ticket: \(ticket)", attributes: .safePublic)
                    continue
                }

                do {
                    try await worker.performWork(for: ticket)
                    completedTickets += 1
                    WireLogger.workAgent.debug("ticket complete: \(ticket)", attributes: .safePublic)
                } catch {
                    WireLogger.workAgent.error("ticket failed, dorpping: \(ticket)", attributes: .safePublic)
                    continue
                }
            }

            let duration = Date().timeIntervalSince(startTime)
            let durationString = String(format: "%.2f seconds", duration)
            WireLogger.workAgent.info(
                "completed \(completedTickets) tickets in \(durationString)",
                attributes: .safePublic
            )
        }

        await task?.value
        task = nil
    }

    func stop() {
        WireLogger.workAgent.info("stopping", attributes: .safePublic)
        task?.cancel()
        task = nil
    }

}
