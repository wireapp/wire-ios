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

import WireTesting
@testable import WireRequestStrategy

@available(iOS 15, *)
class StoreUpdateEventTests: MessagingTestBase {

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
            let primaryKeys = try keyGenerator.generatePublicPrivateKeyPair(id: primaryID)
            let secondaryID = "stored-update-event-tests.secondary.\(account.userIdentifier)"
            let secondaryKeys = try keyGenerator.generatePublicPrivateKeyPair(id: secondaryID)

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

    private func createNewConversationEvent(for conversation: ZMConversation) -> ZMUpdateEvent {
        let payload = payloadForMessage(in: conversation, type: EventConversation.add, data: ["foo": "bar"])!
        let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: UUID.create())!
        event.appendDebugInformation("Highly informative description")
        return event
    }

    private func createStoredEvent(
        for conversation: ZMConversation,
        index: UInt
    ) throws -> StoredUpdateEvent {
        return try createStoredEvents(
            for: conversation,
            indices: [index]
        )[0]
    }

    private func createStoredEvents(
        for conversation: ZMConversation,
        indices: [UInt]
    ) throws -> [StoredUpdateEvent] {
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

    // MARK: - Tests

    func testThatYouCanCreateAnEvent() throws {
        // Given
        eventMOC.performAndWait {
            let conversation = self.createConversation(in: self.uiMOC)
            let event = self.createNewConversationEvent(for: conversation)

            // When
            if let storedEvent = StoredUpdateEvent.encryptAndCreate(
                event, context: self.eventMOC,
                index: 2
            ) {
                // Then
                XCTAssertEqual(storedEvent.debugInformation, event.debugInformation)
                XCTAssertEqual(storedEvent.payload, event.payload as NSDictionary)
                XCTAssertEqual(storedEvent.isTransient, event.isTransient)
                XCTAssertEqual(storedEvent.source, Int16(event.source.rawValue))
                XCTAssertEqual(storedEvent.sortIndex, 2)
                XCTAssertEqual(storedEvent.uuidString, event.uuid?.transportString())
            } else {
                XCTFail("Did not create storedEvent")
            }
        }
    }

    func testThatItFetchesAllStoredEvents() throws {
        try eventMOC.performAndWait {
            // Given
            let conversation = self.createConversation(in: self.uiMOC)

            let storedEvents = try self.createStoredEvents(
                for: conversation,
                indices: [0, 1, 2]
            )

            // When
            let batch = StoredUpdateEvent.nextEvents(
                self.eventMOC,
                batchSize: 4
            )

            // Then
            XCTAssertEqual(batch.count, 3)
            XCTAssertTrue(batch.contains(storedEvents[0]))
            XCTAssertTrue(batch.contains(storedEvents[1]))
            XCTAssertTrue(batch.contains(storedEvents[2]))
            batch.forEach { XCTAssertFalse($0.isFault) }
        }
    }

    func testThatItOrdersEventsBySortIndex() throws {
        try eventMOC.performAndWait {
            // Given
            let conversation = self.createConversation(in: self.uiMOC)

            let storedEvents = try self.createStoredEvents(
                for: conversation,
                indices: [0, 30, 10]
            )

            // When
            let batch = StoredUpdateEvent.nextEvents(
                self.eventMOC,
                batchSize: 3
            )

            // Then
            XCTAssertEqual(batch[0], storedEvents[0])
            XCTAssertEqual(batch[1], storedEvents[2])
            XCTAssertEqual(batch[2], storedEvents[1])
        }
    }

    func testThatItReturnsOnlyDefinedBatchSize() throws {
        try eventMOC.performAndWait {
            // Given
            let conversation = self.createConversation(in: self.uiMOC)

            let storedEvents = try self.createStoredEvents(
                for: conversation,
                indices: [0, 10, 30]
            )

            // When
            let firstBatch = StoredUpdateEvent.nextEvents(
                self.eventMOC,
                batchSize: 2
            )

            // Then
            XCTAssertEqual(firstBatch.count, 2)
            XCTAssertTrue(firstBatch.contains(storedEvents[0]))
            XCTAssertTrue(firstBatch.contains(storedEvents[1]))
            XCTAssertFalse(firstBatch.contains(storedEvents[2]))

            // When
            firstBatch.forEach(self.eventMOC.delete)
            let secondBatch = StoredUpdateEvent.nextEvents(
                self.eventMOC,
                batchSize: 2
            )

            // Then
            XCTAssertEqual(secondBatch.count, 1)
            XCTAssertTrue(secondBatch.contains(storedEvents[2]))
        }
    }

    func testThatItReturnsHighestIndex() throws {
        eventMOC.performAndWait {
            // Given
            let conversation = self.createConversation(in: self.uiMOC)

            // When
            let highestIndex = StoredUpdateEvent.highestIndex(self.eventMOC)

            // Then
            XCTAssertEqual(highestIndex, 2)
        }
    }

    func testThatItCanConvertAnEventToStoredEventAndBack() throws {
        try eventMOC.performAndWait {
            // Given
            let conversation = self.createConversation(in: self.uiMOC)
            let event = self.createNewConversationEvent(for: conversation)

            // When
            let storedEvent = try self.createStoredEvent(
                from: event,
                index: 0
            )

            let events = StoredUpdateEvent.eventsFromStoredEvents(
                [storedEvent],
                privateKeys: nil
            )

            // Then
            let restoredEvent = try XCTUnwrap(events.eventsToProcess.first)
            XCTAssertEqual(restoredEvent, event)
            XCTAssertEqual(restoredEvent.payload["foo"] as? String, event.payload["foo"] as? String)
            XCTAssertEqual(restoredEvent.isTransient, event.isTransient)
            XCTAssertEqual(restoredEvent.source, event.source)
            XCTAssertEqual(restoredEvent.uuid, event.uuid)
            return
        }
    }

    // MARK: - Encryption at Rest

    func testThatItEncryptsEventIfThePublicKeyIsNotNil() throws {
        try eventMOC.performAndWait {
            // Given
            let conversation = self.createConversation(in: self.uiMOC)
            let event = self.createNewConversationEvent(for: conversation)

            // When
            guard let storedEvent = StoredUpdateEvent.encryptAndCreate(
                event, context: self.eventMOC,
                index: 2,
                publicKeys: self.publicKeys
            ) else {
                return XCTFail("Did not create storedEvent")
            }

            // Then
            XCTAssertEqual(storedEvent.debugInformation, event.debugInformation)
            XCTAssertEqual(storedEvent.isTransient, event.isTransient)
            XCTAssertEqual(storedEvent.source, Int16(event.source.rawValue))
            XCTAssertEqual(storedEvent.sortIndex, 2)
            XCTAssertEqual(storedEvent.uuidString, event.uuid?.transportString())
            XCTAssertNotNil(storedEvent.payload)

            #if targetEnvironment(simulator) && swift(>=5.4)
            if isRunningiOS15 {
                XCTExpectFailure("Expect to fail on iOS 15 simulator. ref: https://wearezeta.atlassian.net/browse/SQCORE-1188")
            }
            #endif

            XCTAssertTrue(storedEvent.isEncrypted)

            guard let privateKey = self.privateKeys.primary else {
                return XCTFail("primary private key is unavailable")
            }

            let decryptedPayload = try self.decryptStoredEvent(
                event: storedEvent,
                privateKey: privateKey
            )

            XCTAssertEqual(decryptedPayload, event.payload as NSDictionary)
        }
    }

    func testThatItDoesNotEncryptEventIfThePublicKeyIsNil() throws {
        eventMOC.performAndWait {
            // Given
            let conversation = self.createConversation(in: self.uiMOC)
            let event = self.createNewConversationEvent(for: conversation)

            // When
            guard let storedEvent = StoredUpdateEvent.encryptAndCreate(
                event, context: self.eventMOC,
                index: 2,
                publicKeys: nil
            ) else {
                return XCTFail("Did not create storedEvent")
            }

            XCTAssertEqual(storedEvent.debugInformation, event.debugInformation)
            XCTAssertEqual(storedEvent.payload, event.payload as NSDictionary)
            XCTAssertEqual(storedEvent.isTransient, event.isTransient)
            XCTAssertEqual(storedEvent.source, Int16(event.source.rawValue))
            XCTAssertEqual(storedEvent.sortIndex, 2)
            XCTAssertEqual(storedEvent.uuidString, event.uuid?.transportString())
            XCTAssertNotNil(storedEvent.payload)
            XCTAssertFalse(storedEvent.isEncrypted)
        }
    }

    func testThatItDecryptsAndConvertsStoreEventToTheUpdateEventIfThePrivateKeyIsNotNil() throws {
        try eventMOC.performAndWait {
            // Given
            let conversation = self.createConversation(in: self.uiMOC)
            let event = self.createNewConversationEvent(for: conversation)

            // When
            guard let storedEvent = StoredUpdateEvent.encryptAndCreate(
                event, context: self.eventMOC,
                index: 2,
                publicKeys: self.publicKeys
            ) else {
                return XCTFail("Did not create storedEvent")
            }

            XCTAssertEqual(storedEvent.debugInformation, event.debugInformation)
            XCTAssertEqual(storedEvent.isTransient, event.isTransient)
            XCTAssertEqual(storedEvent.source, Int16(event.source.rawValue))
            XCTAssertEqual(storedEvent.sortIndex, 2)
            XCTAssertEqual(storedEvent.uuidString, event.uuid?.transportString())
            XCTAssertNotNil(storedEvent.payload)

            #if targetEnvironment(simulator) && swift(>=5.4)
            if isRunningiOS15 {
                XCTExpectFailure("Expect to fail on iOS 15 simulator. ref: https://wearezeta.atlassian.net/browse/SQCORE-1188")
            }
            #endif
            XCTAssertTrue(storedEvent.isEncrypted)

            // When
            let convertedEvents = StoredUpdateEvent.eventsFromStoredEvents(
                [storedEvent],
                privateKeys: self.privateKeys
            )

            // Then
            let convertedEvent = try XCTUnwrap(convertedEvents.eventsToProcess.first)
            XCTAssertEqual(convertedEvent.debugInformation, event.debugInformation)
            XCTAssertEqual(convertedEvent.payload as NSDictionary, event.payload as NSDictionary)
            XCTAssertEqual(convertedEvent.isTransient, event.isTransient)
            XCTAssertEqual(convertedEvent.source, event.source)
            XCTAssertEqual(convertedEvent.uuid?.transportString(), event.uuid?.transportString())
        }
    }

    func testThatItConvertsStoreEventToTheUpdateEventIfThePrivateKeyIsNil() throws {
        try eventMOC.performAndWait {
            // Given
            let conversation = self.createConversation(in: self.uiMOC)
            let event = self.createNewConversationEvent(for: conversation)

            // When
            guard let storedEvent = StoredUpdateEvent.encryptAndCreate(
                event, context: self.eventMOC,
                index: 2,
                publicKeys: nil
            ) else {
                return XCTFail("Did not create storedEvent")
            }

            XCTAssertEqual(storedEvent.debugInformation, event.debugInformation)
            XCTAssertEqual(storedEvent.payload, event.payload as NSDictionary)
            XCTAssertEqual(storedEvent.isTransient, event.isTransient)
            XCTAssertEqual(storedEvent.source, Int16(event.source.rawValue))
            XCTAssertEqual(storedEvent.sortIndex, 2)
            XCTAssertEqual(storedEvent.uuidString, event.uuid?.transportString())
            XCTAssertNotNil(storedEvent.payload)
            XCTAssertFalse(storedEvent.isEncrypted)

            // When
            let convertedEvents = StoredUpdateEvent.eventsFromStoredEvents(
                [storedEvent],
                privateKeys: nil
            )

            // Then
            let convertedEvent = try XCTUnwrap(convertedEvents.eventsToProcess.first)
            XCTAssertEqual(convertedEvent.debugInformation, event.debugInformation)
            XCTAssertEqual(convertedEvent.payload as NSDictionary, event.payload as NSDictionary)
            XCTAssertEqual(convertedEvent.isTransient, event.isTransient)
            XCTAssertEqual(convertedEvent.source, event.source)
            XCTAssertEqual(convertedEvent.uuid?.transportString(), event.uuid?.transportString())
        }
    }

    func testThatItCanNotConvertEncryptedStoredEventWithoutPrivateKey() throws {
        eventMOC.performAndWait {
            // Given
            let conversation = self.createConversation(in: self.uiMOC)
            let event = self.createNewConversationEvent(for: conversation)

            // When
            guard let storedEvent = StoredUpdateEvent.encryptAndCreate(
                event, context: self.eventMOC,
                index: 2,
                publicKeys: self.publicKeys
            ) else {
                return XCTFail("Did not create storedEvent")
            }

            XCTAssertEqual(storedEvent.debugInformation, event.debugInformation)
            XCTAssertEqual(storedEvent.isTransient, event.isTransient)
            XCTAssertEqual(storedEvent.source, Int16(event.source.rawValue))
            XCTAssertEqual(storedEvent.sortIndex, 2)
            XCTAssertEqual(storedEvent.uuidString, event.uuid?.transportString())
            XCTAssertNotNil(storedEvent.payload)

            #if targetEnvironment(simulator) && swift(>=5.4)
            if self.isRunningiOS15 {
                XCTExpectFailure("Expect to fail on iOS 15 simulator. ref: https://wearezeta.atlassian.net/browse/SQCORE-1188")
            }
            #endif
            XCTAssertTrue(storedEvent.isEncrypted)

            // When
            let convertedEvents = StoredUpdateEvent.eventsFromStoredEvents(
                [storedEvent],
                privateKeys: nil
            )

            // Then
            XCTAssertTrue(convertedEvents.eventsToProcess.isEmpty)
            XCTAssertTrue(convertedEvents.eventsToDelete.isEmpty)
        }
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

}

