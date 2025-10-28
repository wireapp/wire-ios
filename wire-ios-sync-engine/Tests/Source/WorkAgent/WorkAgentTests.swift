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

import Testing
@testable import WireSyncEngine

struct WorkAgentTests {

    private let scheduler: MockScheduler
    private let sut: WorkAgent

    init() {
        scheduler = MockScheduler()
        sut = WorkAgent(scheduler: scheduler)
        sut.shouldAutoStart = false
    }

    @Test("Submitted tickets are performed")
    func submittedTicketsArePerformed() async throws {
        // Given
        let worker1 = MockWorker()
        let worker2 = MockWorker()
        sut.registerWorker(worker1)
        sut.registerWorker(worker2)

        let ticket1 = MockWorker.Ticket(
            id: UUID(),
            workerID: worker1.id,
            priority: .medium
        )

        let ticket2 = MockWorker.Ticket(
            id: UUID(),
            workerID: worker2.id,
            priority: .medium
        )

        let ticket3 = MockWorker.Ticket(
            id: UUID(),
            workerID: worker1.id,
            priority: .medium
        )

        // When
        sut.submitTicket(ticket1)
        sut.submitTicket(ticket2)
        sut.submitTicket(ticket3)
        await sut.start()

        // Then
        // All tickets were enqueued and dequeued.
        let allTicketIDs = [ticket1, ticket2, ticket3].map(\.id)
        #expect(scheduler.enqueuedTickets.map(\.id) == allTicketIDs)
        #expect(scheduler.dequeuedTickets.map(\.id) == allTicketIDs)

        // All tickets were performed by the correct worker.
        #expect(await worker1.performedTickets.map(\.id) == [ticket1.id, ticket3.id])
        #expect(await worker2.performedTickets.map(\.id) == [ticket2.id])
    }

    @Test("Submitted tickets are performed only once")
    func submittedTicketsArePerformedOnlyOnce() async throws {
        // Given
        let worker1 = MockWorker()
        sut.registerWorker(worker1)

        let ticket1 = MockWorker.Ticket(
            id: UUID(),
            workerID: worker1.id,
            priority: .medium
        )

        // When
        sut.submitTicket(ticket1)
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await sut.start()
            }

            group.addTask {
                await sut.start()
            }

            group.addTask {
                await sut.start()
            }
        }

        // Then
        // The ticket was enqueued, dequeued, and performed only once.
        #expect(scheduler.enqueuedTickets.map(\.id) == [ticket1.id])
        #expect(scheduler.dequeuedTickets.map(\.id) == [ticket1.id])
        #expect(await worker1.performedTickets.map(\.id) == [ticket1.id])
    }

}

private actor MockWorker: Worker {

    struct Ticket: WorkTicket {

        let id: UUID
        let workerID: UUID
        let priority: WorkTicketPriority

    }

    let id = UUID()
    var performedTickets: [Ticket] = []

    func performWork(for ticket: Ticket) async throws {
        performedTickets.append(ticket)
    }

}

private class MockScheduler: WorkScheduler {

    var tickets: [any WorkTicket] = []
    var enqueuedTickets: [any WorkTicket] = []
    var dequeuedTickets: [any WorkTicket] = []

    func enqueueTicket(_ ticket: any WorkTicket) {
        enqueuedTickets.append(ticket)
        tickets.append(ticket)
    }

    func dequeueNextTicket() -> (any WorkTicket)? {
        guard !tickets.isEmpty else { return nil }
        let ticket = tickets.removeFirst()
        dequeuedTickets.append(ticket)
        return ticket
    }

}
