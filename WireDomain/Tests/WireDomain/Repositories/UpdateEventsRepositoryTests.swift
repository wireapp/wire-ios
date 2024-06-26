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

final class UpdateEventsRepositoryTests: XCTestCase {

    var sut: UpdateEventsRepository!
    var eventsAPI: MockUpdateEventsAPI!
    var eventDecryptor: MockUpdateEventDecryptorProtocol!
    var lastEventIDRepository: MockLastEventIDRepositoryInterface!

    var stack: CoreDataStack!
    let coreDataStackHelper = CoreDataStackHelper()

    var context: NSManagedObjectContext {
        stack.eventContext
    }

    override func setUp() async throws {
        try await super.setUp()
        stack = try await coreDataStackHelper.createStack()
        eventsAPI = MockUpdateEventsAPI()
        eventDecryptor = MockUpdateEventDecryptorProtocol()
        lastEventIDRepository = MockLastEventIDRepositoryInterface()
        sut = UpdateEventsRepository(
            selfClientID: Scaffolding.selfClientID,
            eventsAPI: eventsAPI,
            eventDecryptor: eventDecryptor,
            eventContext: context,
            lastEventIDRepository: lastEventIDRepository
        )

        // Base mocks
        eventDecryptor.decryptEventsIn_MockMethod = { $0.events }
        lastEventIDRepository.storeLastEventID_MockMethod = { _ in }
    }

    override func tearDown() async throws {
        stack = nil
        eventsAPI = nil
        eventDecryptor = nil
        lastEventIDRepository = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        try await super.tearDown()
    }

    private func insertStoredEventEnvelopes() async throws {
        try await context.perform { [context] in
            let encoder = JSONEncoder()

            let storedEventEnvelope1 = StoredEventEnvelope(context: context)
            storedEventEnvelope1.data = try encoder.encode(Scaffolding.envelope1)
            storedEventEnvelope1.sortIndex = 0

            let storedEventEnvelope2 = StoredEventEnvelope(context: context)
            storedEventEnvelope2.data = try encoder.encode(Scaffolding.envelope2)
            storedEventEnvelope2.sortIndex = 1

            try context.save()
        }
    }

    // MARK: - Tests

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
        try await insertStoredEventEnvelopes()

        // There is a last event id.
        lastEventIDRepository.fetchLastEventID_MockValue = Scaffolding.lastEventID

        // There are two pages of events waiting to be pulled.
        eventsAPI.getUpdateEventsSelfClientIDSinceEventID_MockValue = PayloadPager(start: "page1") { start in
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
        let apiInvocations = eventsAPI.getUpdateEventsSelfClientIDSinceEventID_Invocations

        guard apiInvocations.count == 1 else {
            XCTFail("expected 1 invocation, got \(apiInvocations.count)")
            return
        }

        XCTAssertEqual(apiInvocations[0].selfClientID, Scaffolding.selfClientID)
        XCTAssertEqual(apiInvocations[0].sinceEventID, Scaffolding.lastEventID)

        // Then the events were decrypted, one call per envelope.
        let decryptorInvocations = eventDecryptor.decryptEventsIn_Invocations

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
            let request = StoredEventEnvelope.sortedFetchRequest(asending: true)
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

}

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
