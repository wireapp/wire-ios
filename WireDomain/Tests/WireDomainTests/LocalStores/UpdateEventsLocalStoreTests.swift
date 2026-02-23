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

import GenericMessageProtocol
import WireDataModel
import WireDataModelSupport
import WireTestingPackage
import WireUpdateEventCoding
import XCTest
@testable import WireDomain
@testable import WireDomainSupport
@testable import WireNetwork

final class UpdateEventsLocalStoreTests: XCTestCase {

    private var sut: UpdateEventsLocalStore!
    private var mockUserDefaults: UserDefaults!
    private var stack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var modelHelper: ModelHelper!

    private var eventContext: NSManagedObjectContext {
        stack.eventContext
    }

    private var syncContext: NSManagedObjectContext {
        stack.syncContext
    }

    override func setUp() async throws {
        modelHelper = ModelHelper()
        coreDataStackHelper = CoreDataStackHelper()
        stack = try await coreDataStackHelper.createStack(inMemoryStore: false)
        /// Batch requests don't work with in-memory store
        /// so we need to use a persistent store.
        try await cleanUpEntity()
        mockUserDefaults = UserDefaults(
            suiteName: Scaffolding.defaultsTestSuiteName
        )
        sut = UpdateEventsLocalStore(
            eventContext: eventContext,
            syncContext: syncContext,
            userID: Scaffolding.selfUserID.id,
            sharedUserDefaults: mockUserDefaults
        )
    }

    override func tearDown() async throws {
        modelHelper = nil
        coreDataStackHelper = CoreDataStackHelper()
        stack = nil
        sut = nil
        mockUserDefaults.removePersistentDomain(
            forName: Scaffolding.defaultsTestSuiteName
        )
        mockUserDefaults = nil
        try coreDataStackHelper.cleanupDirectory()
    }

    // MARK: - Tests

    func testPersistEventEnvelope_It_Stores_Envelope_Locally() async throws {
        // When

        try await sut.persistEventEnvelope(
            Scaffolding.envelope1,
            index: 1,
            publicKeys: nil
        )

        // Then

        try await eventContext.perform { [eventContext] in
            let request = StoredUpdateEventEnvelope.sortedFetchRequest(asending: true)
            let storedEventEnvelope = try XCTUnwrap(eventContext.fetch(request).first)
            let coder = StorableUpdateEventCoder()
            let decodedEnvelope = try coder.decode(storedEventEnvelope.data)

            XCTAssertEqual(decodedEnvelope.id, Scaffolding.envelope1.id)
            XCTAssertEqual(decodedEnvelope.events, Scaffolding.envelope1.events)
        }
    }

    func testFetchStoredEventEnvelopePayloads_It_Fetches_No_Envelopes_If_There_Are_None() async throws {
        // Given no stored events.

        // When

        let fetchedEnvelopes = try await sut.fetchStoredEventEnvelopes(
            limit: 3,
            privateKeys: nil,
            backgroundAccessibleOnly: false
        )

        // Then it returns no envelopes.

        XCTAssertTrue(fetchedEnvelopes.isEmpty)
    }

    func testFetchStoredEventEnvelopePayloads_It_Fetches_Less_Than_The_Limit_If_There_Are_Not_Enough_Envelopes(
    ) async throws {
        // Given there are stored envelopes.

        try await insertStoredEventEnvelopes([Scaffolding.envelope3])

        // When

        let fetchedEnvelopes = try await sut.fetchStoredEventEnvelopes(
            limit: 3,
            privateKeys: nil,
            backgroundAccessibleOnly: false
        )

        // Then it returns the one and only envelope.
        try XCTAssertCount(fetchedEnvelopes, count: 1)
        let fetchedEnvelope1 = fetchedEnvelopes[0].0

        XCTAssertEqual(fetchedEnvelope1, Scaffolding.envelope3)
    }

    func testFetchStoredEventEnvelopePayloads_It_Does_Not_Fetch_More_Than_The_Limit() async throws {
        // Given there are stored envelopes.

        try await insertStoredEventEnvelopes([
            Scaffolding.envelope3,
            Scaffolding.envelope4,
            Scaffolding.envelope1,
            Scaffolding.envelope5,
            Scaffolding.envelope2
        ])

        // When

        let fetchedEnvelopes = try await sut.fetchStoredEventEnvelopes(
            limit: 3,
            privateKeys: nil,
            backgroundAccessibleOnly: false
        )

        // Then the first 3 envelopes were returned.
        try XCTAssertCount(fetchedEnvelopes, count: 3)

        XCTAssertEqual(fetchedEnvelopes[0].0, Scaffolding.envelope3)
        XCTAssertEqual(fetchedEnvelopes[1].0, Scaffolding.envelope4)
        XCTAssertEqual(fetchedEnvelopes[2].0, Scaffolding.envelope1)
    }

