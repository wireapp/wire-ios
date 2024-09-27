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

import WireDataModelSupport
import WireTesting
@testable import WireRequestStrategy

// MARK: - EventConversation

public enum EventConversation {
    static let add = "conversation.message-add"
    static let addClientMessage = "conversation.client-message-add"
    static let addOTRMessage = "conversation.otr-message-add"
    static let addAsset = "conversation.asset-add"
    static let addOTRAsset = "conversation.otr-asset-add"
}

// MARK: - EventDecoderTest

class EventDecoderTest: MessagingTestBase {
    var sut: EventDecoder!
    var mockMLSService = MockMLSServiceInterface()
    var lastEventIDRepository = MockLastEventIDRepositoryInterface()

    override func setUp() {
        super.setUp()
        sut = EventDecoder(eventMOC: eventMOC, syncMOC: syncMOC, lastEventIDRepository: lastEventIDRepository)

        lastEventIDRepository.storeLastEventID_MockMethod = { _ in }

        syncMOC.performGroupedAndWait {
            self.mockMLSService.commitPendingProposalsIfNeeded_MockMethod = {}
            self.syncMOC.mlsService = self.mockMLSService
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.remoteIdentifier = self.accountIdentifier
            let selfConversation = ZMConversation.insertNewObject(in: self.syncMOC)
            selfConversation.remoteIdentifier = self.accountIdentifier
            selfConversation.conversationType = .self
        }
    }

    override func tearDown() {
        EventDecoder.testingBatchSize = nil
        sut = nil
        super.tearDown()
    }
}

// MARK: - Processing events

