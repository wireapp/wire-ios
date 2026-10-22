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
import Testing
@testable import WireDomain

struct WorkAgentTests {

    private let scheduler: MockScheduler
    private let sut: WorkAgent

    init() async {
        self.scheduler = MockScheduler()
        self.sut = WorkAgent(scheduler: scheduler)
        await sut.setAutoStartEnabled(false)
    }

    @Test("Submitted items are performed")
    func submittedItemsArePerformed() async throws {
        // Given
        let item1 = MockWorkItem(priority: .medium)
        let item2 = MockWorkItem(priority: .medium)
        let item3 = MockWorkItem(priority: .medium)

        // When
        await sut.submitItem(item1)
        await sut.submitItem(item2)
        await sut.submitItem(item3)
        await sut.start()

        // Then
        #expect(await sut.isRunning == false)

        // All items were enqueued and dequeued.
        let allItemIDs = [item1, item2, item3].map(\.id)
        #expect(await scheduler.enqueuedItems.map(\.id) == allItemIDs)
        #expect(await scheduler.dequeuedItems.map(\.id) == allItemIDs)

        // All tickets were performed by the correct worker.
        #expect(await item1.didStart)
        #expect(await item2.didStart)
        #expect(await item3.didStart)
    }

    @Test("Submitted items are performed only once")
    func submittedItemsArePerformedOnlyOnce() async throws {
        // Given
        let item = MockWorkItem(priority: .medium)

        // When
        await sut.submitItem(item)
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
        #expect(await sut.isRunning == false)

        // The ticket was enqueued, dequeued, and performed only once.
        #expect(await scheduler.enqueuedItems.map(\.id) == [item.id])
        #expect(await scheduler.dequeuedItems.map(\.id) == [item.id])
        #expect(await item.startCalls == 1)
    }

    @Test("Clear items are removed")
    func clearItems() async throws {
        // Given
        let item = MockWorkItem(priority: .medium)
        await sut.submitItem(item)
        await Task.yield()

        #expect(await scheduler.enqueuedItems.count == 1)

        // When
        await sut.clearSchedulerQueue()

        // Then
        #expect(await scheduler.items.isEmpty)
        #expect(await scheduler.enqueuedItems.isEmpty)
    }

    @Test("Stopping waits for the active work item")
    func stoppingWaitsForActiveWork() async {
        let (started, startedContinuation) = AsyncStream<Void>.makeStream()
        let (cancelled, cancelledContinuation) = AsyncStream<Void>.makeStream()
        let item = BlockingWorkItem(
            started: startedContinuation,
            cancelled: cancelledContinuation
        )
        let queuedItem = MockWorkItem(priority: .medium)
        await scheduler.enqueueItem(item)
        await scheduler.enqueueItem(queuedItem)

        let running = Task { await sut.start() }
        var startedIterator = started.makeAsyncIterator()
        _ = await startedIterator.next()

        let stopping = Task { await sut.stopAndWait() }
        var cancelledIterator = cancelled.makeAsyncIterator()
        _ = await cancelledIterator.next()
        #expect(await sut.isRunning)

        await item.releaseWork()
        await stopping.value
        await running.value
        #expect(await sut.isRunning == false)
        #expect(await queuedItem.didStart == false)

        let submittedAfterShutdown = MockWorkItem(priority: .medium)
        await sut.submitItem(submittedAfterShutdown)
        await sut.start()
        #expect(await submittedAfterShutdown.didStart == false)
    }

}

private actor BlockingWorkItem: WorkItem {

    let id = UUID().uuidString
    let priority: WorkItemPriority = .medium
    let started: AsyncStream<Void>.Continuation
    let cancelled: AsyncStream<Void>.Continuation
    private var releaseContinuation: CheckedContinuation<Void, Never>?

    init(
        started: AsyncStream<Void>.Continuation,
        cancelled: AsyncStream<Void>.Continuation
    ) {
        self.started = started
        self.cancelled = cancelled
    }

    func start() async throws {
        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                releaseContinuation = continuation
                started.yield(())
            }
        } onCancel: {
            cancelled.yield(())
        }
    }

    func releaseWork() {
        releaseContinuation?.resume()
        releaseContinuation = nil
    }

    func cancel() {}
}

private actor MockWorkItem: WorkItem {

    let id = UUID().uuidString
    let priority: WorkItemPriority

    var startCalls = 0
    var didStart: Bool {
        startCalls > 0
    }

    var cancelCalls = 0
    var didCancel: Bool {
        cancelCalls > 0
    }

    init(priority: WorkItemPriority) {
        self.priority = priority
    }

    func start() async throws {
        startCalls += 1
    }

    func cancel() {
        cancelCalls += 1
    }

}

private actor MockScheduler: WorkItemScheduler {

    var items: [any WorkItem] = []
    var enqueuedItems: [any WorkItem] = []
    var dequeuedItems: [any WorkItem] = []

    func enqueueItem(_ item: any WorkItem) {
        enqueuedItems.append(item)
        items.append(item)
    }

    func dequeueNextItem() -> (any WorkItem)? {
        guard !items.isEmpty else { return nil }
        let item = items.removeFirst()
        dequeuedItems.append(item)
        return item
    }

    func clearAllItems() async {
        enqueuedItems.removeAll()
        items.removeAll()
    }
}
