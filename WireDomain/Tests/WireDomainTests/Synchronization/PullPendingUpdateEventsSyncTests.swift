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

import WireNetworkSupport
import XCTest
@testable import WireDataModelSupport
@testable import WireDomain
@testable import WireDomainSupport
@testable import WireNetwork

final class PullPendingUpdateEventsSyncTests: XCTestCase {

    private var sut: PullPendingUpdateEventsSync!
    private var journal: Journal!
    private var api: MockUpdateEventsAPI!
    private var store: MockUpdateEventsLocalStoreProtocol!
    private var decryptor: MockUpdateEventDecryptorProtocol!
    private var envelope: CoreCryptoMocksEnvelope!

    override func setUp() async throws {
        journal = Journal(
            userID: UUID(),
            storage: UserDefaults.temporary()
        )
        api = MockUpdateEventsAPI()
        store = MockUpdateEventsLocalStoreProtocol()
        decryptor = MockUpdateEventDecryptorProtocol()
        envelope = CoreCryptoMocksEnvelope()

        sut = PullPendingUpdateEventsSync(
            selfClientID: Scaffolding.selfClientID,
            api: api,
            store: store,
            journal: journal,
            decryptor: decryptor,
            coreCryptoProvider: envelope.coreCryptoProvider
        )
    }

    override func tearDown() async throws {
        envelope = nil
        api = nil
        store = nil
        decryptor = nil
        journal = nil
        sut = nil
    }

    func testPull() async throws {
        // Mock
        store.lastEventID_MockValue = Scaffolding.lastEventID
        store.indexOfLastEventEnvelope_MockValue = Scaffolding.indexOfLastEventEnvelope

        api.getUpdateEventsSelfClientIDSinceEventID_MockValue = PayloadPager(start: "page1") { start in
            switch start {
            case "page1":
                return Scaffolding.page1

            case "page2":
                return Scaffolding.page2

            default:
                throw "unknown page: \(start ?? "nil")"
            }
        }

        decryptor.decryptEventsInContext_MockMethod = { envelope, _ in
            EventDecryptorResult(events: envelope.events, brokenMLSGroupIDs: [Scaffolding.mlsGroupID])
        }

        store.persistEventEnvelopesIndexPublicKeys_MockMethod = { _, _, _ in }
        store.storeLastEventIDId_MockMethod = { _ in }
        store.storeServerTimeDelta_MockMethod = { _ in }

        // When
        try await sut.pull(publicKeys: nil)

        // Then we used the api to fetch pending events.
        let apiInvocations = api.getUpdateEventsSelfClientIDSinceEventID_Invocations
        try XCTAssertCount(apiInvocations, count: 1)
        XCTAssertEqual(apiInvocations[0].selfClientID, Scaffolding.selfClientID)
        XCTAssertEqual(apiInvocations[0].sinceEventID, Scaffolding.lastEventID)

        // Then the events were decrypted, one call per envelope.
        let decryptorInvocations = decryptor.decryptEventsInContext_Invocations
        try XCTAssertCount(decryptorInvocations, count: 4)
        XCTAssertEqual(decryptorInvocations[0].eventEnvelope.id, Scaffolding.envelope1.id)
        XCTAssertEqual(decryptorInvocations[1].eventEnvelope.id, Scaffolding.envelope2.id)
        XCTAssertEqual(decryptorInvocations[2].eventEnvelope.id, Scaffolding.envelope3.id)
        XCTAssertEqual(decryptorInvocations[3].eventEnvelope.id, Scaffolding.envelope4.id)

        // Then the events were stored at correct indices.
        let persistInvocactions = store.persistEventEnvelopesIndexPublicKeys_Invocations
        try XCTAssertCount(persistInvocactions, count: 2)
        XCTAssertEqual(persistInvocactions[0].index, Scaffolding.indexOfLastEventEnvelope + 1)
        XCTAssertEqual(persistInvocactions[1].index, Scaffolding.indexOfLastEventEnvelope + 1)

        // Then the last event id was updated for all envelopes that aren't transient (envelope 2)
        let storeLastEventIDInvocations = store.storeLastEventIDId_Invocations
        try XCTAssertCount(storeLastEventIDInvocations, count: 2)
        XCTAssertEqual(storeLastEventIDInvocations[0], Scaffolding.envelope1.id)
        XCTAssertEqual(storeLastEventIDInvocations[1], Scaffolding.envelope4.id)
        XCTAssertEqual(journal[.brokenMLSGroupIDs].first, Scaffolding.mlsGroupID)
    }

