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

import WireAPI
import WireAPISupport
import WireDataModel
import WireDataModelSupport
import XCTest
@testable import WireDomain
@testable import WireDomainSupport

// MARK: - UpdateEventsRepositoryTests

final class UpdateEventsRepositoryTests: XCTestCase {
    // MARK: Internal

    var sut: UpdateEventsRepository!
    var updateEventsAPI: MockUpdateEventsAPI!
    var pushChannel: MockPushChannelProtocol!
    var updateEventDecryptor: MockUpdateEventDecryptorProtocol!
    var lastEventIDRepository: MockLastEventIDRepositoryInterface!

    var stack: CoreDataStack!
    let coreDataStackHelper = CoreDataStackHelper()

    var context: NSManagedObjectContext {
        stack.eventContext
    }

    override func setUp() async throws {
        try await super.setUp()
        stack = try await coreDataStackHelper.createStack()
        updateEventsAPI = MockUpdateEventsAPI()
        pushChannel = MockPushChannelProtocol()
        updateEventDecryptor = MockUpdateEventDecryptorProtocol()
        lastEventIDRepository = MockLastEventIDRepositoryInterface()
        sut = UpdateEventsRepository(
            selfClientID: Scaffolding.selfClientID,
            updateEventsAPI: updateEventsAPI,
            pushChannel: pushChannel,
            updateEventDecryptor: updateEventDecryptor,
            eventContext: context,
            lastEventIDRepository: lastEventIDRepository
        )

        // Base mocks
        updateEventDecryptor.decryptEventsIn_MockMethod = { $0.events }
        lastEventIDRepository.storeLastEventID_MockMethod = { _ in }
    }

    override func tearDown() async throws {
        stack = nil
        updateEventsAPI = nil
        pushChannel = nil
        updateEventDecryptor = nil
        lastEventIDRepository = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        try await super.tearDown()
    }

    // MARK: - Pull pending events

