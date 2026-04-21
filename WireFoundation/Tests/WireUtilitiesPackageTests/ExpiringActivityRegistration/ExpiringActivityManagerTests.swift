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

@testable import WireUtilitiesPackage
@testable import WireUtilitiesPackageSupport

struct ExpiringActivityManagerTests {

    let performerMock = ExpiringActivityPerformerProtocolMock()

    @Test
    func testTaskIsCancelledWhenExpiring() async {
        // Given
        performerMock
            .performExpiringActivityReasonStringUsingBlockSendableEscapingIsExpiringBoolVoidVoidClosure = { _, block in
                block(true)
            }
        let manager = ExpiringActivityManagerV2(performer: performerMock)
        let task = Task<Void, Never> {
            try? await Task.sleep(for: .seconds(60))
        }

        // When
        await manager.track(reason: "sync", task: task)
        _ = await task.result

        // Then
        #expect(task.isCancelled)
    }

    @Test
    func testBlockWaitsForTaskToFinishWhenNotExpiring() async throws {
        // Given
        let (stream, continuation) = AsyncStream<Void>.makeStream()
        let flag = Flag()

        let task = Task<Void, Never> {
            for await _ in stream {}
        }

        performerMock
            .performExpiringActivityReasonStringUsingBlockSendableEscapingIsExpiringBoolVoidVoidClosure = { _, block in
                DispatchQueue.global().async {
                    block(false)
                    Task { await flag.set() }
                }
            }
        let manager = ExpiringActivityManagerV2(performer: performerMock)

        // When
        await manager.track(reason: "sync", task: task)

        // Then — the block should still be waiting because the task hasn't finished.
        try await Task.sleep(for: .milliseconds(200))
        var didReturn = await flag.value
        #expect(!didReturn)

        // Allow the task to complete.
        continuation.finish()

        // The block should return shortly after.
        try await Task.sleep(for: .milliseconds(200))
        didReturn = await flag.value
        #expect(didReturn)
    }

    @Test
    func testBlockUnblocksWhenSystemRevokesTime() async throws {
        // Given
        let (stream, _) = AsyncStream<Void>.makeStream()
        let flag = Flag()
        var capturedBlock: (@Sendable (Bool) -> Void)?

        let task = Task<Void, Never> {
            for await _ in stream {}
        }

        performerMock
            .performExpiringActivityReasonStringUsingBlockSendableEscapingIsExpiringBoolVoidVoidClosure = { _, block in
                capturedBlock = block
                DispatchQueue.global().async {
                    block(false)
                    Task { await flag.set() }
                }
            }
        let manager = ExpiringActivityManagerV2(performer: performerMock)

        // When — register the activity, which grants time and blocks.
        await manager.track(reason: "sync", task: task)

        // The block should still be waiting because the task hasn't finished.
        try await Task.sleep(for: .milliseconds(200))
        var didReturn = await flag.value
        #expect(!didReturn)

        // Simulate the system revoking background time.
        capturedBlock?(true)

        // Then — the block should unblock and the task should be cancelled.
        try await Task.sleep(for: .milliseconds(200))
        didReturn = await flag.value
        #expect(didReturn)
        #expect(task.isCancelled)
    }

    @Test
    func testBlockReturnsEvenWhenTaskThrows() async throws {
        // Given
        struct TestError: Error {}
        let flag = Flag()

        let task = Task<Void, any Error> {
            throw TestError()
        }

        performerMock
            .performExpiringActivityReasonStringUsingBlockSendableEscapingIsExpiringBoolVoidVoidClosure = { _, block in
                DispatchQueue.global().async {
                    block(false)
                    Task { await flag.set() }
                }
            }
        let manager = ExpiringActivityManagerV2(performer: performerMock)

        // When
        await manager.track(reason: "sync", task: task)

        // Then — block should return despite the task throwing.
        try await Task.sleep(for: .milliseconds(200))
        let didReturn = await flag.value
        #expect(didReturn)
    }

    @Test
    func testMultipleTasksBlockOnlyOneThread() async throws {
        // Given
        let (stream1, continuation1) = AsyncStream<Void>.makeStream()
        let (stream2, continuation2) = AsyncStream<Void>.makeStream()
        let flag = Flag()
        var performCallCount = 0

        let task1 = Task<Void, Never> { for await _ in stream1 {} }
        let task2 = Task<Void, Never> { for await _ in stream2 {} }

        performerMock
            .performExpiringActivityReasonStringUsingBlockSendableEscapingIsExpiringBoolVoidVoidClosure = { _, block in
                performCallCount += 1
                DispatchQueue.global().async {
                    block(false)
                    Task { await flag.set() }
                }
            }
        let manager = ExpiringActivityManagerV2(performer: performerMock)

        // When — track two tasks.
        await manager.track(reason: "sync", task: task1)
        await manager.track(reason: "sync", task: task2)

        // Then — only one expiring activity should have been registered.
        #expect(performCallCount == 1)

        // The block should still be waiting because both tasks are running.
        try await Task.sleep(for: .milliseconds(200))
        var didReturn = await flag.value
        #expect(!didReturn)

        // Finish the first task — block should still wait for the second.
        continuation1.finish()
        try await Task.sleep(for: .milliseconds(200))
        didReturn = await flag.value
        #expect(!didReturn)

        // Finish the second task — now the block should return.
        continuation2.finish()
        try await Task.sleep(for: .milliseconds(200))
        didReturn = await flag.value
        #expect(didReturn)
    }

    @Test
    func testSystemExpirationCancelsAllTrackedTasks() async throws {
        // Given
        let (stream1, _) = AsyncStream<Void>.makeStream()
        let (stream2, _) = AsyncStream<Void>.makeStream()
        var capturedBlock: (@Sendable (Bool) -> Void)?

        let task1 = Task<Void, Never> { for await _ in stream1 {} }
        let task2 = Task<Void, Never> { for await _ in stream2 {} }

        performerMock
            .performExpiringActivityReasonStringUsingBlockSendableEscapingIsExpiringBoolVoidVoidClosure = { _, block in
                capturedBlock = block
                DispatchQueue.global().async {
                    block(false)
                }
            }
        let manager = ExpiringActivityManagerV2(performer: performerMock)

        // When
        await manager.track(reason: "sync", task: task1)
        await manager.track(reason: "sync", task: task2)

        try await Task.sleep(for: .milliseconds(200))
        capturedBlock?(true)

        // Then — both tasks should be cancelled.
        try await Task.sleep(for: .milliseconds(200))
        #expect(task1.isCancelled)
        #expect(task2.isCancelled)
    }

    @Test
    func testCancellingOuterTaskCancelsBlock() async throws {
        // Given
        let blockStarted = Flag()
        let blockCancelled = Flag()

        performerMock
            .performExpiringActivityReasonStringUsingBlockSendableEscapingIsExpiringBoolVoidVoidClosure = { _, block in
                DispatchQueue.global().async {
                    block(false)
                }
            }
        let manager = ExpiringActivityManagerV2(performer: performerMock)

        let outerTask = Task {
            await withExpiringActivity(manager: manager, reason: "sync") {
                await blockStarted.set()
                while !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(10))
                }
                await blockCancelled.set()
            }
        }

        // Wait for the block to start running.
        while !(await blockStarted.value) {
            try await Task.sleep(for: .milliseconds(10))
        }

        // When
        outerTask.cancel()

        // Then — the block should see cancellation.
        try await Task.sleep(for: .milliseconds(200))
        let wasCancelled = await blockCancelled.value
        #expect(wasCancelled)
    }

}

// MARK: -

private actor Flag {
    var value = false
    func set() { value = true }
}
