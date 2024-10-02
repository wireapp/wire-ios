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

@testable import WireRequestStrategy
import WireTesting

final class StoreUpdateEventTests: MessagingTestBase {

    struct Failure: Error {

        var description: String

        init(_ description: String) {
            self.description = description
        }

    }

    var account: Account!
    var publicKey: SecKey?
    var publicKeys: EARPublicKeys!
    var privateKeys: EARPrivateKeys!

    // MARK: - Life cycle

    override func setUpWithError() throws {
        try super.setUpWithError()

        try eventMOC.performAndWait {
            account = Account(userName: "John Doe", userIdentifier: UUID())
            let keyGenerator = EARKeyGenerator()
            let primaryID = "stored-update-event-tests.primary.\(account.userIdentifier)"
            let primaryKeys = try keyGenerator.generatePrimaryPublicPrivateKeyPair(id: primaryID)
            let secondaryID = "stored-update-event-tests.secondary.\(account.userIdentifier)"
            let secondaryKeys = try keyGenerator.generateSecondaryPublicPrivateKeyPair(id: secondaryID)

            publicKeys = EARPublicKeys(
                primary: primaryKeys.publicKey,
                secondary: secondaryKeys.publicKey
            )

            privateKeys = EARPrivateKeys(
                primary: primaryKeys.privateKey,
                secondary: secondaryKeys.privateKey
            )
        }
    }

