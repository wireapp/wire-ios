//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

import Combine
import WireAPI
import WireAPISupport
import XCTest

@testable import WireDomain
@testable import WireDomainSupport

final class SyncManagerTests: XCTestCase {

    private var sut: SyncManager!
    private var updateEventsRepository: MockUpdateEventsRepositoryProtocol!
    private var updateEventProcessor: MockUpdateEventProcessorProtocol!

    override func setUp() async throws {
        try await super.setUp()
        updateEventsRepository = MockUpdateEventsRepositoryProtocol()
        updateEventProcessor = MockUpdateEventProcessorProtocol()
        sut = SyncManager(
            updateEventsRepository: updateEventsRepository,
            updateEventProcessor: updateEventProcessor
        )

        // Base mocks.
        updateEventsRepository.startBufferingLiveEvents_MockValue = AsyncStream { _ in }
        updateEventsRepository.stopReceivingLiveEvents_MockMethod = { }
        updateEventsRepository.pullPendingEvents_MockMethod = {}
        updateEventsRepository.fetchNextPendingEventsLimit_MockValue = []
        updateEventsRepository.deleteNextPendingEventsLimit_MockMethod = { _ in }
        updateEventProcessor.processEvent_MockMethod = { _ in }
    }

    override func tearDown() async throws {
        sut = nil
        updateEventsRepository = nil
        updateEventProcessor = nil
        try await super.tearDown()
    }

    // MARK: - Tests

    func testItStartsSuspended() async throws {
        // Given we just initialized the sync manager.

        // Then it's suspended.
        guard case .suspended = sut.syncState else {
            XCTFail("unexpected sync state: \(sut.syncState)")
            return
        }

        // Then is has not requested any live events.
        XCTAssertTrue(updateEventsRepository.startBufferingLiveEvents_Invocations.isEmpty)
    }

    // MARK: - Suspension

    func testItDoesNotSuspendIfItIsAlreadySuspended() async throws {
        // Given it's already suspended.
        guard case .suspended = sut.syncState else {
            XCTFail("unexpected sync state: \(sut.syncState)")
            return
        }

        // When
        try await sut.suspend()

        // Then it didn't do anything.
        XCTAssertTrue(updateEventsRepository.stopReceivingLiveEvents_Invocations.isEmpty)
    }

    func testItSuspendsWhenLive() async throws {
        // Given it goes live.
        try await sut.performQuickSync()

        guard case .live = sut.syncState else {
            XCTFail("unexpected sync state: \(sut.syncState)")
            return
        }

        // When it suspends.
        try await sut.suspend()

        // Then the push channel was closed.
        XCTAssertEqual(updateEventsRepository.stopReceivingLiveEvents_Invocations.count, 1)

        // Then it goes to the suspended state.
        guard case .suspended = sut.syncState else {
            XCTFail("unexpected sync state: \(sut.syncState)")
            return
        }
    }

    // This test asserts that if we suspend the SyncManager while there
    // is an ongoing quick sync, then the quick sync is cancelled and
    // it transitions to the `suspend` state.
    //
    // The sequence of events is:
    //
    // 1. Test creates Task to perform quick sync.
    // 2. Test lets the Task begin, waits for it to pull pending events.
    // 3. Meanwhile, Task continues to fetch next pending events, waits until
    //    Test starts suspension.
    // 4. Test suspends sut, then waits for the Task to throw a CancellationError.
    // 5. Meanwhile, Task continues after the suspension, then will throw a
    //    CancellationError when it processes the next batch of events.