extension EventDecoderTest {
    func testThatItProcessesEvents() async throws {
        // given
        var didCallBlock = false
        let event = await syncMOC.perform {
            self.eventStreamEvent()
        }

        _ = try await sut.decryptAndStoreEvents([event])

        // when
        await sut.processStoredEvents { events in
            XCTAssertTrue(events.contains(event))
            didCallBlock = true
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(didCallBlock)
    }

    func testThatItProcessesEventsWithPrivateKeys() async throws {
        var didCallBlock = false
        let accountID = UUID.create()
        let keyGenerator = EARKeyGenerator()
        let primaryKeys = try keyGenerator
            .generatePrimaryPublicPrivateKeyPair(id: "event-decoder-tests.\(accountID).primary")
        let secondaryKeys = try keyGenerator
            .generateSecondaryPublicPrivateKeyPair(id: "event-decoder-tests.\(accountID).secondary")

        let publicKeys = EARPublicKeys(
            primary: primaryKeys.publicKey,
            secondary: primaryKeys.privateKey
        )

        let privateKeys = EARPrivateKeys(
            primary: primaryKeys.privateKey,
            secondary: secondaryKeys.privateKey
        )

        // given
        let event = await syncMOC.perform {
            self.eventStreamEvent()
        }

        _ = try await sut.decryptAndStoreEvents(
            [event],
            publicKeys: publicKeys
        )

        // when
        await sut.processStoredEvents(with: privateKeys) { events in
            XCTAssertTrue(events.contains(event))
            didCallBlock = true
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(didCallBlock)
    }

    func testThatItProcessesPreviouslyStoredEventsFirst() async throws {
        EventDecoder.testingBatchSize = 1
        var callCount = 0

        // given
        let event1 = await syncMOC.perform {
            self.eventStreamEvent()
        }
        let event2 = await syncMOC.perform {
            self.eventStreamEvent()
        }

        _ = try await sut.decryptAndStoreEvents([event1])

        // when
        _ = try await sut.decryptAndStoreEvents([event2])
        await sut.processStoredEvents { events in
            if callCount == 0 {
                XCTAssertTrue(events.contains(event1))
            } else if callCount == 1 {
                XCTAssertTrue(events.contains(event2))
            } else {
                XCTFail("called too often")
            }
            callCount += 1
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(callCount, 2)
    }

    func testThatItProcessesInBatches() async throws {
        EventDecoder.testingBatchSize = 2
        var callCount = 0

        // given
        let event1 = await syncMOC.perform {
            self.eventStreamEvent()
        }
        let event2 = await syncMOC.perform {
            self.eventStreamEvent()
        }
        let event3 = await syncMOC.perform {
            self.eventStreamEvent()
        }
        let event4 = await syncMOC.perform {
            self.eventStreamEvent()
        }

        _ = try await sut.decryptAndStoreEvents([event1, event2, event3, event4])

        // when
        await sut.processStoredEvents { events in
            if callCount == 0 {
                XCTAssertTrue(events.contains(event1))
                XCTAssertTrue(events.contains(event2))
            } else if callCount == 1 {
                XCTAssertTrue(events.contains(event3))
                XCTAssertTrue(events.contains(event4))
            } else {
                XCTFail("called too often")
            }
            callCount += 1
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(callCount, 2)
    }

    func testThatItDoesNotProcessTheSameEventsTwiceWhenCalledSuccessively() async throws {
        EventDecoder.testingBatchSize = 2

        // given
        let event1 = await syncMOC.perform {
            self.eventStreamEvent()
        }
        let event2 = await syncMOC.perform {
            self.eventStreamEvent()
        }
        let event3 = await syncMOC.perform {
            self.eventStreamEvent()
        }
        let event4 = await syncMOC.perform {
            self.eventStreamEvent()
        }

        _ = try await sut.decryptAndStoreEvents([event1, event2])

        await sut.processStoredEvents(with: nil) { events in
            XCTAssert(events.contains(event1))
            XCTAssert(events.contains(event2))
        }

        insert([event3, event4], startIndex: 1)

        // when
        await sut.processStoredEvents(with: nil) { events in
            XCTAssertFalse(events.contains(event1))
            XCTAssertFalse(events.contains(event2))
            XCTAssertTrue(events.contains(event3))
            XCTAssertTrue(events.contains(event4))
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatItDoesNotProcessEventsFromOtherUsersArrivingInSelfConversation() async {
        var didCallBlock = false

        // given
        let event1 = await syncMOC.perform {
            self.eventStreamEvent(
                conversation: ZMConversation.selfConversation(in: self.syncMOC),
                genericMessage: GenericMessage(content: Calling(content: "123", conversationId: .random()))
            )
        }

        let event2 = await syncMOC.perform {
            self.eventStreamEvent()
        }

        insert([event1, event2])

        // when
        await sut.processStoredEvents(with: nil) { events in
            XCTAssertEqual(events, [event2])
            didCallBlock = true
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(didCallBlock)
    }

    func testThatItDoesProcessEventsFromSelfUserArrivingInSelfConversation() async {
        var didCallBlock = false

        // given
        let callingBessage = GenericMessage(content: Calling(content: "123", conversationId: .random()))

        let event1 = await syncMOC.perform {
            self.eventStreamEvent(
                conversation: ZMConversation.selfConversation(in: self.syncMOC),
                genericMessage: callingBessage,
                from: ZMUser.selfUser(in: self.syncMOC)
            )
        }
        let event2 = await syncMOC.perform {
            self.eventStreamEvent()
        }
        insert([event1, event2])

        // when
        await sut.processStoredEvents(with: nil) { events in
            XCTAssertEqual(events, [event1, event2])
            didCallBlock = true
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(didCallBlock)
    }

    func testThatItProcessAvailabilityEventsFromOtherUsersArrivingInSelfConversation() async {
        var didCallBlock = false

        // given
        let event1 = await syncMOC.perform {
            self.eventStreamEvent(
                conversation: ZMConversation.selfConversation(in: self.syncMOC),
                genericMessage: GenericMessage(content: WireProtos.Availability(.away))
            )
        }
        let event2 = await syncMOC.perform {
            self.eventStreamEvent()
        }

        insert([event1, event2])

        // when
        await sut.processStoredEvents(with: nil) { events in
            XCTAssertEqual(events, [event1, event2])
            didCallBlock = true
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(didCallBlock)
    }
}

// MARK: - Already seen events

extension EventDecoderTest {
    func testThatItProcessesEventsWithDifferentUUIDWhenThroughPushEventsFirst() async throws {
        // given
        let pushProcessed = customExpectation(description: "Push event processed")

        let pushEvent = await syncMOC.perform {
            self.pushNotificationEvent()
        }
        let streamEvent = await syncMOC.perform {
            self.eventStreamEvent()
        }

        // when
        _ = try await sut.decryptAndStoreEvents([pushEvent])
        await sut.processStoredEvents { events in
            XCTAssertTrue(events.contains(pushEvent))
            pushProcessed.fulfill()
        }

        // then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))

        // and when
        let streamProcessed = customExpectation(description: "Stream event processed")
        _ = try await sut.decryptAndStoreEvents([streamEvent])
        await sut.processStoredEvents { events in
            XCTAssertTrue(events.contains(streamEvent))
            streamProcessed.fulfill()
        }

        // then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItDoesProcessEventsWithSameUUIDWhenThroughPushEventsFirst() async throws {
        // given
        let pushProcessed = customExpectation(description: "Push event processed")
        let uuid = UUID.create()

        let pushEvent = await syncMOC.perform {
            self.pushNotificationEvent(uuid: uuid)
        }
        let streamEvent = await syncMOC.perform {
            self.eventStreamEvent(uuid: uuid)
        }

        // when
        _ = try await sut.decryptAndStoreEvents([pushEvent])
        await sut.processStoredEvents { events in
            XCTAssertTrue(events.contains(pushEvent))
            pushProcessed.fulfill()
        }

        // then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))

        // and when
        let streamProcessed = customExpectation(description: "Stream event not processed")

        _ = try await sut.decryptAndStoreEvents([streamEvent])
        await sut.processStoredEvents { events in
            // as filtering is removed, event with same id can go through process twice
            XCTAssertTrue(events.contains(streamEvent))
            streamProcessed.fulfill()
        }

        // then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItProcessesEventsWithSameUUIDWhenThroughPushEventsFirstAndDiscarding() async throws {
        // given
        let pushProcessed = customExpectation(description: "Push event processed")
        let uuid = UUID.create()

        let pushEvent = await syncMOC.perform {
            self.pushNotificationEvent(uuid: uuid)
        }
        let streamEvent = await syncMOC.perform {
            self.eventStreamEvent(uuid: uuid)
        }

        // when
        _ = try await sut.decryptAndStoreEvents([pushEvent])
        await sut.processStoredEvents { events in
            XCTAssertTrue(events.contains(pushEvent))
            pushProcessed.fulfill()
        }

        // then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))

        // and when
        let streamProcessed = customExpectation(description: "Stream event processed")

        _ = try await sut.decryptAndStoreEvents([streamEvent])
        await sut.processStoredEvents { events in
            XCTAssertTrue(events.contains(streamEvent))
            streamProcessed.fulfill()
        }

        // then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
    }
}

// MARK: - Proteus via Core Crypto Event Decryption

extension EventDecoderTest {
    func test_ProteusEventDecryption() async throws {
        var proteusViaCoreCrypto = DeveloperFlag.proteusViaCoreCrypto
        let mockProteusService = MockProteusServiceInterface()

        // Given
        mockProteusService.decryptDataForSession_MockMethod = { data, _ in
            (didCreateNewSession: false, decryptedData: data)
        }

        let event = await syncMOC.perform {
            let message = GenericMessage(content: Text(content: "foo"))
            return self.encryptedUpdateEventToSelfFromOtherClient(message: message)
        }

        proteusViaCoreCrypto.isOn = true

        await syncMOC.perform {
            self.syncMOC.proteusService = mockProteusService
        }

        // When
        _ = try await sut.decryptAndStoreEvents([event])

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        XCTAssertEqual(mockProteusService.decryptDataForSession_Invocations.count, 1)

        // Cleanup
        proteusViaCoreCrypto.isOn = false
    }

    func test_ProteusEventDecryptionDoesNotStoreLastEventIdIfFails() async throws {
        DeveloperFlag.proteusViaCoreCrypto.enable(true, storage: .temporary())
        defer {
            DeveloperFlag.proteusViaCoreCrypto.enable(false, storage: .standard)
        }

        let mockProteusService = MockProteusServiceInterface()
        enum FakeError: Error {
            case decryptionError
        }
        // Given
        mockProteusService.decryptDataForSession_MockMethod = { _, _ in
            throw FakeError.decryptionError
        }

        let event = await syncMOC.perform {
            let message = GenericMessage(content: Text(content: "foo"))
            return self.encryptedUpdateEventToSelfFromOtherClient(message: message)
        }

        await syncMOC.perform {
            self.syncMOC.proteusService = mockProteusService
        }

        // When
        _ = try await sut.decryptAndStoreEvents([event])

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        XCTAssertEqual(mockProteusService.decryptDataForSession_Invocations.count, 1)
        XCTAssertEqual(lastEventIDRepository.storeLastEventID_Invocations.count, 0)
    }

    func test_ProteusEventDecryption_Legacy() async throws {
        var proteusViaCoreCrypto = DeveloperFlag.proteusViaCoreCrypto

        // Given
        let event = await syncMOC.perform {
            let message = GenericMessage(content: Text(content: "foo"))
            return self.encryptedUpdateEventToSelfFromOtherClient(message: message)
        }

        proteusViaCoreCrypto.isOn = false

        // When
        let decryptedEvents = try await sut.decryptAndStoreEvents([event])
        XCTAssertEqual(decryptedEvents.count, 1)

        // Then
        // We could decrypt, and the proteus service doesn't exist, so it used the keystore.
        let proteusService = await syncMOC.perform { self.syncMOC.proteusService }
        XCTAssertNil(proteusService)

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }
}

// MARK: - MLS Event Decryption

extension EventDecoderTest {
    func test_DecryptMLSMessage_ReturnsDecryptedEvent() async {
        // Given
        let messageData = Data.random()
        let senderClientID = "clientID"
        mockMLSService.decryptMessageForSubconversationType_MockMethod = { _, _, _ in
            [.message(messageData, senderClientID)]
        }
        let event: ZMUpdateEvent = await syncMOC.perform { [self] in
            mlsMessageAddEvent(
                data: Data.random().base64EncodedString(),
                groupID: .random()
            )
        }
        // When
        let decryptedEvents = await sut.decryptMlsMessage(from: event, context: syncMOC)

        // Then
        let decryptedEvent = decryptedEvents.first
        let payloadData = decryptedEvent?.payload["data"] as? [String: Any]
        let decryptedData = payloadData?["text"] as? String
        let senderID = payloadData?["sender"] as? String

        XCTAssertEqual(decryptedData, messageData.base64EncodedString())
        XCTAssertEqual(senderClientID, senderID)
        XCTAssertEqual(decryptedEvent?.uuid, event.uuid)
    }

    func test_DecryptMLSMessage_SchedulesCommit_WhenMessageContainsProposal() async throws {
        // Given
        let commitDelay: UInt64 = 10
        let mlsGroupID = MLSGroupID.random()

        let event: ZMUpdateEvent = await syncMOC.perform { [self] in
            mlsMessageAddEvent(
                data: Data.random().base64EncodedString(),
                groupID: mlsGroupID
            )
        }
        var expectedCommitDate = try XCTUnwrap(event.timestamp)
        expectedCommitDate += TimeInterval(commitDelay)
        mockMLSService.decryptMessageForSubconversationType_MockMethod = { _, _, _ in
            [.proposal(commitDelay)]
        }

        // When
        let decryptedEvents = await sut.decryptMlsMessage(from: event, context: syncMOC)

        // Then
        XCTAssertTrue(decryptedEvents.isEmpty)

        await syncMOC.perform {
            guard let conversation = ZMConversation.fetch(with: mlsGroupID, in: self.syncMOC) else {
                XCTFail("expected conversation")
                return
            }

            XCTAssertEqual(conversation.commitPendingProposalDate, expectedCommitDate)
        }
    }

    func test_DecryptMLSMessage_CommitsPendingsProposals_WhenReceivingProposalOnWebsocket() async {
        // Given
        let commitDelay: UInt64 = 5
        let event: ZMUpdateEvent = await syncMOC.perform { [self] in
            mlsMessageAddEvent(
                data: Data.random().base64EncodedString(),
                groupID: .random()
            )
        }
        event.source = .webSocket
        mockMLSService.decryptMessageForSubconversationType_MockMethod = { _, _, _ in
            [.proposal(commitDelay)]
        }

        // When
        let decryptedEvents = await sut.decryptMlsMessage(from: event, context: syncMOC)

        // Then
        XCTAssertTrue(decryptedEvents.isEmpty)
        wait(forConditionToBeTrue: !mockMLSService.commitPendingProposalsIfNeeded_Invocations.isEmpty, timeout: 3)
        XCTAssertEqual(1, mockMLSService.commitPendingProposalsIfNeeded_Invocations.count)
    }

    func test_DecryptMLSMessage_CommitsPendingsProposalsIsNotCalled_WhenReceivingProposalViaDownload() async {
        // Given
        let commitDelay: UInt64 = 5
        let mlsGroupID = MLSGroupID.random()
        let event = await syncMOC.perform { [self] in
            mlsMessageAddEvent(
                data: Data.random().base64EncodedString(),
                groupID: mlsGroupID
            )
        }
        event.source = .download
        mockMLSService.decryptMessageForSubconversationType_MockMethod = { _, _, _ in
            [.proposal(commitDelay)]
        }

        // When
        let decryptedEvents = await sut.decryptMlsMessage(from: event, context: syncMOC)

        // Then
        XCTAssertTrue(decryptedEvents.isEmpty)
        spinMainQueue(withTimeout: 1)
        XCTAssertTrue(mockMLSService.commitPendingProposalsIfNeeded_Invocations.isEmpty)
    }

    func test_DecryptMLSMessage_ReturnsNoEvent_WhenPayloadIsInvalid() async {
        // Given
        let invalidDataPayload = ["invalidKey": ""]
        let event = await syncMOC.perform { self.mlsMessageAddEvent(data: invalidDataPayload) }

        // When
        let decryptedEvents = await sut.decryptMlsMessage(from: event, context: syncMOC)

        // Then
        XCTAssertTrue(decryptedEvents.isEmpty)
    }

    func test_DecryptMLSMessage_ReturnsNoEvent_WhenGroupIDIsMissing() async {
        // Given
        let event = await syncMOC.perform { [self] in
            mlsMessageAddEvent(
                data: Data.random().base64EncodedString(),
                groupID: nil
            )
        }

        // When
        let decryptedEvents = await sut.decryptMlsMessage(from: event, context: syncMOC)

        // Then
        XCTAssertTrue(decryptedEvents.isEmpty)
    }

    func test_DecryptMLSMessage_ReturnsNoEvent_WhenDecryptedDataIsNil() async {
        // Given
        mockMLSService.decryptMessageForSubconversationType_MockMethod = { _, _, _ in
            []
        }

        let event = await syncMOC.perform { [self] in
            mlsMessageAddEvent(
                data: Data.random().base64EncodedString(),
                groupID: .random()
            )
        }

        // When
        let decryptedEvents = await sut.decryptMlsMessage(from: event, context: syncMOC)

        // Then
        XCTAssertTrue(decryptedEvents.isEmpty)
    }

    func test_DecryptMLSMessage_ReturnsNoEvent_WhenmlsServiceThrows() async {
        // Given
        mockMLSService.decryptMessageForSubconversationType_MockMethod = { _, _, _ in
            throw MLSDecryptionService.MLSMessageDecryptionError.failedToDecryptMessage
        }

        let event = await syncMOC.perform { [self] in
            mlsMessageAddEvent(
                data: Data.random().base64EncodedString(),
                groupID: .random()
            )
        }

        // When
        let decryptedEvents = await sut.decryptMlsMessage(from: event, context: syncMOC)

        // Then
        XCTAssertTrue(decryptedEvents.isEmpty)
    }

    func test_DecryptWelcomeMessage_ReturnsEvent() async throws {
        // Given
        let conversationID = QualifiedID.random()
        let groupID = MLSGroupID.random()
        let event = mlsWelcomeMessageEvent(data: Data.random(), conversationID: conversationID)

        mockMLSService.processWelcomeMessageWelcomeMessage_MockValue = groupID

        // When
        let result = try await sut.decryptAndStoreEvents([event])

        // Then
        XCTAssertEqual(result, [event])
    }

    func test_DecryptWelcomeMessage_ProcessWelcomeMessage() async throws {
        // Given
        let conversationID = QualifiedID.random()
        let groupID = MLSGroupID.random()
        let event = mlsWelcomeMessageEvent(data: Data.random(), conversationID: conversationID)

        mockMLSService.processWelcomeMessageWelcomeMessage_MockValue = groupID

        // When
        _ = try await sut.decryptAndStoreEvents([event])

        // Then
        XCTAssertEqual(mockMLSService.processWelcomeMessageWelcomeMessage_Invocations.count, 1)
    }
}

// MARK: - Helpers

extension EventDecoderTest {
    /// Returns an event from the notification stream
    func eventStreamEvent(uuid: UUID? = nil) -> ZMUpdateEvent {
        let conversation = ZMConversation.insertNewObject(in: syncMOC)
        conversation.remoteIdentifier = UUID.create()
        let payload = payloadForMessage(in: conversation, type: EventConversation.add, data: ["foo": "bar"])!
        return ZMUpdateEvent(fromEventStreamPayload: payload, uuid: uuid ?? UUID.create())!
    }

    func eventStreamEvent(
        conversation: ZMConversation,
        genericMessage: GenericMessage,
        from user: ZMUser? = nil,
        uuid: UUID? = nil
    ) -> ZMUpdateEvent {
        var payload: ZMTransportData =
            if let user {
                payloadForMessage(
                    in: conversation,
                    type: EventConversation.addOTRMessage,
                    data: ["text": try? genericMessage.serializedData().base64EncodedString()],
                    time: nil,
                    from: user
                )!
            } else {
                payloadForMessage(
                    in: conversation,
                    type: EventConversation.addOTRMessage,
                    data: ["text": try? genericMessage.serializedData().base64EncodedString()]
                )!
            }

        return ZMUpdateEvent(fromEventStreamPayload: payload, uuid: uuid ?? UUID.create())!
    }

    /// Returns a `conversation.mls-message-add` event
    func mlsMessageAddEvent(data: Any, groupID: MLSGroupID? = nil) -> ZMUpdateEvent {
        let conversation = ZMConversation.insertNewObject(in: syncMOC)
        conversation.remoteIdentifier = UUID.create()
        conversation.mlsGroupID = groupID
        conversation.mlsStatus = .ready

        let payload = payloadForMessage(
            in: conversation,
            type: "conversation.mls-message-add",
            data: data,
            time: Date()
        )

        return ZMUpdateEvent(fromEventStreamPayload: payload!, uuid: UUID().create())!
    }

    /// Returns a `conversation.mls-message-add` event
    func mlsWelcomeMessageEvent(data: Data, conversationID: QualifiedID) -> ZMUpdateEvent {
        let payload = payloadForMessage(
            conversationID: conversationID.uuid,
            domain: conversationID.domain,
            type: "conversation.mls-welcome",
            data: data.base64EncodedString(),
            time: Date(),
            fromID: UUID()
        )

        return ZMUpdateEvent(fromEventStreamPayload: payload!, uuid: UUID().create())!
    }

    /// Returns an event from a push notification
    func pushNotificationEvent(uuid: UUID? = nil) -> ZMUpdateEvent {
        let conversation = ZMConversation.insertNewObject(in: syncMOC)
        conversation.remoteIdentifier = UUID.create()
        let innerPayload = payloadForMessage(in: conversation, type: EventConversation.add, data: ["foo": "bar"])!
        let payload = [
            "id": (uuid ?? UUID.create()).transportString(),
            "payload": [innerPayload],
        ] as [String: Any]
        let events = ZMUpdateEvent.eventsArray(from: payload as NSDictionary, source: .pushNotification)
        return events!.first!
    }

    func insert(_ events: [ZMUpdateEvent], startIndex: Int64 = 0) {
        eventMOC.performGroupedAndWait {
            for (index, event) in events.enumerated() {
                _ = StoredUpdateEvent.encryptAndCreate(
                    event,
                    context: self.eventMOC,
                    index: Int64(startIndex) + Int64(index)
                )
            }

            XCTAssert(self.eventMOC.saveOrRollback())
        }
    }
}