    override func tearDown() {
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        account = nil
        publicKey = nil
        privateKeys = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func createConversation(
        id: UUID = .create(),
        in context: NSManagedObjectContext
    ) -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: context)
        conversation.remoteIdentifier = id
        return conversation
    }

    private func createNewConversationEvent(for conversation: ZMConversation, uuid: UUID = .create()) -> ZMUpdateEvent {
        let payload = payloadForMessage(in: conversation, type: EventConversation.add, data: ["foo": "bar"])!
        let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: uuid)!
        event.appendDebugInformation("Highly informative description")
        return event
    }

    private func createNewCallEvent(for conversation: ZMConversation, uuid: UUID = .create()) throws -> ZMUpdateEvent {
        let callEventContent = CallEventContent(
            type: "CONFSTART",
            properties: nil,
            callerUserID: nil,
            callerClientID: "",
            resp: false
        )

        let calling = Calling(content: try callEventContent.encodeToJSONString(), conversationId: .random())
        let genericMessage = GenericMessage(content: calling)
        let serializedData = try genericMessage.serializedData()

        let payload = payloadForMessage(
            in: conversation,
            type: EventConversation.addOTRMessage,
            data: ["text": serializedData.base64String()]
        )!

        let event = ZMUpdateEvent(
            fromEventStreamPayload: payload,
            uuid: uuid
        )!

        event.appendDebugInformation("Highly informative description")
        return event

    }

    private func createStoredEvent(index: UInt) throws -> StoredUpdateEvent {
        return try createStoredEvents(indices: [index])[0]
    }

    private func createStoredEvents(indices: [UInt]) throws -> [StoredUpdateEvent] {
        let conversation = createConversation(in: uiMOC)
        let eventsAndIndices = indices.map { index in
            (createNewConversationEvent(for: conversation), index)
        }

        return try createStoredEvents(eventsAndIndices: eventsAndIndices)
    }

    private func createStoredEvent(
        from event: ZMUpdateEvent,
        index: UInt
    ) throws -> StoredUpdateEvent {
        return try createStoredEvents(eventsAndIndices: [(event, index)])[0]
    }

    private func createStoredEvents(eventsAndIndices: [(ZMUpdateEvent, UInt)]) throws -> [StoredUpdateEvent] {
        return try eventsAndIndices.map { event, index in
            guard let storedEvent = StoredUpdateEvent.encryptAndCreate(
                event,
                context: eventMOC,
                index: Int64(index)
            ) else {
                throw Failure("Could not create storedEvents")
            }

            return storedEvent
        }
    }

    private func createStoredEvents(encrypt: Bool) throws -> ([ZMUpdateEvent], [StoredUpdateEvent]) {
        let conversation = self.createConversation(in: self.uiMOC)
        let event1 = self.createNewConversationEvent(for: conversation)
        let event2 = try self.createNewCallEvent(for: conversation)

        guard let storedEvent1 = StoredUpdateEvent.encryptAndCreate(
            event1,
            context: self.eventMOC,
            index: 2,
            publicKeys: encrypt ? self.publicKeys : nil
        ) else {
            throw Failure("Did not create storedEvent")
        }

        guard let storedEvent2 = StoredUpdateEvent.encryptAndCreate(
            event2,
            context: self.eventMOC,
            index: 3,
            publicKeys: encrypt ? self.publicKeys : nil
        ) else {
            throw Failure("Did not create storedEvent")
        }

        // Then first event is encrypted and not a call event
        assertStoredEventProperties(storedEvent: storedEvent1, event: event1)
        XCTAssertEqual(storedEvent1.sortIndex, 2)
        XCTAssertNotNil(storedEvent1.payload)
        XCTAssertFalse(storedEvent1.isCallEvent)
        XCTAssertEqual(storedEvent1.isEncrypted, encrypt)

        // Then second event is encrypted and a call event
        assertStoredEventProperties(storedEvent: storedEvent2, event: event2)
        XCTAssertEqual(storedEvent2.sortIndex, 3)
        XCTAssertNotNil(storedEvent2.payload)
        XCTAssertTrue(storedEvent2.isCallEvent)
        XCTAssertEqual(storedEvent2.isEncrypted, encrypt)

        return ([event1, event2], [storedEvent1, storedEvent2])
    }

    private func decryptStoredEvent(
        event: StoredUpdateEvent,
        privateKey: SecKey
    ) throws -> NSDictionary {
        guard let encryptedPayload = event.payload?[StoredUpdateEvent.encryptedPayloadKey] else {
            throw Failure("expected encrypted payload")
        }

        guard let decryptedData = SecKeyCreateDecryptedData(
            privateKey,
            .eciesEncryptionCofactorX963SHA256AESGCM,
            encryptedPayload as! CFData,
            nil
        ) else {
            throw Failure("failed to decrypt payload")
        }

        guard let payload = try JSONSerialization.jsonObject(
            with: decryptedData as Data,
            options: []
        ) as? NSDictionary else {
            throw Failure("failed to serialize payload")
        }

        return payload
    }

    private func assertStoredEventProperties(
        storedEvent: StoredUpdateEvent,
        event: ZMUpdateEvent
    ) {
        XCTAssertEqual(storedEvent.debugInformation, event.debugInformation)
        XCTAssertEqual(storedEvent.isTransient, event.isTransient)
        XCTAssertEqual(storedEvent.source, Int16(event.source.rawValue))
        XCTAssertEqual(storedEvent.uuidString, event.uuid?.transportString())
    }

    // MARK: - Encrypt and create

    func test_EncryptAndCreate_DoesNotStoreDuplicateEvents() throws {
        eventMOC.performAndWait {
            // Given some events.
            let conversation = self.createConversation(in: self.uiMOC)
            let event1 = self.createNewConversationEvent(for: conversation)

            guard let storedEvent1 = StoredUpdateEvent.encryptAndCreate(
                event1,
                context: self.eventMOC,
                index: 2,
                publicKeys: nil
            ) else {
                return XCTFail("Did not create storedEvent")
            }

            let duplicateStoredEvent1 = StoredUpdateEvent.encryptAndCreate(
                event1,
                context: self.eventMOC,
                index: 2,
                publicKeys: nil
            )

            // Then first event is encrypted
            assertStoredEventProperties(storedEvent: storedEvent1, event: event1)
            XCTAssertEqual(storedEvent1.sortIndex, 2)
            XCTAssertNotNil(storedEvent1.payload)
            XCTAssertFalse(storedEvent1.isCallEvent)
            XCTAssertFalse(storedEvent1.isEncrypted)

            XCTAssertNil(duplicateStoredEvent1)
        }
    }

    func test_EncryptAndCreate_DoesNotStoreEventIfHashDoesNotExistButSameEventId() throws {
        try eventMOC.performAndWait {
            // GIVEN
            let conversation = self.createConversation(in: self.uiMOC)
            let event1 = self.createNewConversationEvent(for: conversation)

            _ = StoredUpdateEvent.create(from: event1,
                                                                  eventId: try XCTUnwrap(event1.uuid?.uuidString.lowercased()),
                                                                  eventHash: 0,
                                                                  index: 1,
                                                                  context: eventMOC)
            // WHEN
            let storedEvent1 = StoredUpdateEvent.encryptAndCreate(
                event1,
                context: self.eventMOC,
                index: 1,
                publicKeys: nil
            )

            XCTAssertNil(storedEvent1, "it should drop the event")
        }
    }

    func test_EncryptAndCreate_StoresDuplicateEventsWithSameEventId() throws {
        try eventMOC.performAndWait {
            // Given some events.
            let conversation = self.createConversation(in: self.uiMOC)
            let event1 = self.createNewConversationEvent(for: conversation)
            let event2 = try self.createNewCallEvent(for: conversation, uuid: try XCTUnwrap(event1.uuid))

            guard let storedEvent1 = StoredUpdateEvent.encryptAndCreate(
                event1,
                context: self.eventMOC,
                index: 1,
                publicKeys: nil
            ) else {
                return XCTFail("Did not create storedEvent")
            }

            let storedEvent2 = try XCTUnwrap(StoredUpdateEvent.encryptAndCreate(
                event2,
                context: self.eventMOC,
                index: 2,
                publicKeys: nil
            ))

            assertStoredEventProperties(storedEvent: storedEvent1, event: event1)
            XCTAssertEqual(storedEvent1.sortIndex, 1)
            XCTAssertNotNil(storedEvent1.payload)
            XCTAssertFalse(storedEvent1.isCallEvent)
            XCTAssertFalse(storedEvent1.isEncrypted)

            assertStoredEventProperties(storedEvent: storedEvent2, event: event2)
            XCTAssertEqual(storedEvent2.sortIndex, 2)
            XCTAssertNotNil(storedEvent2.payload)
            XCTAssertTrue(storedEvent2.isCallEvent)
            XCTAssertFalse(storedEvent2.isEncrypted)

        }
    }

    func test_EncryptAndCreate_Unencrypted() throws {
        try eventMOC.performAndWait {
            // Given some events.
            let conversation = self.createConversation(in: self.uiMOC)
            let event1 = self.createNewConversationEvent(for: conversation)
            let event2 = try self.createNewCallEvent(for: conversation)

            // When we store the events without public keys.
            guard let storedEvent1 = StoredUpdateEvent.encryptAndCreate(
                event1,
                context: self.eventMOC,
                index: 2,
                publicKeys: nil
            ) else {
                return XCTFail("Did not create storedEvent")
            }

            guard let storedEvent2 = StoredUpdateEvent.encryptAndCreate(
                event2,
                context: self.eventMOC,
                index: 3,
                publicKeys: nil
            ) else {
                return XCTFail("Did not create storedEvent")
            }

            // Then first event is not encrypted
            assertStoredEventProperties(storedEvent: storedEvent1, event: event1)
            XCTAssertEqual(storedEvent1.sortIndex, 2)
            XCTAssertFalse(storedEvent1.isCallEvent)
            XCTAssertFalse(storedEvent1.isEncrypted)
            XCTAssertEqual(storedEvent1.payload, event1.payload as NSDictionary)

            // Then second event is not encrypted
            assertStoredEventProperties(storedEvent: storedEvent2, event: event2)
            XCTAssertEqual(storedEvent2.sortIndex, 3)
            XCTAssertTrue(storedEvent2.isCallEvent)
            XCTAssertFalse(storedEvent2.isEncrypted)
            XCTAssertEqual(storedEvent2.payload, event2.payload as NSDictionary)
        }
    }

    func test_EncryptAndCreate_DoesNotStoreDuplicateEvents_Encrypted() throws {
        eventMOC.performAndWait {
            // Given some events.
            let conversation = self.createConversation(in: self.uiMOC)
            let event1 = self.createNewConversationEvent(for: conversation)

            guard let storedEvent1 = StoredUpdateEvent.encryptAndCreate(
                event1,
                context: self.eventMOC,
                index: 2,
                publicKeys: self.publicKeys
            ) else {
                return XCTFail("Did not create storedEvent")
            }

            let duplicateStoredEvent1 = StoredUpdateEvent.encryptAndCreate(
                event1,
                context: self.eventMOC,
                index: 2,
                publicKeys: self.publicKeys
            )

            // Then first event is encrypted
            assertStoredEventProperties(storedEvent: storedEvent1, event: event1)
            XCTAssertEqual(storedEvent1.sortIndex, 2)
            XCTAssertNotNil(storedEvent1.payload)
            XCTAssertFalse(storedEvent1.isCallEvent)
            XCTAssertTrue(storedEvent1.isEncrypted)

            XCTAssertNil(duplicateStoredEvent1)
        }

    }

    func test_EncryptAndCreate_CanStoreEventsWithSameIdButDifferentPayloads() throws {
        try eventMOC.performAndWait {
            // Given some events.
            let conversation = self.createConversation(in: self.uiMOC)

            let event1 = self.createNewConversationEvent(for: conversation)
            let storedEvent1 = StoredUpdateEvent.encryptAndCreate(
                event1,
                context: self.eventMOC,
                index: 2,
                publicKeys: nil
            )
            XCTAssertNotNil(storedEvent1)

            let event2 = try createNewCallEvent(for: conversation, uuid: event1.uuid!)
            let storedEvent2 = StoredUpdateEvent.encryptAndCreate(
                event2,
                context: self.eventMOC,
                index: 1,
                publicKeys: nil
            )
            XCTAssertNotNil(storedEvent2)
        }

    }

    func test_EncryptAndCreate_Encrypted() throws {
        try eventMOC.performAndWait {
            // Given some events.
            let conversation = self.createConversation(in: self.uiMOC)
            let event1 = self.createNewConversationEvent(for: conversation)
            let event2 = try createNewCallEvent(for: conversation)

            // When we store the events with public keys.
            guard let storedEvent1 = StoredUpdateEvent.encryptAndCreate(
                event1,
                context: self.eventMOC,
                index: 2,
                publicKeys: self.publicKeys
            ) else {
                return XCTFail("Did not create storedEvent")
            }

            guard let storedEvent2 = StoredUpdateEvent.encryptAndCreate(
                event2,
                context: self.eventMOC,
                index: 3,
                publicKeys: self.publicKeys
            ) else {
                return XCTFail("Did not create storedEvent")
            }

            // Then first event is encrypted
            assertStoredEventProperties(storedEvent: storedEvent1, event: event1)
            XCTAssertEqual(storedEvent1.sortIndex, 2)
            XCTAssertNotNil(storedEvent1.payload)
            XCTAssertFalse(storedEvent1.isCallEvent)
            XCTAssertTrue(storedEvent1.isEncrypted)

            // Then second event is encrypted
            assertStoredEventProperties(storedEvent: storedEvent2, event: event2)
            XCTAssertEqual(storedEvent2.sortIndex, 3)
            XCTAssertNotNil(storedEvent2.payload)
            XCTAssertTrue(storedEvent2.isCallEvent)
            XCTAssertTrue(storedEvent2.isEncrypted)
        }
    }

    // MARK: - Next events

    func test_NextEvents() throws {
        try eventMOC.performAndWait {
            // Given some stored events.
            let storedEvents = try self.createStoredEvents(indices: [0, 1, 2])

            // When we fetch a batch of events.
            let batch = StoredUpdateEvent.nextEvents(
                self.eventMOC,
                batchSize: 4,
                callEventsOnly: false
            )

            // Then all the events are returned.
            XCTAssertEqual(batch, storedEvents)
            batch.forEach { XCTAssertFalse($0.isFault) }
        }
    }

    func test_NextEvents_OrderedResults() throws {
        try eventMOC.performAndWait {
            // Given some stored events with various indices.
            let storedEvents = try self.createStoredEvents(indices: [0, 30, 10])

            // When we fetch a batch of events.
            let batch = StoredUpdateEvent.nextEvents(
                self.eventMOC,
                batchSize: 3,
                callEventsOnly: false
            )

            // Then they are returned in the correct order.
            XCTAssertEqual(batch[0], storedEvents[0])
            XCTAssertEqual(batch[1], storedEvents[2])
            XCTAssertEqual(batch[2], storedEvents[1])
        }
    }

    func test_NextEvents_BatchSize() throws {
        try eventMOC.performAndWait {
            // Given some stored events.
            let storedEvents = try self.createStoredEvents(indices: [0, 1, 2])

            // When we fetch a small batch.
            let firstBatch = StoredUpdateEvent.nextEvents(
                self.eventMOC,
                batchSize: 2,
                callEventsOnly: false
            )

            // Then the batch size is correct
            XCTAssertEqual(firstBatch, Array(storedEvents.prefix(2)))

            // When we fetch another batch.
            firstBatch.forEach(self.eventMOC.delete)
            let secondBatch = StoredUpdateEvent.nextEvents(
                self.eventMOC,
                batchSize: 2,
                callEventsOnly: false
            )

            // Then
            XCTAssertEqual(secondBatch, Array(storedEvents.dropFirst(2)))
        }
    }

    func test_NextEvents_CallEventsOnly() throws {
        try eventMOC.performAndWait {
            // Given stored events (containing 1 call event)
            let storedEvents = try self.createStoredEvents(encrypt: false).1

            // When we fetch a batch
            let batch = StoredUpdateEvent.nextEvents(
                self.eventMOC,
                batchSize: 2,
                callEventsOnly: true
            )

            // Then we only get 1 event (call event)
            XCTAssertEqual(batch, Array(storedEvents.dropFirst()))
        }
    }

    // MARK: - Highest index

    func test_HighestIndex() throws {
        try eventMOC.performAndWait {
            // Given some events.
            _ = try self.createStoredEvents(indices: [0, 1, 2])

            // When we query the highest index.
            let highestIndex = StoredUpdateEvent.highestIndex(self.eventMOC)

            // Then
            XCTAssertEqual(highestIndex, 2)
        }
    }

    // MARK: - Event from stored events

    func test_EventFromStoredEvents_Unencrypted() throws {
        try eventMOC.performAndWait {
            // Given some uncrypted events.
            let (updateEvents, storedEvents) = try self.createStoredEvents(encrypt: false)

            // When we retrieve the events without private keys.
            let fetchedEvents = StoredUpdateEvent.eventsFromStoredEvents(
                storedEvents,
                privateKeys: nil
            )

            // Then we can process and delete all events.
            XCTAssertEqual(fetchedEvents.eventsToProcess, updateEvents)
            XCTAssertEqual(fetchedEvents.eventsToDelete, storedEvents)
        }
    }

    func test_EventFromStoredEvents_Encrypted() throws {
        try eventMOC.performAndWait {
            // Given some encrypted stored events.
            let (updateEvents, storedEvents) = try self.createStoredEvents(encrypt: true)

            // When we retrieve the events with private keys.
            let fetchedEvents = StoredUpdateEvent.eventsFromStoredEvents(
                storedEvents,
                privateKeys: self.privateKeys
            )

            // Then we process and delete all events.
            XCTAssertEqual(fetchedEvents.eventsToProcess, updateEvents)
            XCTAssertEqual(fetchedEvents.eventsToDelete, storedEvents)
        }
    }

    func test_EventFromStoredEvents_Encrypted_SecondaryPrivateKeyOnly() throws {
        try eventMOC.performAndWait {
            // Given some encrypted events.
            let (updateEvents, storedEvents) = try self.createStoredEvents(encrypt: true)

            // When we retrieve the events with only the secondary private key.
            self.privateKeys = EARPrivateKeys(
                primary: nil,
                secondary: self.privateKeys.secondary
            )

            let fetchedEvents = StoredUpdateEvent.eventsFromStoredEvents(
                storedEvents,
                privateKeys: self.privateKeys
            )

            // Then we process and delete only the events associated with the secondary key.
            XCTAssertEqual(fetchedEvents.eventsToProcess, updateEvents.filter(\.isCallEvent))
            XCTAssertEqual(fetchedEvents.eventsToDelete, storedEvents.filter(\.isCallEvent))
        }
    }

    func test_EventFromStoredEvents_Encrypted_NoPrivateKeys() throws {
        try eventMOC.performAndWait {
            // Given some encrypted events.
            let (_, storedEvents) = try self.createStoredEvents(encrypt: true)

            // When we retrieve the events with no private keys.
            let convertedEvents = StoredUpdateEvent.eventsFromStoredEvents(
                storedEvents,
                privateKeys: nil
            )

            // Then we can neither process nor delete any events.
            XCTAssertTrue(convertedEvents.eventsToProcess.isEmpty)
            XCTAssertTrue(convertedEvents.eventsToDelete.isEmpty)
        }
    }
}
