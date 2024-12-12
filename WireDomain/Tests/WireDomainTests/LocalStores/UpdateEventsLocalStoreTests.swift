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

@testable import WireAPI
import WireDataModel
import WireDataModelSupport
import WireTestingPackage
import XCTest
@testable import WireDomain
@testable import WireDomainSupport

final class UpdateEventsLocalStoreTests: XCTestCase {

    private var sut: UpdateEventsLocalStore!
    private var mockUserDefaults: UserDefaults!
    private var stack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!

    private var context: NSManagedObjectContext {
        stack.eventContext
    }

    override func setUp() async throws {
        coreDataStackHelper = CoreDataStackHelper()
        stack = try await coreDataStackHelper.createStack()
        mockUserDefaults = UserDefaults(
            suiteName: Scaffolding.defaultsTestSuiteName
        )
        sut = UpdateEventsLocalStore(
            context: context,
            userID: Scaffolding.selfUserID.uuid,
            sharedUserDefaults: mockUserDefaults
        )
    }

    override func tearDown() async throws {
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
        // Given

        let envelopeData = try JSONEncoder().encode(Scaffolding.envelope1)

        // When

        try await sut.persistEventEnvelope(
            envelopeData,
            index: 1
        )

        // Then

        try await context.perform { [context] in
            let request = StoredUpdateEventEnvelope.sortedFetchRequest(asending: true)
            let storedEventEnvelope = try XCTUnwrap(context.fetch(request).first)
            let decodedEnvelope = try JSONDecoder().decode(UpdateEventEnvelope.self, from: storedEventEnvelope.data)

            XCTAssertEqual(decodedEnvelope.id, Scaffolding.envelope1.id)
            XCTAssertEqual(decodedEnvelope.events, Scaffolding.envelope1.events)
        }
    }

    func testFetchStoredEventEnvelopePayloads_It_Fetches_No_Envelopes_If_There_Are_None() async throws {
        // Given no stored events.

        // When

        let fetchedEnvelopes = try await sut.fetchStoredEventEnvelopePayloads(limit: 3)

        // Then it returns no envelopes.

        XCTAssertTrue(fetchedEnvelopes.isEmpty)
    }

    func testFetchStoredEventEnvelopePayloads_It_Fetches_Less_Than_The_Limit_If_There_Are_Not_Enough_Envelopes(
    ) async throws {
        // Given there are stored envelopes.

        try await insertStoredEventEnvelopes([Scaffolding.envelope3])

        // When

        let fetchedEnvelopes = try await sut.fetchStoredEventEnvelopePayloads(limit: 3)

        // Then it returns the one and only envelope.

        let fetchedEnvelope1 = try JSONDecoder().decode(UpdateEventEnvelope.self, from: fetchedEnvelopes[0])

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

        let fetchedEnvelopes = try await sut.fetchStoredEventEnvelopePayloads(limit: 3)

        // Then the first 3 envelopes were returned.

        guard fetchedEnvelopes.count == 3 else {
            XCTFail("expected 3 envelopes, got \(fetchedEnvelopes.count)")
            return
        }

        let fetchedEnvelope1 = try JSONDecoder().decode(UpdateEventEnvelope.self, from: fetchedEnvelopes[0])
        let fetchedEnvelope2 = try JSONDecoder().decode(UpdateEventEnvelope.self, from: fetchedEnvelopes[1])
        let fetchedEnvelope3 = try JSONDecoder().decode(UpdateEventEnvelope.self, from: fetchedEnvelopes[2])

        XCTAssertEqual(fetchedEnvelope1, Scaffolding.envelope3)
        XCTAssertEqual(fetchedEnvelope2, Scaffolding.envelope4)
        XCTAssertEqual(fetchedEnvelope3, Scaffolding.envelope1)
    }

    func testDeleteNextPendingEvents_It_Deletes_All_Stored_Envelopes_If_Limit_Exceeds_Total_Number_Of_Envelopes(
    ) async throws {
        // Given there are stored envelopes.

        try await insertStoredEventEnvelopes([
            Scaffolding.envelope1,
            Scaffolding.envelope2,
            Scaffolding.envelope3
        ])

        // When it deletes more than 3.

        try await sut.deleteNextPendingEvents(limit: 10)

        // Then all stored events were deleted.

        try await context.perform { [context] in
            let request = StoredUpdateEventEnvelope.fetchRequest()
            let result = try context.fetch(request)
            XCTAssertTrue(result.isEmpty)
        }
    }

    func testDeleteNextPendingEvents_It_Deletes_Stored_Envelopes_Only_Up_To_The_Limit() async throws {
        // Given there are stored envelopes.

        try await insertStoredEventEnvelopes([
            Scaffolding.envelope1,
            Scaffolding.envelope2,
            Scaffolding.envelope3
        ])

        // When it deletes 2 envelopes.

        try await sut.deleteNextPendingEvents(limit: 2)

        // Then the first 2 envelopes were deleted.

        try await context.perform { [context] in
            let request = StoredUpdateEventEnvelope.sortedFetchRequest(asending: true)
            let result = try context.fetch(request)

            XCTAssertEqual(result.count, 1)

            let envelope = try XCTUnwrap(result.first)
            XCTAssertEqual(envelope.sortIndex, 2)

            let decoder = JSONDecoder()
            let decodedEnvelope = try decoder.decode(UpdateEventEnvelope.self, from: envelope.data)
            XCTAssertEqual(decodedEnvelope, Scaffolding.envelope3)
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

    private func insertStoredEventEnvelopes(_ envelopes: [UpdateEventEnvelope]) async throws {
        try await context.perform { [context] in
            let encoder = JSONEncoder()

            for (index, envelope) in envelopes.enumerated() {
                let storedEventEnvelope = StoredUpdateEventEnvelope(context: context)
                storedEventEnvelope.data = try encoder.encode(envelope)
                storedEventEnvelope.sortIndex = Int64(index)
            }

            try context.save()
        }
    }

    private enum Scaffolding {

        static let localDomain = "local.com"
        static let selfUserID = UserID(uuid: .mockID1, domain: localDomain)
        static let selfClientID = "abcd1234"
        static let conversationID = ConversationID(uuid: .mockID2, domain: localDomain)
        static let lastEventID = UUID.mockID3
        static let otherDomain = "other.com"
        static let aliceID = UserID(uuid: .mockID4, domain: otherDomain)
        static let aliceClientID = "efgh5678"
        static let defaultsTestSuiteName = UUID().uuidString

        static let id1 = UUID.mockID1
        static let id2 = UUID.mockID2
        static let id3 = UUID.mockID3
        static let id4 = UUID.mockID4
        static let id5 = UUID.mockID5

        static let time30SecondsAgo = Date(timeIntervalSinceNow: -30)
        static let time20SecondsAgo = Date(timeIntervalSinceNow: -20)

        static let lastEventIDUserDefaultsKey = "\(selfUserID.uuid.uuidString)_lastEventID"

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
