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
    private var pushChannel: MockPushChannelProtocol!
    private var updateEventsRepository: MockUpdateEventsRepositoryProtocol!
    private var updateEventDecryptor: MockUpdateEventDecryptorProtocol!
    private var updateEventProcessor: MockUpdateEventProcessorProtocol!

    private var pushChannelSubject: PassthroughSubject<UpdateEventEnvelope, Never>!

    override func setUp() async throws {
        try await super.setUp()
        pushChannel = MockPushChannelProtocol()
        updateEventsRepository = MockUpdateEventsRepositoryProtocol()
        updateEventDecryptor = MockUpdateEventDecryptorProtocol()
        updateEventProcessor = MockUpdateEventProcessorProtocol()
        sut = SyncManager(
            pushChannel: pushChannel,
            updateEventsRepository: updateEventsRepository,
            updateEventDecryptor: updateEventDecryptor,
            updateEventProcessor: updateEventProcessor
        )
        
        // Send `Data` through the subject to simulate push channel events.
        pushChannelSubject = PassthroughSubject()
        pushChannel.open_MockValue = pushChannelSubject.eraseToAnyPublisher()
        pushChannel.close_MockMethod = { }

        // Base mocks.
        updateEventsRepository.pullPendingEvents_MockMethod = {}
        updateEventsRepository.fetchNextPendingEventsLimit_MockValue = []
        updateEventsRepository.deleteNextPendingEventsLimit_MockMethod = { _ in }

        updateEventDecryptor.decryptEventsIn_MockMethod = { envelope in
            envelope.events
        }
    }

    override func tearDown() async throws {
        sut = nil
        pushChannel = nil
        updateEventsRepository = nil
        updateEventDecryptor = nil
        updateEventProcessor = nil
        pushChannelSubject = nil
        try await super.tearDown()
    }

    // MARK: - Tests

    func testItStartsSuspended() async throws {
        // Given we just initialized the sync manager.

        // Then it's suspended.
        XCTAssertEqual(sut.syncState, .suspended)

        // Then the push channel is closed.
        XCTAssertTrue(pushChannel.open_Invocations.isEmpty)
    }

    // MARK: - Suspension

    func testItSuspendsWhenLive() async throws {
        // Given it goes live.
        try await sut.performQuickSync()
        XCTAssertEqual(sut.syncState, .live)

        // When it suspends.
        try await sut.suspend()

        // Then the push channel was closed.
        XCTAssertEqual(pushChannel.close_Invocations.count, 1)

        // Then it goes to the suspended state.
        XCTAssertEqual(sut.syncState, .suspended)
    }

    func testItSuspendsWhenQuickSyncing() async throws {
        XCTFail("not implemented yet")
    }

    func testItSuspendsWhenSlowSyncing() async throws {
        XCTFail("not implemented yet")
    }

    // MARK: - Slow sync

    func testItSlowSyncs() async throws {
        // performs slow sync
        // performs quick sync
        // goes live
        XCTFail("not implemented yet")
    }

    func testItOnlyPerformsASingleSlowSync() async throws {
        // start slow sync
        // start again
        // they don't overlap
        XCTFail("not implemented yet")
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
        let didPushLiveEvents = XCTestExpectation()

        updateEventProcessor.processEvent_MockMethod = { event in
            if event == Scaffolding.event2 {
                // Stop processing, wait for live events.
                await self.fulfillment(of: [didPushLiveEvents])
            }

            didProcessEvent.fulfill()
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
        pushChannelSubject.send(liveEnvelope1)

        let liveEnvelope2 = Scaffolding.makeEnvelope(with: Scaffolding.event5)
        pushChannelSubject.send(liveEnvelope2)
        didPushLiveEvents.fulfill()

        // Wait for "when" to finish.
        try await whenTask.value

        // Then the push channel is open.
        XCTAssertEqual(pushChannel.open_Invocations.count, 1)
        XCTAssertEqual(pushChannel.close_Invocations.count, 0)

        // Then it pulls pending events.
        XCTAssertEqual(updateEventsRepository.pullPendingEvents_Invocations.count, 1)

        // Then it tries to fetch 2 event batches (1st is non-empty, 2nd is empty).
        XCTAssertEqual(updateEventsRepository.fetchNextPendingEventsLimit_Invocations, [500, 500])

        // Then it decrypted the 2 bufferend events.
        let decryptionInvocations = updateEventDecryptor.decryptEventsIn_Invocations

        guard decryptionInvocations.count == 2 else {
            XCTFail("expected 2 events to be decrypted, got \(decryptionInvocations.count)")
            return
        }

        XCTAssertEqual(decryptionInvocations[0], liveEnvelope1)
        XCTAssertEqual(decryptionInvocations[1], liveEnvelope2)

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

        // Then there are no buffered envelopes.
        XCTAssertEqual(sut.bufferedEnvelopes.count, 0)

        // Then it is live.
        XCTAssertEqual(sut.syncState, .live)
    }

    func testItOnlyPerformsASingleQuickSync() async throws {
        // start quick sync
        // start again
        // they don't overlap
        XCTFail("not implemented yet")
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