    func testItThrowsErrorWhenPullingPendingEventsWithoutLastEventID() async throws {
        // Given no last event id.
        lastEventIDRepository.fetchLastEventID_MockValue = .some(nil)

        do {
            // When
            try await sut.pullPendingEvents()
            XCTFail("expected an error, but none was thrown")
        } catch UpdateEventsRepositoryError.lastEventIDMissing {
            // Then it threw the right error.
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    func testItPullPendingEvents() async throws {
        // Given some events already in the db.
        try await insertStoredEventEnvelopes([
            Scaffolding.envelope1,
            Scaffolding.envelope2,
        ])

        // There is a last event id.
        lastEventIDRepository.fetchLastEventID_MockValue = Scaffolding.lastEventID

        // There are two pages of events waiting to be pulled.
        updateEventsAPI.getUpdateEventsSelfClientIDSinceEventID_MockValue = PayloadPager(start: "page1") { start in
            switch start {
            case "page1":
                return Scaffolding.page1

            case "page2":
                return Scaffolding.page2

            default:
                throw TestError(message: "unknown page: \(start ?? "nil")")
            }
        }

        // When
        try await sut.pullPendingEvents()

        // Then we used the api to fetch pending events.
        let apiInvocations = updateEventsAPI.getUpdateEventsSelfClientIDSinceEventID_Invocations

        guard apiInvocations.count == 1 else {
            XCTFail("expected 1 invocation, got \(apiInvocations.count)")
            return
        }

        XCTAssertEqual(apiInvocations[0].selfClientID, Scaffolding.selfClientID)
        XCTAssertEqual(apiInvocations[0].sinceEventID, Scaffolding.lastEventID)

        // Then the events were decrypted, one call per envelope.
        let decryptorInvocations = updateEventDecryptor.decryptEventsIn_Invocations

        guard decryptorInvocations.count == 4 else {
            XCTFail("expected 4 invocations, got \(decryptorInvocations.count)")
            return
        }

        XCTAssertEqual(decryptorInvocations[0].id, Scaffolding.envelope3.id)
        XCTAssertEqual(decryptorInvocations[1].id, Scaffolding.envelope4.id)
        XCTAssertEqual(decryptorInvocations[2].id, Scaffolding.envelope5.id)
        XCTAssertEqual(decryptorInvocations[3].id, Scaffolding.envelope6.id)

        // Then there should now be 7 persisted events in the right order.
        try await context.perform { [context] in
            let request = StoredUpdateEventEnvelope.sortedFetchRequest(asending: true)
            let storedEventEnvelopes = try context.fetch(request)

            guard storedEventEnvelopes.count == 6 else {
                XCTFail("expected 6 stored events, got \(storedEventEnvelopes.count)")
                return
            }

            let decoder = JSONDecoder()

            let data1 = try XCTUnwrap(storedEventEnvelopes[0].data)
            let storedEnvelope1 = try decoder.decode(UpdateEventEnvelope.self, from: data1)
            XCTAssertEqual(storedEnvelope1, Scaffolding.envelope1)
            XCTAssertEqual(storedEventEnvelopes[0].sortIndex, 0)

            let data2 = try XCTUnwrap(storedEventEnvelopes[1].data)
            let storedEnvelope2 = try decoder.decode(UpdateEventEnvelope.self, from: data2)
            XCTAssertEqual(storedEnvelope2, Scaffolding.envelope2)
            XCTAssertEqual(storedEventEnvelopes[1].sortIndex, 1)

            let data3 = try XCTUnwrap(storedEventEnvelopes[2].data)
            let storedEnvelope3 = try decoder.decode(UpdateEventEnvelope.self, from: data3)
            XCTAssertEqual(storedEnvelope3, Scaffolding.envelope3)
            XCTAssertEqual(storedEventEnvelopes[2].sortIndex, 2)

            let data4 = try XCTUnwrap(storedEventEnvelopes[3].data)
            let storedEnvelope4 = try decoder.decode(UpdateEventEnvelope.self, from: data4)
            XCTAssertEqual(storedEnvelope4, Scaffolding.envelope4)
            XCTAssertEqual(storedEventEnvelopes[3].sortIndex, 3)

            let data5 = try XCTUnwrap(storedEventEnvelopes[4].data)
            let storedEnvelope5 = try decoder.decode(UpdateEventEnvelope.self, from: data5)
            XCTAssertEqual(storedEnvelope5, Scaffolding.envelope5)
            XCTAssertEqual(storedEventEnvelopes[4].sortIndex, 4)

            let data6 = try XCTUnwrap(storedEventEnvelopes[5].data)
            let storedEnvelope6 = try decoder.decode(UpdateEventEnvelope.self, from: data6)
            XCTAssertEqual(storedEnvelope6, Scaffolding.envelope6)
            XCTAssertEqual(storedEventEnvelopes[5].sortIndex, 5)
        }

        // The the last update event id was persisted for each non-transient envelope.
        let lastEventIDInvocations = lastEventIDRepository.storeLastEventID_Invocations

        guard lastEventIDInvocations.count == 3 else {
            XCTFail("expected 3 invocations, got \(lastEventIDInvocations.count)")
            return
        }

        XCTAssertEqual(lastEventIDInvocations[0], Scaffolding.id3)
        XCTAssertEqual(lastEventIDInvocations[1], Scaffolding.id5)
        XCTAssertEqual(lastEventIDInvocations[2], Scaffolding.id6)
    }

    // MARK: - Fetch next pending events

    func testItFetchesNoEnvelopesIfThereAreNone() async throws {
        // Given no stored events.

        // When
        let fetchedEnvelopes = try await sut.fetchNextPendingEvents(limit: 3)

        // Then it returns no envelopes.
        XCTAssertTrue(fetchedEnvelopes.isEmpty)
    }

    func testItFetchesLessThanTheLimitIfThereAreNotEnoughEnvelopes() async throws {
        // Given there are stored envelopes.
        try await insertStoredEventEnvelopes([Scaffolding.envelope3])

        // When
        let fetchedEnvelopes = try await sut.fetchNextPendingEvents(limit: 3)

        // Then it returns the one and only envelope.
        XCTAssertEqual(fetchedEnvelopes, [Scaffolding.envelope3])
    }

    func testItDoesNotFetchMoreThanTheLimit() async throws {
        // Given there are stored envelopes.
        try await insertStoredEventEnvelopes([
            Scaffolding.envelope3,
            Scaffolding.envelope4,
            Scaffolding.envelope1,
            Scaffolding.envelope5,
            Scaffolding.envelope2,
        ])

        // When
        let fetchedEnvelopes = try await sut.fetchNextPendingEvents(limit: 3)

        // Then the first 3 envelopes were returned.
        guard fetchedEnvelopes.count == 3 else {
            XCTFail("expected 3 envelopes, got \(fetchedEnvelopes.count)")
            return
        }

        XCTAssertEqual(fetchedEnvelopes[0], Scaffolding.envelope3)
        XCTAssertEqual(fetchedEnvelopes[1], Scaffolding.envelope4)
        XCTAssertEqual(fetchedEnvelopes[2], Scaffolding.envelope1)
    }

    // MARK: - Delete next pending events

    func testItDeletesAllStoredEnvelopesIfLimitExceedsTotalNumberOfEnvelopes() async throws {
        // Given there are stored envelopes.
        try await insertStoredEventEnvelopes([
            Scaffolding.envelope1,
            Scaffolding.envelope2,
            Scaffolding.envelope3,
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

    func testItDeletesStoredEnvelopesOnlyUpToTheLimit() async throws {
        // Given there are stored envelopes.
        try await insertStoredEventEnvelopes([
            Scaffolding.envelope1,
            Scaffolding.envelope2,
            Scaffolding.envelope3,
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

    // MARK: - Live events

    func testItBuffersLiveEventsUntilIterationStarts() async throws {
        // Mock push channel.
        var liveEventsContinuation: AsyncThrowingStream<UpdateEventEnvelope, Error>.Continuation?
        pushChannel.open_MockValue = AsyncThrowingStream {
            liveEventsContinuation = $0
        }

        // Given it starts buffering.
        let liveEventStream = try await sut.startBufferingLiveEvents()

        // Given live events arrive.
        liveEventsContinuation?.yield(Scaffolding.envelope1)
        liveEventsContinuation?.yield(Scaffolding.envelope2)
        liveEventsContinuation?.yield(Scaffolding.envelope3)

        // When iteration starts.
        let task = Task {
            var receivedEnvelopes = [UpdateEventEnvelope]()
            for try await envelope in liveEventStream {
                receivedEnvelopes.append(envelope)
            }
            return receivedEnvelopes
        }

        liveEventsContinuation?.finish()
        let receivedEnvelopes = try await task.value

        // Then all three envelopes are received.
        guard receivedEnvelopes.count == 3 else {
            XCTFail("Expected 3 envelopes, got \(receivedEnvelopes.count)")
            return
        }

        XCTAssertEqual(receivedEnvelopes[0], Scaffolding.envelope1)
        XCTAssertEqual(receivedEnvelopes[1], Scaffolding.envelope2)
        XCTAssertEqual(receivedEnvelopes[2], Scaffolding.envelope3)

        // Then each envelope was decrypted.
        let decryptionInvocations = updateEventDecryptor.decryptEventsIn_Invocations
        guard decryptionInvocations.count == 3 else {
            XCTFail("expected 4 decryption invocations, got \(decryptionInvocations.count)")
            return
        }

        XCTAssertEqual(decryptionInvocations[0], Scaffolding.envelope1)
        XCTAssertEqual(decryptionInvocations[1], Scaffolding.envelope2)
        XCTAssertEqual(decryptionInvocations[2], Scaffolding.envelope3)
    }

    func testItStoresLastEventEnvelopeID() throws {
        // Given
        let id = UUID()

        // When
        sut.storeLastEventEnvelopeID(id)

        // Then
        lastEventIDRepository.storeLastEventID_Invocations = [id]
    }

    // MARK: Private

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
}

// MARK: - Scaffolding

private enum Scaffolding {
    // MARK: - Local domain

    static let localDomain = "local.com"
    static let selfUserID = UserID(uuid: UUID(), domain: localDomain)
    static let selfClientID = "abcd1234"
    static let conversationID = ConversationID(uuid: UUID(), domain: localDomain)

    static let lastEventID = UUID(uuidString: "571d22a5-026c-48b4-90bf-78d00354f121")!

    // MARK: - Other domain

    static let otherDomain = "other.com"
    static let aliceID = UserID(uuid: UUID(), domain: otherDomain)
    static let aliceClientID = "efgh5678"

    // MARK: - Pending events

    // 6 envelopes, the first 2 will be already stored in the DB
    // and the rest will come from the backend.

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

    static let envelope6 = UpdateEventEnvelope(
        id: id6,
        events: [.conversation(.proteusMessageAdd(proteusMessage3))],
        isTransient: false
    )

    static let proteusMessage1 = ConversationProteusMessageAddEvent(
        conversationID: conversationID,
        senderID: aliceID,
        timestamp: time30SecondsAgo,
        message: .ciphertext("xxxxx"),
        externalData: nil,
        messageSenderClientID: aliceClientID,
        messageRecipientClientID: selfClientID
    )

    static let proteusMessage2 = ConversationProteusMessageAddEvent(
        conversationID: conversationID,
        senderID: aliceID,
        timestamp: time20SecondsAgo,
        message: .ciphertext("yyyyy"),
        externalData: nil,
        messageSenderClientID: aliceClientID,
        messageRecipientClientID: selfClientID
    )

    static let proteusMessage3 = ConversationProteusMessageAddEvent(
        conversationID: conversationID,
        senderID: aliceID,
        timestamp: time10SecondsAgo,
        message: .ciphertext("zzzzz"),
        externalData: nil,
        messageSenderClientID: aliceClientID,
        messageRecipientClientID: selfClientID
    )

    static let id1 = UUID(uuidString: "d92f875d-9599-4469-886e-39addaffdad7")!
    static let id2 = UUID(uuidString: "a826994f-082b-4d1e-9655-df8e1c7dccbf")!
    static let id3 = UUID(uuidString: "000e7674-6fbe-4099-b081-10c5757c37f2")!
    static let id4 = UUID(uuidString: "94d2dbb9-7a81-411d-b009-41a58cdae13b")!
    static let id5 = UUID(uuidString: "9ec9d043-150b-4b4e-b916-33bf04e8c74f")!
    static let id6 = UUID(uuidString: "9924114a-9773-436e-b1f8-b7cf32385ca2")!

    static let time30SecondsAgo = Date(timeIntervalSinceNow: -30)
    static let time20SecondsAgo = Date(timeIntervalSinceNow: -20)
    static let time10SecondsAgo = Date(timeIntervalSinceNow: -10)

    static let page1 = PayloadPager<UpdateEventEnvelope>.Page(
        element: [envelope3, envelope4],
        hasMore: true,
        nextStart: "page2"
    )

    static let page2 = PayloadPager<UpdateEventEnvelope>.Page(
        element: [envelope5, envelope6],
        hasMore: false,
        nextStart: ""
    )
}