    func testLastEventIDIsNotPersisted_untilTransactionIsCompleted() async throws {
        // Mock
        store.lastEventID_MockValue = Scaffolding.lastEventID
        store.indexOfLastEventEnvelope_MockValue = Scaffolding.indexOfLastEventEnvelope

        api.getUpdateEventsSelfClientIDSinceEventID_MockValue = PayloadPager(start: "page2") { start in
            switch start {
            case "page2":
                return Scaffolding.page2

            default:
                throw "unknown page: \(start ?? "nil")"
            }
        }

        decryptor.decryptEventsInContext_MockMethod = { envelope, _ in
            EventDecryptorResult(events: envelope.events, brokenMLSGroupIDs: [Scaffolding.mlsGroupID])
        }

        store.persistEventEnvelopesIndexPublicKeys_MockMethod = { _, _, _ in }
        store.storeLastEventIDId_MockMethod = { _ in }
        store.storeServerTimeDelta_MockMethod = { _ in }

        envelope.setCompleteTransactionByDefault(false)

        // When
        let pullingEventsTask = Task { [sut] in
            try await sut.pull(publicKeys: nil)
        }

        // we wait until the sync tries to commit the batch of decrypted events
        try await envelope.waitUntilTransactionIsPending()

        // Then
        try XCTAssertCount(store.storeLastEventIDId_Invocations, count: 0)

        // complete all transaction
        envelope.completeAllTransactions()

        _ = await pullingEventsTask.result

        // after allowing the transaction to complete we should we see
        // that the last event ID got persisted
        let storeLastEventIDInvocations = store.storeLastEventIDId_Invocations
        try XCTAssertCount(storeLastEventIDInvocations, count: 1)
        XCTAssertEqual(storeLastEventIDInvocations[0], Scaffolding.envelope4.id)
    }

}

private enum Scaffolding {

    static let localDomain = "wire.com"
    static let selfUserID = UserID(id: UUID(), domain: localDomain)
    static let selfClientID = "abcd1234"
    static let conversationID = ConversationID(id: UUID(), domain: localDomain)
    static let mlsGroupID = "ASDF"

    static let otherDomain = "other.com"
    static let aliceID = UserID(id: .mockID3, domain: otherDomain)
    static let aliceClientID = "efgh5678"

    static let lastEventID = UUID()
    static let indexOfLastEventEnvelope: Int64 = 100

    static let envelope1 = UpdateEventEnvelope(
        id: UUID(),
        events: [.conversation(.proteusMessageAdd(proteusMessage1))],
        isTransient: false
    )

    static let envelope2 = UpdateEventEnvelope(
        id: UUID(),
        events: [.user(.pushRemove)],
        isTransient: true
    )

    static let envelope3 = UpdateEventEnvelope(
        id: UUID(),
        events: [.conversation(.proteusMessageAdd(proteusMessage2))],
        isTransient: false
    )

    static let envelope4 = UpdateEventEnvelope(
        id: UUID(),
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

    static let time30SecondsAgo = Date(timeIntervalSinceNow: -30)
    static let time20SecondsAgo = Date(timeIntervalSinceNow: -20)
    static let time10SecondsAgo = Date(timeIntervalSinceNow: -10)

    nonisolated(unsafe) static let page1 = PayloadPager<UpdateEventBatch>.Page(
        element: .init(time: .now, updateEventEnvelopes: [envelope1, envelope2]),
        hasMore: true,
        nextStart: "page2"
    )

    nonisolated(unsafe) static let page2 = PayloadPager<UpdateEventBatch>.Page(
        element: .init(time: .now, updateEventEnvelopes: [envelope3, envelope4]),
        hasMore: false,
        nextStart: ""
    )

}
