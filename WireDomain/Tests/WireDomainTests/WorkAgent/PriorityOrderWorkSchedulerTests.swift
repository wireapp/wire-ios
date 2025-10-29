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
import Testing
@testable import WireDomain

struct PriorityOrderWorkSchedulerTests {

    let sut = PriorityOrderWorkScheduler()

    @Test("It deqeues in priority order")
    func itDequeuesInPriorityOrder() async throws {
        // Given
        let lowPriorityTicket = MockWorkTicket(priority: .low)
        let mediumPriorityTicket = MockWorkTicket(priority: .medium)
        let highPriorityTicket = MockWorkTicket(priority: .high)
        let blockerPriorityTicket = MockWorkTicket(priority: .blocker)
        let criticalPriorityTicket = MockWorkTicket(priority: .critical)

        // When
        sut.enqueueTicket(lowPriorityTicket)
        sut.enqueueTicket(mediumPriorityTicket)
        sut.enqueueTicket(highPriorityTicket)
        sut.enqueueTicket(blockerPriorityTicket)
        sut.enqueueTicket(criticalPriorityTicket)

        // Then
        try #require(sut.dequeueNextTicket()?.id == criticalPriorityTicket.id)
        try #require(sut.dequeueNextTicket()?.id == blockerPriorityTicket.id)
        try #require(sut.dequeueNextTicket()?.id == highPriorityTicket.id)
        try #require(sut.dequeueNextTicket()?.id == mediumPriorityTicket.id)
        try #require(sut.dequeueNextTicket()?.id == lowPriorityTicket.id)
        #expect(sut.dequeueNextTicket() == nil)
    }

    @Test("It dequeues tickets of same priority in FIFO order")
    func itDequeuesTicketsOfSamePriorityInFIFOOrder() async throws {
        // Given
        let ticket1 = MockWorkTicket(priority: .low)
        let ticket2 = MockWorkTicket(priority: .high)
        let ticket3 = MockWorkTicket(priority: .medium)
        let ticket4 = MockWorkTicket(priority: .low)
        let ticket5 = MockWorkTicket(priority: .critical)
        let ticket6 = MockWorkTicket(priority: .medium)
        let ticket7 = MockWorkTicket(priority: .critical)
        let ticket8 = MockWorkTicket(priority: .blocker)
        let ticket9 = MockWorkTicket(priority: .high)
        let ticket10 = MockWorkTicket(priority: .blocker)

        // When
        sut.enqueueTicket(ticket1)
        sut.enqueueTicket(ticket2)
        sut.enqueueTicket(ticket3)
        sut.enqueueTicket(ticket4)
        sut.enqueueTicket(ticket5)
        sut.enqueueTicket(ticket6)
        sut.enqueueTicket(ticket7)
        sut.enqueueTicket(ticket8)
        sut.enqueueTicket(ticket9)
        sut.enqueueTicket(ticket10)

        // Then
        try #require(sut.dequeueNextTicket()?.id == ticket5.id)
        try #require(sut.dequeueNextTicket()?.id == ticket7.id)
        try #require(sut.dequeueNextTicket()?.id == ticket8.id)
        try #require(sut.dequeueNextTicket()?.id == ticket10.id)
        try #require(sut.dequeueNextTicket()?.id == ticket2.id)
        try #require(sut.dequeueNextTicket()?.id == ticket9.id)
        try #require(sut.dequeueNextTicket()?.id == ticket3.id)
        try #require(sut.dequeueNextTicket()?.id == ticket6.id)
        try #require(sut.dequeueNextTicket()?.id == ticket1.id)
        try #require(sut.dequeueNextTicket()?.id == ticket4.id)
    }

    @Test("Dequeuing considers newly enqueued tickets")
    func dequeuingConsidersNewlyEnqueuedTickets() async throws {
        // Given
        let medium1 = MockWorkTicket(priority: .medium)
        let high1 = MockWorkTicket(priority: .high)
        let low1 = MockWorkTicket(priority: .low)
        let low2 = MockWorkTicket(priority: .low)
        let critical1 = MockWorkTicket(priority: .critical)

        // When
        sut.enqueueTicket(medium1)
        sut.enqueueTicket(high1)

        // Then
        try #require(sut.dequeueNextTicket()?.id == high1.id)

        // When
        sut.enqueueTicket(low1)

        // Then
        try #require(sut.dequeueNextTicket()?.id == medium1.id)

        // When
        sut.enqueueTicket(low2)

        // Then
        try #require(sut.dequeueNextTicket()?.id == low1.id)

        // When
        sut.enqueueTicket(critical1)

        // Then
        try #require(sut.dequeueNextTicket()?.id == critical1.id)
        try #require(sut.dequeueNextTicket()?.id == low2.id)
        #expect(sut.dequeueNextTicket() == nil)
    }

}

private struct MockWorkTicket: WorkTicket, Equatable {

    let id = UUID()
    let workerID = UUID()
    var priority: WorkTicketPriority

}