    func testItSuspendsWhenQuickSyncing() async throws {
        let didPullEvents = XCTestExpectation()
        let didSuspend = XCTestExpectation()
        
        updateEventsRepository.pullPendingEvents_MockMethod = {
            didPullEvents.fulfill()
        }

        updateEventsRepository.fetchNextPendingEventsLimit_MockMethod = { _ in
            // Wait here until we suspend.
            await self.fulfillment(of: [didSuspend])
            return [Scaffolding.makeEnvelope(with: Scaffolding.event1)]
        }

        let ongoingQuickSync = Task {
            // Given we are quick syncing.
            try await sut.performQuickSync()
        }

        // Let quick sync run, wait until it pulls events.
        await fulfillment(of: [didPullEvents])

        // When it suspends.
        try await sut.suspend()
        didSuspend.fulfill()

        do {
            // Wait for the quick sync to finish.
            try await ongoingQuickSync.value
            XCTFail("expected the quick sync to cancel but it did not")
            return
        } catch is CancellationError {
            // Then the quick sync was cancelled.
        } catch {
            XCTFail("expected a cancellation error but got: \(error)")
            return
        }

        // Then the push channel was closed.
        XCTAssertEqual(updateEventsRepository.stopReceivingLiveEvents_Invocations.count, 1)

        // Then it goes to the suspended state.
        guard case .suspended = sut.syncState else {
            XCTFail("unexpected sync state: \(sut.syncState)")
            return
        }
    }

    // MARK: - Quick sync

    // This test is important because it asserts how we coordinate multiple sources of
    // events:
    //
    // - pending events from the backend (remove event queue), which are stored locally
    // - live events arriving in an active push channel
    //
    // In particular, we want to assert that we process all events in order, even if
    // we receive live events during the processing of previous stored events.
    //
    // In order to simulate this we need to deterministically push mock live events
    // through the push channel at the right time, which I've arbitrarily chosen to
    // be after processing event 1 and before processing event 2.
    //
    // Key checkpoints in the test are:
    //
    // 1. Start performing quick sync (start of "when").
    // 2. Pull 3 pending events from remote event queue.
    // 3. Fetch the next batck of stored events (the 3 just pulled).
    // 4. Process the 1st event.
    // 5. Push 2 live events through push channel (from outside of "when"), these get bufferend.
    // 6. Process the 2nd and 3rd events (back inside of "when").
    // 7. Delete first batch of events.
    // 8. Fetch next batch of events, get back none (all have been processed).
    // 9. Decrypt and process buffered events (live events received in step 5.)