    func testDeleteNextPendingEvents_It_Deletes_All_Stored_Envelopes() async throws {
        // Given there are stored envelopes.

        let objectIDs = try await insertStoredEventEnvelopes([
            Scaffolding.envelope1,
            Scaffolding.envelope2,
            Scaffolding.envelope3
        ])

        // When it deletes all stored envelopes.

        try await sut.deleteNextPendingEvents(with: objectIDs)

        // Then all stored events were deleted.

        try await eventContext.perform { [eventContext] in
            let request = StoredUpdateEventEnvelope.fetchRequest()
            let result = try eventContext.fetch(request)
            XCTAssertTrue(result.isEmpty)
        }
    }

    func testDeleteNextPendingEvents_It_Deletes_Only_Selected_Envelopes() async throws {
        // Given there are stored envelopes.

        var objectIDs = try await insertStoredEventEnvelopes([
            Scaffolding.envelope1,
            Scaffolding.envelope2,
            Scaffolding.envelope3
        ])

        let nonDeletedEnvelopeObjectID = objectIDs.removeLast()

        // When it deletes selected envelopes.

        try await sut.deleteNextPendingEvents(with: objectIDs)

        // Then selected envelopes were deleted, remains only one.

        try await eventContext.perform { [eventContext] in
            let request = StoredUpdateEventEnvelope.fetchRequest()
            let result = try eventContext.fetch(request) as! [StoredUpdateEventEnvelope]
            XCTAssertEqual(result.count, 1)
            XCTAssertEqual(result.first!.objectID, nonDeletedEnvelopeObjectID)
        }
    }

    func testDeleteEventEnvelope_It_Deletes_The_Stored_Envelope() async throws {
        // Given there are stored envelopes.
        try await insertStoredEventEnvelopes([
            Scaffolding.envelope1,
            Scaffolding.envelope2,
            Scaffolding.envelope3
        ])

        // When it deletes the first one
        try await sut.deleteEventEnvelope(atIndex: 0)

        // Then the first envelope (index 0) was deleted and indices 1 and 2 remain.
        try await eventContext.perform { [eventContext] in
            let request = StoredUpdateEventEnvelope.sortedFetchRequest(asending: true)
            let result = try eventContext.fetch(request)
            XCTAssertEqual(result.count, 2)

            let indicesOfStoredEnvelopes = result.map(\.sortIndex)
            XCTAssertEqual(indicesOfStoredEnvelopes, [1, 2])
        }
    }

    func testStoreLastEventID_It_Stores_Last_Event_Envelope_ID() throws {
        // Given

        let id = UUID()

        // When

        sut.storeLastEventID(id: id)

        // Then

        let lastEventId = try XCTUnwrap(mockUserDefaults.string(forKey: Scaffolding.lastEventIDUserDefaultsKey))
        XCTAssertEqual(UUID(uuidString: lastEventId), id)
    }

    func testCalculateLastUnreadMessages_It_Disables_Flag_After_Calculation() async throws {
        // Given

        let conversation = try await syncContext.perform { [self] in
            let conversation = modelHelper.createGroupConversation(in: syncContext)
            try modelHelper.addTextMessages(
                to: conversation,
                sender: nil,
                count: 1,
                in: syncContext
            )
            conversation.needsToCalculateUnreadMessages = true

            return conversation
        }

        // When

        await sut.calculateLastUnreadMessages()

        // Then
        await syncContext.perform {
            XCTAssertEqual(conversation.needsToCalculateUnreadMessages, false)
        }
    }

    // MARK: - EAR Encryption Tests

