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

    // MARK: - Life cycle

    private var task: Task<Void, Never>?
    private let scheduler: any WorkScheduler
    private var workers: [any Worker]

    private let logger = WireLogger(tag: "work-agent")

    init() {
        scheduler = ThreeTierWorkScheduler()
        workers = []
    }

    deinit {
        stop()
    }

    // MARK: - Operation

    func registerWorker(_ worker: any Worker) {
        workers.append(worker)
    }

    func submitTicket(_ ticket: any WorkTicket) {
        logger.debug("ticket submitted: \(ticket)", attributes: .safePublic)
        scheduler.enqueueTicket(ticket)
        Task {
            await start()
        }
    }

    func start() async {
        guard task == nil else {
            return
        }

        logger.info("starting", attributes: .safePublic)

        task = Task {
            let startTime = Date()
            var completedTickets = 0

            while let ticket = scheduler.dequeueNextTicket() {
                logger.debug("dequeued ticket: \(ticket)", attributes: .safePublic)

                guard let worker = workers.first(where: {
                    $0.id == ticket.workerID
                }) else {
                    logger.warn("didn't find worker for ticket: \(ticket)", attributes: .safePublic)
                    continue
                }

                do {
                    try await worker.performWork(for: ticket)
                    completedTickets += 1
                    logger.debug("ticket complete: \(ticket)", attributes: .safePublic)
                } catch {
                    logger.error("ticket failed, dorpping: \(ticket)", attributes: .safePublic)
                    continue
                }
            }

            let duration = Date().timeIntervalSince(startTime)
            let durationString = String(format: "%.2f seconds", duration)
            logger.info(
                "completed \(completedTickets) tickets in \(durationString)",
                attributes: .safePublic
            )
        }

        await task?.value
        task = nil
    }

    func stop() {
        logger.info("stopping", attributes: .safePublic)
        task?.cancel()
        task = nil
    }

}
