//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

import XCTest
@testable import WireSyncEngine
@testable import WireDataModelSupport

class EventProcessorTests: MessagingTest {

    struct MockError: Error { }

    var sut: EventProcessor!
    var eventProcessingTracker: EventProcessingTracker!
    var mockEventsConsumers: [MockEventConsumer]!
    var mockEventAsyncConsumers: [MockEventAsyncConsumer]!
    var earService: MockEARServiceInterface!

    override func setUp() {
        super.setUp()

        syncMOC.performAndWait {
            _ = createSelfClient()
        }

        mockEventsConsumers = [MockEventConsumer(), MockEventConsumer()]
        mockEventAsyncConsumers = [MockEventAsyncConsumer(), MockEventAsyncConsumer()]

        eventProcessingTracker = EventProcessingTracker()

        earService = MockEARServiceInterface()
        earService.fetchPublicKeys_MockError = MockError()
        earService.fetchPrivateKeysIncludingPrimary_MockError = MockError()

        sut = EventProcessor(
            storeProvider: coreDataStack,
            eventProcessingTracker: eventProcessingTracker,
            earService: earService,
            eventConsumers: mockEventsConsumers,
            eventAsyncConsumers: mockEventAsyncConsumers
        )
    }

    override func tearDown() {
        mockEventsConsumers = nil
        mockEventAsyncConsumers = nil
        eventProcessingTracker = nil
        earService = nil
        sut = nil

        super.tearDown()
    }

    // MARK: - Helpers

    func createSampleEvents(conversationID: UUID  = UUID(), messageNonce: UUID = UUID()) -> [ZMUpdateEvent] {
        let payload1: [String: Any] = ["type": "conversation.member-join",
                                       "conversation": conversationID]
        let payload2: [String: Any] = ["type": "conversation.message-add",
                                       "data": ["content": "www.wire.com",
                                                "nonce": messageNonce],
                                       "conversation": conversationID]

        let event1 = ZMUpdateEvent(fromEventStreamPayload: payload1 as ZMTransportData, uuid: nil)!
        let event2 = ZMUpdateEvent(fromEventStreamPayload: payload2 as ZMTransportData, uuid: nil)!

        return [event1, event2]
    }

    // MARK: - Tests

    func testThatEventsAreForwardedToAllEventConsumers_WhenProcessed() async throws {
        // given
        let events = createSampleEvents()

        // when
        try await sut.processEvents(events)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        mockEventsConsumers.forEach({ mockEventConsumer in
            XCTAssertTrue(mockEventConsumer.processEventsWhileInBackgroundCalled)
            XCTAssertTrue(mockEventConsumer.processEventsCalled)
            XCTAssertEqual(events, mockEventConsumer.eventsProcessed)
        })

        mockEventAsyncConsumers.forEach({ mockEventConsumer in
            XCTAssertTrue(mockEventConsumer.processEventsCalled)
            XCTAssertEqual(events, mockEventConsumer.eventsProcessed)
        })
    }

    func testThatEventsAreNotForwardedToAllEventConsumers_WhenBuffered() async {
        // given
        let events = createSampleEvents()

        // when
        await sut.bufferEvents(events)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        mockEventsConsumers.forEach({ mockEventConsumer in
            XCTAssertFalse(mockEventConsumer.processEventsWhileInBackgroundCalled)
            XCTAssertFalse(mockEventConsumer.processEventsCalled)
        })

        mockEventAsyncConsumers.forEach({ mockEventConsumer in
            XCTAssertFalse(mockEventConsumer.processEventsCalled)
        })
    }

    func testThatEventsAreNotForwardedToAllEventConsumers_WhenDatabaseIsLocked() async throws {
        // given
        let earService = EARService(
            accountID: userIdentifier,
            databaseContexts: [uiMOC, syncMOC],
            sharedUserDefaults: UserDefaults.temporary()
        )
        earService.setInitialEARFlagValue(true)
        try syncMOC.performAndWait {
            try earService.enableEncryptionAtRest(
                context: syncMOC,
                skipMigration: true
            )
        }
        earService.lockDatabase()

        let events = createSampleEvents()

        // when
        await sut.bufferEvents(events)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        mockEventsConsumers.forEach({ mockEventConsumer in
            XCTAssertFalse(mockEventConsumer.processEventsWhileInBackgroundCalled)
            XCTAssertFalse(mockEventConsumer.processEventsCalled)
        })
    }

    func testThatEventsAreForwardedToAllEventConsumers_WhenBufferedEventsAreProcessed() async throws {
        // given
        let events = createSampleEvents()
        await sut.bufferEvents(events)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        try await sut.processBufferedEvents()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        mockEventsConsumers.forEach({ mockEventConsumer in
            XCTAssertTrue(mockEventConsumer.processEventsWhileInBackgroundCalled)
            XCTAssertTrue(mockEventConsumer.processEventsCalled)
            XCTAssertEqual(events, mockEventConsumer.eventsProcessed)
        })

        mockEventAsyncConsumers.forEach({ mockEventConsumer in
            XCTAssertTrue(mockEventConsumer.processEventsCalled)
            XCTAssertEqual(events, mockEventConsumer.eventsProcessed)
        })
    }

    func testThatItCreatesAFetchBatchRequestWithTheNoncesAndRemoteIdentifiers_RequestedByEventsConsumers() async {
        // given
        let converationID = UUID()
        let messageNonce = UUID()
        let events = createSampleEvents(conversationID: converationID, messageNonce: messageNonce)

        // when
        let batchFetchRequest = await sut.prefetchRequest(updateEvents: events)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let conversationIdSet: NSSet = [converationID]
        let messageNonceSet: NSSet = [messageNonce]
        XCTAssertEqual(batchFetchRequest.remoteIdentifiersToFetch, conversationIdSet)
        XCTAssertEqual(batchFetchRequest.noncesToFetch, messageNonceSet)
    }
}

class MockOperationStateProvider: OperationStateProvider {

    var operationState = SyncEngineOperationState.background

}