    func testPersistEventEnvelope_WithPublicKeys_EncryptsData() async throws {
        // Given: Generate key pair
        let (publicKey, _) = try generateKeyPair()
        let (secondaryPublicKey, _) = try generateSecondaryKeyPair()

        let publicKeys = EARPublicKeys(
            primary: publicKey,
            secondary: secondaryPublicKey
        )

        // Create non-calling event (should use primary key)
        let event = createNonCallingEvent()
        let envelope = UpdateEventEnvelope(
            id: UUID(),
            events: [event],
            isTransient: false,
            deliveryTag: nil
        )

        // When
        try await sut.persistEventEnvelope(envelope, index: 0, publicKeys: publicKeys)

        // Then: Verify envelope is stored and encrypted
        try await eventContext.perform { [eventContext] in
            let request = StoredUpdateEventEnvelope.sortedFetchRequest(asending: true)
            let stored = try XCTUnwrap(eventContext.fetch(request).first)

            XCTAssertTrue(stored.isEncrypted, "Should be marked as encrypted")
            XCTAssertFalse(stored.isBackgroundAccessible, "Non-calling event not background accessible")

            // Verify data is actually encrypted (not plaintext)
            let coder = StorableUpdateEventCoder()
            XCTAssertThrowsError(try coder.decode(stored.data))
        }
    }

    func testPersistEventEnvelope_CallingEvent_UsesSecondaryKey() async throws {
        // Given: Generate key pairs
        let (publicKey, _) = try generateKeyPair()
        let (secondaryPublicKey, _) = try generateSecondaryKeyPair()

        let publicKeys = EARPublicKeys(
            primary: publicKey,
            secondary: secondaryPublicKey
        )

        // Create calling-related event (should use secondary key)
        let event = createCallingEvent()
        let envelope = UpdateEventEnvelope(
            id: UUID(),
            events: [event],
            isTransient: false,
            deliveryTag: nil
        )

        // When
        try await sut.persistEventEnvelope(envelope, index: 0, publicKeys: publicKeys)

        // Then: Verify envelope is encrypted and background accessible
        try await eventContext.perform { [eventContext] in
            let request = StoredUpdateEventEnvelope.sortedFetchRequest(asending: true)
            let stored = try XCTUnwrap(eventContext.fetch(request).first)

            XCTAssertTrue(stored.isEncrypted)
            XCTAssertTrue(stored.isBackgroundAccessible, "Calling event should be background accessible")
        }
    }

