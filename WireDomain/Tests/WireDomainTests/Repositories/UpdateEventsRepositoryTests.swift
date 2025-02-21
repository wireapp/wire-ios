//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import WireAPISupport
import WireDataModel
import WireDataModelSupport
import WireTestingPackage
import XCTest
@testable import WireAPI
@testable import WireDomain
@testable import WireDomainSupport

final class UpdateEventsRepositoryTests: XCTestCase {

    private var sut: UpdateEventsRepository!
    private var updateEventsAPI: MockUpdateEventsAPI!
    private var pushChannel: MockPushChannelProtocol!
    private var updateEventDecryptor: MockUpdateEventDecryptorProtocol!
    private var updateEventsLocalStore: MockUpdateEventsLocalStoreProtocol!
    private var stack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!

    private var context: NSManagedObjectContext {
        stack.eventContext
    }

    override func setUp() async throws {
        coreDataStackHelper = CoreDataStackHelper()
        stack = try await coreDataStackHelper.createStack()
        updateEventsAPI = MockUpdateEventsAPI()
        pushChannel = MockPushChannelProtocol()
        updateEventDecryptor = MockUpdateEventDecryptorProtocol()
        updateEventsLocalStore = MockUpdateEventsLocalStoreProtocol()

        sut = UpdateEventsRepository(
            userID: Scaffolding.selfUserID.uuid,
            selfClientID: Scaffolding.selfClientID,
            updateEventsAPI: updateEventsAPI,
            pushChannel: pushChannel,
            updateEventDecryptor: updateEventDecryptor,
            updateEventsLocalStore: updateEventsLocalStore
        )

        // Base mocks
        updateEventDecryptor.decryptEventsIn_MockMethod = { $0.events }
    }

    override func tearDown() async throws {
        coreDataStackHelper = CoreDataStackHelper()
        stack = nil
        updateEventsAPI = nil
        pushChannel = nil
        updateEventDecryptor = nil
        sut = nil
        updateEventsLocalStore = nil
        try coreDataStackHelper.cleanupDirectory()
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

    // MARK: - Pull pending events

    func testPullPendingEvents_It_Throws_Error_When_Pulling_Pending_Events_Without_Last_Event_ID() async throws {
        // Mock

        updateEventsLocalStore.lastEventID_MockMethod = { nil }

        do {
            // When
            try await sut.pullPendingEvents()
            XCTFail("expected an error, but none was thrown")
        } catch PullPendingUpdateEventsSyncError.noLastEventID {
            // Then it threw the right error.
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    func testPullPendingEvents_It_Pulls_Pending_Events() async throws {
        // There is a last event id.

        updateEventsLocalStore.lastEventID_MockValue = Scaffolding.lastEventID
        updateEventsLocalStore.indexOfLastEventEnvelope_MockValue = 1
        updateEventsLocalStore.persistEventEnvelopeIndex_MockMethod = { _, _ in }
        updateEventsLocalStore.storeLastEventIDId_MockMethod = { _ in }

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

        // Then

        XCTAssertEqual(updateEventsLocalStore.persistEventEnvelopeIndex_Invocations.count, 4)
        XCTAssertEqual(updateEventsLocalStore.storeLastEventIDId_Invocations.count, 3)
        XCTAssertEqual(updateEventsLocalStore.lastEventID_Invocations.count, 1)
        XCTAssertEqual(updateEventsLocalStore.indexOfLastEventEnvelope_Invocations.count, 1)
    }

    // MARK: - Live events

    func testStartBufferingLiveEvents_It_Buffers_Live_Events_Until_Iteration_Starts() async throws {
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

    func testStoreLastEventEnvelopeID_It_Invokes_Local_Store_Method() throws {
        // Mock

        updateEventsLocalStore.storeLastEventIDId_MockMethod = { _ in }

        // When

        sut.storeLastEventEnvelopeID(Scaffolding.lastEventID)

        // Then

        XCTAssertEqual(updateEventsLocalStore.storeLastEventIDId_Invocations.count, 1)
    }

    func testPullLastEventID_It_Invokes_Local_Store_Method() async throws {
        // Mock

        updateEventsAPI.getLastUpdateEventSelfClientID_MockValue = Scaffolding.envelope1
        updateEventsLocalStore.storeLastEventIDId_MockMethod = { _ in }

        // When

        try await sut.pullLastEventID()

        // Then

        XCTAssertEqual(updateEventsLocalStore.storeLastEventIDId_Invocations.count, 1)
    }

    private enum Scaffolding {

        // MARK: - Local domain

        static let localDomain = "local.com"
        static let selfUserID = UserID(uuid: .mockID1, domain: localDomain)
        static let selfClientID = "abcd1234"
        static let conversationID = ConversationID(uuid: .mockID2, domain: localDomain)

        static let lastEventID = UUID(uuidString: "571d22a5-026c-48b4-90bf-78d00354f121")!

        // MARK: - Other domain

        static let otherDomain = "other.com"
        static let aliceID = UserID(uuid: .mockID3, domain: otherDomain)
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
            message: .init(encryptedMessage: "xxxxx"),
            externalData: nil,
            messageSenderClientID: aliceClientID,
            messageRecipientClientID: selfClientID
        )

        static let proteusMessage2 = ConversationProteusMessageAddEvent(
            conversationID: conversationID,
            senderID: aliceID,
            timestamp: time20SecondsAgo,
            message: .init(encryptedMessage: "yyyyy"),
            externalData: nil,
            messageSenderClientID: aliceClientID,
            messageRecipientClientID: selfClientID
        )

        static let proteusMessage3 = ConversationProteusMessageAddEvent(
            conversationID: conversationID,
            senderID: aliceID,
            timestamp: time10SecondsAgo,
            message: .init(encryptedMessage: "zzzzz"),
            externalData: nil,
            messageSenderClientID: aliceClientID,
            messageRecipientClientID: selfClientID
        )

        static let id1 = UUID.mockID1
        static let id2 = UUID.mockID2
        static let id3 = UUID.mockID3
        static let id4 = UUID.mockID4
        static let id5 = UUID.mockID5
        static let id6 = UUID.mockID6

        static let time30SecondsAgo = Date(timeIntervalSinceNow: -30)
        static let time20SecondsAgo = Date(timeIntervalSinceNow: -20)
        static let time10SecondsAgo = Date(timeIntervalSinceNow: -10)

        nonisolated(unsafe) static let page1 = PayloadPager<UpdateEventEnvelope>.Page(
            element: [envelope3, envelope4],
            hasMore: true,
            nextStart: "page2"
        )

        nonisolated(unsafe) static let page2 = PayloadPager<UpdateEventEnvelope>.Page(
            element: [envelope5, envelope6],
            hasMore: false,
            nextStart: ""
        )

    }

}
