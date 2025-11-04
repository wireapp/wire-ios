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

struct PriorityOrderWorkItemSchedulerTests {

    let sut = PriorityOrderWorkItemScheduler()

    @Test("It deqeues in priority order")
    func itDequeuesInPriorityOrder() async throws {
        // Given
        let lowPriorityItem = MockWorkItem(priority: .low)
        let mediumPriorityItem = MockWorkItem(priority: .medium)
        let highPriorityItem = MockWorkItem(priority: .high)
        let blockerPriorityItem = MockWorkItem(priority: .blocker)

        // When
        await sut.enqueueItem(lowPriorityItem)
        await sut.enqueueItem(mediumPriorityItem)
        await sut.enqueueItem(highPriorityItem)
        await sut.enqueueItem(blockerPriorityItem)

        // Then
        try await #require(sut.dequeueNextItem()?.id == blockerPriorityItem.id)
        try await #require(sut.dequeueNextItem()?.id == highPriorityItem.id)
        try await #require(sut.dequeueNextItem()?.id == mediumPriorityItem.id)
        try await #require(sut.dequeueNextItem()?.id == lowPriorityItem.id)
        #expect(await sut.dequeueNextItem() == nil)
    }

    @Test("It dequeues tickets of same priority in FIFO order")
    func itDequeuesTicketsOfSamePriorityInFIFOOrder() async throws {
        // Given
        let item1 = MockWorkItem(priority: .low)
        let item2 = MockWorkItem(priority: .high)
        let item3 = MockWorkItem(priority: .medium)
        let item4 = MockWorkItem(priority: .low)
        let item5 = MockWorkItem(priority: .medium)
        let item6 = MockWorkItem(priority: .blocker)
        let item7 = MockWorkItem(priority: .high)
        let item8 = MockWorkItem(priority: .blocker)

        // When
        await sut.enqueueItem(item1)
        await sut.enqueueItem(item2)
        await sut.enqueueItem(item3)
        await sut.enqueueItem(item4)
        await sut.enqueueItem(item5)
        await sut.enqueueItem(item6)
        await sut.enqueueItem(item7)
        await sut.enqueueItem(item8)

        // Then
        try await #require(sut.dequeueNextItem()?.id == item6.id)
        try await #require(sut.dequeueNextItem()?.id == item8.id)
        try await #require(sut.dequeueNextItem()?.id == item2.id)
        try await #require(sut.dequeueNextItem()?.id == item7.id)
        try await #require(sut.dequeueNextItem()?.id == item3.id)
        try await #require(sut.dequeueNextItem()?.id == item5.id)
        try await #require(sut.dequeueNextItem()?.id == item1.id)
        try await #require(sut.dequeueNextItem()?.id == item4.id)
        #expect(await sut.dequeueNextItem() == nil)
    }

    @Test("Dequeuing considers newly enqueued tickets")
    func dequeuingConsidersNewlyEnqueuedTickets() async throws {
        // Given
        let medium1 = MockWorkItem(priority: .medium)
        let high1 = MockWorkItem(priority: .high)
        let low1 = MockWorkItem(priority: .low)
        let low2 = MockWorkItem(priority: .low)
        let blocker1 = MockWorkItem(priority: .blocker)

        // When
        await sut.enqueueItem(medium1)
        await sut.enqueueItem(high1)

        // Then
        try await #require(sut.dequeueNextItem()?.id == high1.id)

        // When
        await sut.enqueueItem(low1)

        // Then
        try await #require(sut.dequeueNextItem()?.id == medium1.id)

        // When
        await sut.enqueueItem(low2)

        // Then
        try await #require(sut.dequeueNextItem()?.id == low1.id)

        // When
        await sut.enqueueItem(blocker1)

        // Then
        try await #require(sut.dequeueNextItem()?.id == blocker1.id)
        try await #require(sut.dequeueNextItem()?.id == low2.id)
        #expect(await sut.dequeueNextItem() == nil)
    }

}

private struct MockWorkItem: WorkItem, Equatable {

    let id = UUID()
    let priority: WorkItemPriority
    func start() async throws {}
    func cancel() async {}

}