    func testItQuickSyncs() async throws {
        // Given no stored events.
        var storedEvents = [UpdateEventEnvelope]()

        // Mock live event stream.
        var liveEventsContinuation: AsyncStream<UpdateEventEnvelope>.Continuation?
        updateEventsRepository.startBufferingLiveEvents_MockValue = AsyncStream { continuation in
            liveEventsContinuation = continuation
        }

        // Mock pull events from remote, store locally.
        updateEventsRepository.pullPendingEvents_MockMethod = {
            storedEvents = [
                Scaffolding.makeEnvelope(with: Scaffolding.event1),
                Scaffolding.makeEnvelope(with: Scaffolding.event2),
                Scaffolding.makeEnvelope(with: Scaffolding.event3)
            ]
        }

        // Mock fetch the next batch.
        updateEventsRepository.fetchNextPendingEventsLimit_MockMethod = { limit in
            Array(storedEvents.prefix(Int(limit)))
        }

        // Mock delete the next batch.
        updateEventsRepository.deleteNextPendingEventsLimit_MockMethod = { limit in
            storedEvents = Array(storedEvents.dropFirst(Int(limit)))
        }

        let didProcessEvent = XCTestExpectation()
        let didProcessEvent5 = XCTestExpectation()
        let didPushLiveEvents = XCTestExpectation()

        updateEventProcessor.processEvent_MockMethod = { event in
            switch event {
            case Scaffolding.event1:
                didProcessEvent.fulfill()

            case Scaffolding.event2:
                // Stop processing, wait for live events.
                await self.fulfillment(of: [didPushLiveEvents])

            case Scaffolding.event5:
                didProcessEvent5.fulfill()

            default:
                break
            }
        }

        // Run in another task so we can send events through the push channel.
        let whenTask = Task.detached {
            // When
            try await self.sut.performQuickSync()
        }

        // Let the "when" task begin.
        await Task.yield()

        // Wait for event 1 to be processed.
        await fulfillment(of: [didProcessEvent])

        // Push 2 live events through push channel
        let liveEnvelope1 = Scaffolding.makeEnvelope(with: Scaffolding.event4)
        liveEventsContinuation?.yield(liveEnvelope1)

        let liveEnvelope2 = Scaffolding.makeEnvelope(with: Scaffolding.event5)
        liveEventsContinuation?.yield(liveEnvelope2)
        didPushLiveEvents.fulfill()

        // Wait for "when" to finish.
        try await whenTask.value

        // We also need to wait to get the two live events...
        await fulfillment(of: [didProcessEvent5])

        // Then it requested live events.
        XCTAssertEqual(updateEventsRepository.startBufferingLiveEvents_Invocations.count, 1)

        // Then it pulls pending events.
        XCTAssertEqual(updateEventsRepository.pullPendingEvents_Invocations.count, 1)

        // Then it tries to fetch 2 event batches (1st is non-empty, 2nd is empty).
        XCTAssertEqual(updateEventsRepository.fetchNextPendingEventsLimit_Invocations, [500, 500])

        // Then it processed 5 events, in the correct order.
        let processEventInvocations = updateEventProcessor.processEvent_Invocations
        
        guard processEventInvocations.count == 5 else {
            XCTFail("expected 5 events to be processed, got \(processEventInvocations.count)")
            return
        }
        
        // These were the stored events.
        XCTAssertEqual(processEventInvocations[0], Scaffolding.event1)
        XCTAssertEqual(processEventInvocations[1], Scaffolding.event2)
        XCTAssertEqual(processEventInvocations[2], Scaffolding.event3)

        // These were the buffered events.
        XCTAssertEqual(processEventInvocations[3], Scaffolding.event4)
        XCTAssertEqual(processEventInvocations[4], Scaffolding.event5)

        // Then it deleted 1 batch (i.e all) of the stored events.
        XCTAssertEqual(updateEventsRepository.deleteNextPendingEventsLimit_Invocations, [500])
        XCTAssertTrue(storedEvents.isEmpty)

        // Then it is live.
        guard case .live = sut.syncState else {
            XCTFail("unexpected sync state: \(sut.syncState)")
            return
        }

        XCTAssertEqual(updateEventsRepository.stopReceivingLiveEvents_Invocations.count, 0)
    }

}

private enum Scaffolding {

    static let localDomain = "example.com"
    static let conversationID1 = ConversationID(uuid: UUID(), domain: localDomain)
    static let conversationID2 = ConversationID(uuid: UUID(), domain: localDomain)
    static let aliceID = UserID(uuid: UUID(), domain: localDomain)

    static let event1 = UpdateEvent.user(.clientAdd(UserClientAddEvent(client:UserClient(
        id: "userClientID",
        type: .permanent,
        activationDate: .now,
        capabilities: [.legalholdConsent]
    ))))

    static let event2 = UpdateEvent.conversation(.typing(ConversationTypingEvent(
        conversationID: conversationID1,
        senderID: aliceID,
        isTyping: true
    )))

    static let event3 = UpdateEvent.conversation(.delete(ConversationDeleteEvent(
        conversationID: conversationID1,
        senderID: aliceID,
        timestamp: .now
    )))

    static let event4 = UpdateEvent.conversation(.rename(ConversationRenameEvent(
        conversationID: conversationID2,
        senderID: aliceID,
        timestamp: .now,
        newName: "Foo"
    )))

    static let event5 = UpdateEvent.conversation(.rename(ConversationRenameEvent(
        conversationID: conversationID2,
        senderID: aliceID,
        timestamp: .now,
        newName: "Bar"
    )))

    static func makeEnvelope(with event: UpdateEvent) -> UpdateEventEnvelope {
        .init(
            id: UUID(),
            events: [event],
            isTransient: false
        )
    }

}
