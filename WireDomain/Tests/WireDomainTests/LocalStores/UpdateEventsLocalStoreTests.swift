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
            index: 1
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

        let fetchedEnvelopes = try await sut.fetchStoredEventEnvelopes(limit: 3)

        // Then it returns no envelopes.

        XCTAssertTrue(fetchedEnvelopes.isEmpty)
    }

    func testFetchStoredEventEnvelopePayloads_It_Fetches_Less_Than_The_Limit_If_There_Are_Not_Enough_Envelopes(
    ) async throws {
        // Given there are stored envelopes.

        try await insertStoredEventEnvelopes([Scaffolding.envelope3])

        // When

        let fetchedEnvelopes = try await sut.fetchStoredEventEnvelopes(limit: 3)

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

        let fetchedEnvelopes = try await sut.fetchStoredEventEnvelopes(limit: 3)

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
