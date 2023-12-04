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

import WireDataModelSupport
import WireTesting
@testable import WireRequestStrategy

public enum EventConversation {
    static let add = "conversation.message-add"
    static let addClientMessage = "conversation.client-message-add"
    static let addOTRMessage = "conversation.otr-message-add"
    static let addAsset = "conversation.asset-add"
    static let addOTRAsset = "conversation.otr-asset-add"
}

class EventDecoderTest: MessagingTestBase {

    var sut: EventDecoder!
    var mockMLSService = MockMLSServiceInterface()

    override func setUp() {
        super.setUp()
        sut = EventDecoder(eventMOC: eventMOC, syncMOC: syncMOC)

        syncMOC.performGroupedBlockAndWait {
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

    func testThatItProcessesEvents() async {
        // given
        var didCallBlock = false
        let event = await syncMOC.perform {
            self.eventStreamEvent()
        }

        _ = await sut.decryptAndStoreEvents([event])

        // when
        await sut.processStoredEvents { (events) in
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
        let primaryKeys = try keyGenerator.generatePrimaryPublicPrivateKeyPair(id: "event-decoder-tests.\(accountID).primary")
        let secondaryKeys = try keyGenerator.generateSecondaryPublicPrivateKeyPair(id: "event-decoder-tests.\(accountID).secondary")

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

        _ = await sut.decryptAndStoreEvents(
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

    func testThatItProcessesPreviouslyStoredEventsFirst() async {
        EventDecoder.testingBatchSize = 1
        var callCount = 0

        // given
        let event1 = await syncMOC.perform {
            self.eventStreamEvent()
        }
        let event2 = await syncMOC.perform {
            self.eventStreamEvent()
        }

        _ = await self.sut.decryptAndStoreEvents([event1])

        // when
        _ = await self.sut.decryptAndStoreEvents([event2])
        await self.sut.processStoredEvents { (events) in
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

    func testThatItProcessesInBatches() async {

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

        _ = await sut.decryptAndStoreEvents([event1, event2, event3, event4])

        // when
        await sut.processStoredEvents { (events) in
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

    func testThatItDoesNotProcessTheSameEventsTwiceWhenCalledSuccessively() async {
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

        _ = await self.sut.decryptAndStoreEvents([event1, event2])

        await sut.processStoredEvents(with: nil) { (events) in
            XCTAssert(events.contains(event1))
            XCTAssert(events.contains(event2))
        }

        insert([event3, event4], startIndex: 1)

        // when
        await sut.processStoredEvents(with: nil) { (events) in
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
            self.eventStreamEvent(conversation: ZMConversation.selfConversation(in: self.syncMOC), genericMessage: GenericMessage(content: Calling(content: "123", conversationId: .random())))
        }

        let event2 = await syncMOC.perform {
            self.eventStreamEvent()
        }

        self.insert([event1, event2])

        // when
        await sut.processStoredEvents(with: nil) { (events) in
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
            self.eventStreamEvent(conversation: ZMConversation.selfConversation(in: self.syncMOC), genericMessage: callingBessage, from: ZMUser.selfUser(in: self.syncMOC))
        }
        let event2 = await syncMOC.perform {
            self.eventStreamEvent()
        }
        self.insert([event1, event2])

        // when
        await sut.processStoredEvents(with: nil) { (events) in
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
            self.eventStreamEvent(conversation: ZMConversation.selfConversation(in: self.syncMOC), genericMessage: GenericMessage(content: WireProtos.Availability(.away)))
        }
        let event2 = await syncMOC.perform {
            self.eventStreamEvent()
        }

        self.insert([event1, event2])

        // when
        await sut.processStoredEvents(with: nil) { (events) in
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

    func testThatItProcessesEventsWithDifferentUUIDWhenThroughPushEventsFirst() async {

        // given
        let pushProcessed = self.expectation(description: "Push event processed")

        let pushEvent = await syncMOC.perform {
            self.pushNotificationEvent()
        }
        let streamEvent = await syncMOC.perform {
            self.eventStreamEvent()
        }

        // when
        _ = await sut.decryptAndStoreEvents([pushEvent])
        await sut.processStoredEvents { (events) in
            XCTAssertTrue(events.contains(pushEvent))
            pushProcessed.fulfill()
        }

        // then
        XCTAssert(self.waitForCustomExpectations(withTimeout: 0.5))

        // and when
        let streamProcessed = self.expectation(description: "Stream event processed")
        _ = await sut.decryptAndStoreEvents([streamEvent])
        await sut.processStoredEvents { (events) in
            XCTAssertTrue(events.contains(streamEvent))
            streamProcessed.fulfill()
        }

        // then
        XCTAssert(self.waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItDoesNotProcessesEventsWithSameUUIDWhenThroughPushEventsFirst() async {

        // given
        let pushProcessed = self.expectation(description: "Push event processed")
        let uuid = UUID.create()

        let pushEvent = await syncMOC.perform {
            self.pushNotificationEvent(uuid: uuid)
        }
        let streamEvent = await syncMOC.perform {
            self.eventStreamEvent(uuid: uuid)
        }

        // when
        _ = await sut.decryptAndStoreEvents([pushEvent])
        await sut.processStoredEvents { (events) in
            XCTAssertTrue(events.contains(pushEvent))
            pushProcessed.fulfill()
        }

        // then
        XCTAssert(self.waitForCustomExpectations(withTimeout: 0.5))

        // and when
        let streamProcessed = self.expectation(description: "Stream event not processed")

        _ = await sut.decryptAndStoreEvents([streamEvent])
        await sut.processStoredEvents { (events) in
            XCTAssertTrue(events.isEmpty)
            streamProcessed.fulfill()
        }

        // then
        XCTAssert(self.waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItProcessesEventsWithSameUUIDWhenThroughPushEventsFirstAndDiscarding() async {

        // given
        let pushProcessed = self.expectation(description: "Push event processed")
        let uuid = UUID.create()

        let pushEvent = await syncMOC.perform {
            self.pushNotificationEvent(uuid: uuid)
        }
        let streamEvent = await syncMOC.perform {
            self.eventStreamEvent(uuid: uuid)
        }

        // when
        _ = await self.sut.decryptAndStoreEvents([pushEvent])
        await self.sut.processStoredEvents { (events) in
            XCTAssertTrue(events.contains(pushEvent))
            pushProcessed.fulfill()
        }
        self.sut.discardListOfAlreadyReceivedPushEventIDs()

        // then
        XCTAssert(self.waitForCustomExpectations(withTimeout: 0.5))

        // and when
        let streamProcessed = self.expectation(description: "Stream event processed")

        _ = await self.sut.decryptAndStoreEvents([streamEvent])
        await self.sut.processStoredEvents { (events) in
            XCTAssertTrue(events.contains(streamEvent))
            streamProcessed.fulfill()
        }

        // then
        XCTAssert(self.waitForCustomExpectations(withTimeout: 0.5))
    }

}

// MARK: - Proteus via Core Crypto Event Decryption

extension EventDecoderTest {

    func test_ProteusEventDecryption() async throws {
        var proteusViaCoreCrypto = DeveloperFlag.proteusViaCoreCrypto
        let mockProteusService = MockProteusServiceInterface()

        // Given
        mockProteusService.decryptDataForSession_MockMethod = { data, _ in
            return (didCreateNewSession: false, decryptedData: data)
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
        _ = await self.sut.decryptAndStoreEvents([event])

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        XCTAssertEqual(mockProteusService.decryptDataForSession_Invocations.count, 1)

        // Cleanup
        proteusViaCoreCrypto.isOn = false
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
        let decryptedEvents = await self.sut.decryptAndStoreEvents([event])
        XCTAssertEqual(decryptedEvents.count, 1)

        // Then
        // We could decrypt, and the proteus service doesn't exist, so it used the keystore.
        let proteusService = await self.syncMOC.perform { self.syncMOC.proteusService }
        XCTAssertNil(proteusService)

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

}

// MARK: - MLS Event Decryption

extension EventDecoderTest {
    func test_DecryptMLSMessage_ReturnsDecryptedEvent() {
        syncMOC.performAndWait {
            // Given
            let messageData = randomData
            let senderClientID = "clientID"
            mockMLSService.decryptMessageForSubconversationType_MockMethod = { _, _, _ in
                .message(messageData, senderClientID)
            }

            let event = mlsMessageAddEvent(
                data: randomData.base64EncodedString(),
                groupID: randomGroupID
            )

            // When
            let decryptedEvent = sut.decryptMlsMessage(from: event, context: syncMOC)

            // Then
            let payloadData = decryptedEvent?.payload["data"] as? [String: Any]
            let decryptedData = payloadData?["text"] as? String
            let senderID = payloadData?["sender"] as? String

            XCTAssertEqual(decryptedData, messageData.base64EncodedString())
            XCTAssertEqual(senderClientID, senderID)
            XCTAssertEqual(decryptedEvent?.uuid, event.uuid)
        }
    }

    func test_DecryptMLSMessage_SchedulesCommit_WhenMessageContainsProposal() {
        syncMOC.performAndWait {
            // Given
            let commitDelay: UInt64 = 5
            let mlsGroupID = randomGroupID
            let event = mlsMessageAddEvent(
                data: randomData.base64EncodedString(),
                groupID: mlsGroupID
            )
            let expectedCommitDate = event.timestamp! + TimeInterval(commitDelay)
            mockMLSService.decryptMessageForSubconversationType_MockMethod = { _, _, _ in
                    .proposal(commitDelay)
            }

            // When
            let decryptedEvent = sut.decryptMlsMessage(from: event, context: syncMOC)

            // Then
            XCTAssertNil(decryptedEvent)

            guard let conversation = ZMConversation.fetch(with: mlsGroupID, in: syncMOC) else {
                XCTFail("expected conversation")
                return
            }

            XCTAssertEqual(conversation.commitPendingProposalDate, expectedCommitDate)
        }
    }

    func test_DecryptMLSMessage_CommitsPendingsProposals_WhenReceivingProposalOnWebsocket() {
        syncMOC.performAndWait {
            // Given
            let commitDelay: UInt64 = 5
            let mlsGroupID = randomGroupID
            let event = mlsMessageAddEvent(
                data: randomData.base64EncodedString(),
                groupID: mlsGroupID
            )
            event.source = .webSocket
            mockMLSService.decryptMessageForSubconversationType_MockMethod = { _, _, _ in
                    .proposal(commitDelay)
            }

            // When
            let decryptedEvent = sut.decryptMlsMessage(from: event, context: syncMOC)

            // Then
            XCTAssertNil(decryptedEvent)
            XCTAssertTrue(wait(withTimeout: 3.0) { [self] in
                !mockMLSService.commitPendingProposals_Invocations.isEmpty
            })

            XCTAssertEqual(1, mockMLSService.commitPendingProposals_Invocations.count)
        }
    }

    func test_DecryptMLSMessage_CommitsPendingsProposalsIsNotCalled_WhenReceivingProposalViaDownload() {
        syncMOC.performAndWait {
            // Given
            let commitDelay: UInt64 = 5
            let mlsGroupID = randomGroupID
            let event = mlsMessageAddEvent(
                data: randomData.base64EncodedString(),
                groupID: mlsGroupID
            )
            event.source = .download
            mockMLSService.decryptMessageForSubconversationType_MockMethod = { _, _, _ in
                    .proposal(commitDelay)
            }

            // When
            let decryptedEvent = sut.decryptMlsMessage(from: event, context: syncMOC)

            // Then
            XCTAssertNil(decryptedEvent)
            spinMainQueue(withTimeout: 1)
            XCTAssertTrue(mockMLSService.commitPendingProposals_Invocations.isEmpty)
        }
    }

    func test_DecryptMLSMessage_ReturnsNil_WhenPayloadIsInvalid() {
        syncMOC.performAndWait {
            // Given
            let invalidDataPayload = ["invalidKey": ""]
            let event = mlsMessageAddEvent(data: invalidDataPayload)

            // When
            let decryptedEvent = sut.decryptMlsMessage(from: event, context: syncMOC)

            // Then
            XCTAssertNil(decryptedEvent)
        }
    }

    func test_DecryptMLSMessage_ReturnsNil_WhenGroupIDIsMissing() {
        syncMOC.performAndWait {
            // Given
            let event = mlsMessageAddEvent(
                data: randomData.base64EncodedString(),
                groupID: nil
            )

            // When
            let decryptedEvent = sut.decryptMlsMessage(from: event, context: syncMOC)

            // Then
            XCTAssertNil(decryptedEvent)
        }
    }

    func test_DecryptMLSMessage_ReturnsNil_WhenDecryptedDataIsNil() {
        syncMOC.performAndWait {
            // Given
            mockMLSService.decryptMessageForSubconversationType_MockMethod = { _, _, _ in
                .none
            }

            let event = mlsMessageAddEvent(
                data: randomData.base64EncodedString(),
                groupID: randomGroupID
            )

            // When
            let decryptedEvent = sut.decryptMlsMessage(from: event, context: syncMOC)

            // Then
            XCTAssertNil(decryptedEvent)
        }
    }

    func test_DecryptMLSMessage_ReturnsNil_WhenmlsServiceThrows() {
        syncMOC.performAndWait {
            // Given
            mockMLSService.decryptMessageForSubconversationType_MockMethod = { _, _, _ in
                throw MLSDecryptionService.MLSMessageDecryptionError.failedToDecryptMessage
            }

            let event = mlsMessageAddEvent(
                data: randomData.base64EncodedString(),
                groupID: randomGroupID
            )

            // When
            let decryptedEvent = sut.decryptMlsMessage(from: event, context: syncMOC)

            // Then
            XCTAssertNil(decryptedEvent)
        }
    }

    var randomData: Data {
        return .random()
    }

    var randomGroupID: MLSGroupID {
        return MLSGroupID(randomData.bytes)
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

    func eventStreamEvent(conversation: ZMConversation, genericMessage: GenericMessage, from user: ZMUser? = nil, uuid: UUID? = nil) -> ZMUpdateEvent {
        var payload: ZMTransportData
        if let user = user {
            payload = payloadForMessage(in: conversation, type: EventConversation.addOTRMessage, data: ["text": try? genericMessage.serializedData().base64EncodedString()], time: nil, from: user)!
        } else {
            payload = payloadForMessage(in: conversation, type: EventConversation.addOTRMessage, data: ["text": try? genericMessage.serializedData().base64EncodedString()])!
        }

        return ZMUpdateEvent(fromEventStreamPayload: payload, uuid: uuid ?? UUID.create())!
    }

    /// Returns a `conversation.mls-message-add` event
    func mlsMessageAddEvent(data: Any, groupID: MLSGroupID? = nil) -> ZMUpdateEvent {
        let conversation = ZMConversation.insertNewObject(in: syncMOC)
        conversation.remoteIdentifier = UUID.create()
        conversation.mlsGroupID = groupID
        conversation.mlsStatus = .ready

        let payload = self.payloadForMessage(
            in: conversation,
            type: "conversation.mls-message-add",
            data: data,
            time: Date()
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
            "payload": [innerPayload]
        ] as [String: Any]
        let events = ZMUpdateEvent.eventsArray(from: payload as NSDictionary, source: .pushNotification)
        return events!.first!
    }

    func insert(_ events: [ZMUpdateEvent], startIndex: Int64 = 0) {
        eventMOC.performGroupedBlockAndWait {
            events.enumerated().forEach { index, event  in
                _ = StoredUpdateEvent.encryptAndCreate(event, context: self.eventMOC, index: Int64(startIndex) + Int64(index))
            }

            XCTAssert(self.eventMOC.saveOrRollback())
        }
    }

}