    func testFetchStoredEventEnvelopes_Encrypted_DecryptsWithPrimaryKey() async throws {
        // Given: Generate key pair and encrypt an envelope
        let (publicKey, privateKey) = try generateKeyPair()
        let (secondaryPublicKey, secondaryPrivateKey) = try generateSecondaryKeyPair()

        let publicKeys = EARPublicKeys(primary: publicKey, secondary: secondaryPublicKey)
        let privateKeys = EARPrivateKeys(primary: privateKey, secondary: secondaryPrivateKey)

        let eventID = UUID()
        let event = createNonCallingEvent()
        let envelope = UpdateEventEnvelope(
            id: eventID,
            events: [event],
            isTransient: false,
            deliveryTag: nil
        )

        // Persist encrypted
        try await sut.persistEventEnvelope(envelope, index: 0, publicKeys: publicKeys)

        // When: Fetch with private keys
        let fetched = try await sut.fetchStoredEventEnvelopes(
            limit: 10,
            privateKeys: privateKeys,
            backgroundAccessibleOnly: false
        )

        // Then: Should decrypt and return envelope
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.envelope.id, eventID)
        XCTAssertEqual(fetched.first?.envelope.events.count, 1)
    }

    func testFetchStoredEventEnvelopes_Encrypted_NoPrivateKeys_Throws() async throws {
        // Given: Encrypted envelope stored
        let (publicKey, _) = try generateKeyPair()
        let (secondaryPublicKey, _) = try generateSecondaryKeyPair()

        let publicKeys = EARPublicKeys(primary: publicKey, secondary: secondaryPublicKey)

        let envelope = UpdateEventEnvelope(
            id: UUID(),
            events: [createNonCallingEvent()],
            isTransient: false,
            deliveryTag: nil
        )

        try await sut.persistEventEnvelope(envelope, index: 0, publicKeys: publicKeys)

        // When / Then: Fetching encrypted events without private keys is a developer error
        await XCTAssertThrowsErrorAsync({
            _ = try await self.sut.fetchStoredEventEnvelopes(
                limit: 10,
                privateKeys: nil,
                backgroundAccessibleOnly: false
            )
        }) { error in
            guard
                case UpdateEventsLocalStore.Error.failedToFetchStoredEvents(let inner) = error,
                let storeError = inner as? UpdateEventsLocalStore.Error,
                case .missingPrivateKeys = storeError
            else {
                XCTFail("Expected failedToFetchStoredEvents(missingPrivateKeys), got: \(error)")
                return
            }
        }
    }

    func testFetchStoredEventEnvelopes_BackgroundAccessibleOnly_FiltersCorrectly() async throws {
        // Given: Mix of encrypted and unencrypted envelopes
        let (publicKey, privateKey) = try generateKeyPair()
        let (secondaryPublicKey, secondaryPrivateKey) = try generateSecondaryKeyPair()

        let publicKeys = EARPublicKeys(primary: publicKey, secondary: secondaryPublicKey)
        let privateKeys = EARPrivateKeys(primary: privateKey, secondary: secondaryPrivateKey)

        // 1. Unencrypted envelope (should be included)
        let unencryptedEnvelope = UpdateEventEnvelope(
            id: UUID(),
            events: [createNonCallingEvent()],
            isTransient: false,
            deliveryTag: nil
        )
        try await sut.persistEventEnvelope(unencryptedEnvelope, index: 0, publicKeys: nil)

        // 2. Encrypted + background accessible (calling event, should be included)
        let backgroundAccessibleEnvelope = UpdateEventEnvelope(
            id: UUID(),
            events: [createCallingEvent()],
            isTransient: false,
            deliveryTag: nil
        )
        try await sut.persistEventEnvelope(backgroundAccessibleEnvelope, index: 1, publicKeys: publicKeys)

        // 3. Encrypted + NOT background accessible (should be excluded)
        let nonBackgroundAccessibleEnvelope = UpdateEventEnvelope(
            id: UUID(),
            events: [createNonCallingEvent()],
            isTransient: false,
            deliveryTag: nil
        )
        try await sut.persistEventEnvelope(nonBackgroundAccessibleEnvelope, index: 2, publicKeys: publicKeys)

        // When: Fetch with backgroundAccessibleOnly: true
        let fetched = try await sut.fetchStoredEventEnvelopes(
            limit: 10,
            privateKeys: privateKeys,
            backgroundAccessibleOnly: true
        )

        // Then: Should return only unencrypted and background-accessible envelopes
        XCTAssertEqual(fetched.count, 2)

        let fetchedIDs = fetched.map(\.envelope.id)
        XCTAssertTrue(fetchedIDs.contains(unencryptedEnvelope.id))
        XCTAssertTrue(fetchedIDs.contains(backgroundAccessibleEnvelope.id))
        XCTAssertFalse(fetchedIDs.contains(nonBackgroundAccessibleEnvelope.id))
    }

    func testEncryptionDecryption_RoundTrip_BothKeyTypes() async throws {
        // Given: Both key pairs
        let (publicKey, privateKey) = try generateKeyPair()
        let (secondaryPublicKey, secondaryPrivateKey) = try generateSecondaryKeyPair()

        let publicKeys = EARPublicKeys(primary: publicKey, secondary: secondaryPublicKey)
        let privateKeys = EARPrivateKeys(primary: privateKey, secondary: secondaryPrivateKey)

        // Create one envelope for each key type
        let primaryEnvelope = UpdateEventEnvelope(
            id: UUID(),
            events: [createNonCallingEvent()],
            isTransient: false,
            deliveryTag: nil
        )

        let secondaryEnvelope = UpdateEventEnvelope(
            id: UUID(),
            events: [createCallingEvent()],
            isTransient: false,
            deliveryTag: nil
        )

        // When: Persist both
        try await sut.persistEventEnvelope(primaryEnvelope, index: 0, publicKeys: publicKeys)
        try await sut.persistEventEnvelope(secondaryEnvelope, index: 1, publicKeys: publicKeys)

        // Fetch both
        let fetched = try await sut.fetchStoredEventEnvelopes(
            limit: 10,
            privateKeys: privateKeys,
            backgroundAccessibleOnly: false
        )

        // Then: Both should be decrypted successfully
        XCTAssertEqual(fetched.count, 2)

        let fetchedIDs = fetched.map(\.envelope.id)
        XCTAssertTrue(fetchedIDs.contains(primaryEnvelope.id))
        XCTAssertTrue(fetchedIDs.contains(secondaryEnvelope.id))
    }

    // MARK: - Helper Methods

    private func generateKeyPair() throws -> (publicKey: SecKey, privateKey: SecKey) {
        let keyGenerator = EARKeyGenerator()
        return try keyGenerator.generatePrimaryPublicPrivateKeyPair(id: "test-primary-\(UUID().uuidString)")
    }

    private func generateSecondaryKeyPair() throws -> (publicKey: SecKey, privateKey: SecKey) {
        let keyGenerator = EARKeyGenerator()
        return try keyGenerator.generateSecondaryPublicPrivateKeyPair(id: "test-secondary-\(UUID().uuidString)")
    }

    private func createNonCallingEvent() -> UpdateEvent {
        .user(.pushRemove)
    }

    private func createCallingEvent() -> UpdateEvent {
        // Create a GenericMessage with Calling content
        let callingMessage = GenericMessage(
            content: Calling(content: "calling", conversationId: .init(uuid: UUID(), domain: "")),
            nonce: UUID()
        )

        // Serialize to data
        let callingData = try! callingMessage.serializedData().base64String()

        // Create a ProteusMessageAddEvent with the calling message as decrypted content
        let event = ConversationProteusMessageAddEvent(
            conversationID: Scaffolding.conversationID,
            senderID: Scaffolding.aliceID,
            timestamp: Date(),
            message: MessageContent(
                encryptedMessage: "encrypted",
                decryptedMessage: callingData
            ),
            externalData: nil,
            messageSenderClientID: Scaffolding.aliceClientID,
            messageRecipientClientID: Scaffolding.selfClientID
        )

        return .conversation(.proteusMessageAdd(event))
    }

    @discardableResult
    private func insertStoredEventEnvelopes(
        _ envelopes: [UpdateEventEnvelope]
    ) async throws -> [NSManagedObjectID] {
        try await eventContext.perform { [eventContext] in
            let coder = StorableUpdateEventCoder()

            for (index, envelope) in envelopes.enumerated() {
                let storedEventEnvelope = StoredUpdateEventEnvelope(context: eventContext)
                storedEventEnvelope.data = try coder.encode(envelope)
                storedEventEnvelope.sortIndex = Int64(index)
            }

            try eventContext.save()

            let fetchRequest = StoredUpdateEventEnvelope.fetchRequest()
            let results = try eventContext.fetch(fetchRequest) as! [StoredUpdateEventEnvelope]

            XCTAssertEqual(results.count, envelopes.count)

            return results.map(\.objectID)
        }
    }

    func cleanUpEntity() async throws {
        try await eventContext.perform { [self] in
            let fetchRequest = StoredUpdateEventEnvelope.fetchRequest()
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            _ = try eventContext.execute(batchDeleteRequest)
        }
    }

    private enum Scaffolding {

        static let localDomain = "local.com"
        static let selfUserID = UserID(id: .mockID1, domain: localDomain)
        static let selfClientID = "abcd1234"
        static let conversationID = ConversationID(id: .mockID2, domain: localDomain)
        static let lastEventID = UUID.mockID3
        static let otherDomain = "other.com"
        static let aliceID = UserID(id: .mockID4, domain: otherDomain)
        static let aliceClientID = "efgh5678"
        static let defaultsTestSuiteName = UUID().uuidString

        static let id1 = UUID.mockID1
        static let id2 = UUID.mockID2
        static let id3 = UUID.mockID3
        static let id4 = UUID.mockID4
        static let id5 = UUID.mockID5

        static let time30SecondsAgo = Date(timeIntervalSinceNow: -30)
        static let time20SecondsAgo = Date(timeIntervalSinceNow: -20)

        static let lastEventIDUserDefaultsKey = "\(selfUserID.id.uuidString)_lastEventID"

        static let envelope1 = UpdateEventEnvelope(
            id: id1,
            events: [.user(.pushRemove)],
            isTransient: false
        )

        static let envelope2 = UpdateEventEnvelope(
            id: id2,
            events: [.user(.pushRemove)],
            isTransient: false
        )

        static let envelope3 = UpdateEventEnvelope(
            id: id3,
            events: [.conversation(.proteusMessageAdd(proteusMessage1))],
            isTransient: false
        )

        static let envelope4 = UpdateEventEnvelope(
            id: id4,
            events: [.user(.pushRemove)],
            isTransient: true
        )

        static let envelope5 = UpdateEventEnvelope(
            id: id5,
            events: [.conversation(.proteusMessageAdd(proteusMessage2))],
            isTransient: false
        )

        static let proteusMessage1 = ConversationProteusMessageAddEvent(
            conversationID: conversationID,
            senderID: aliceID,
            timestamp: time30SecondsAgo,
            message: MessageContent(encryptedMessage: "xxxxx"),
            externalData: nil,
            messageSenderClientID: aliceClientID,
            messageRecipientClientID: selfClientID
        )

        static let proteusMessage2 = ConversationProteusMessageAddEvent(
            conversationID: conversationID,
            senderID: aliceID,
            timestamp: time20SecondsAgo,
            message: MessageContent(encryptedMessage: "yyyyy"),
            externalData: nil,
            messageSenderClientID: aliceClientID,
            messageRecipientClientID: selfClientID
        )

    }

}
