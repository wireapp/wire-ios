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

import XCTest
@testable import WireAPI
@testable import WireAPISupport
@testable import WireDomain
@testable import WireDomainSupport

final class IncrementalSyncTests: XCTestCase {

    var sut: IncrementalSync!
    var pushChannelAPI: MockPushChannelAPI!
    var updateEventsSync: MockPullPendingUpdateEventsSyncProtocol!
    var decryptor: MockUpdateEventDecryptorProtocol!
    var store: MockUpdateEventsLocalStoreProtocol!
    var processor: MockUpdateEventProcessorProtocol!

    override func setUp() {
        pushChannelAPI = MockPushChannelAPI()
        updateEventsSync = MockPullPendingUpdateEventsSyncProtocol()
        decryptor = MockUpdateEventDecryptorProtocol()
        store = MockUpdateEventsLocalStoreProtocol()
        processor = MockUpdateEventProcessorProtocol()
        sut = IncrementalSync(
            selfClientID: Scaffolding.selfClientID,
            pushChannelAPI: pushChannelAPI,
            updateEventsSync: updateEventsSync,
            decryptor: decryptor,
            store: store,
            processor: processor
        )
    }

    override func tearDown() {
        sut = nil
        pushChannelAPI = nil
        updateEventsSync = nil
        decryptor = nil
        store = nil
        processor = nil
    }

    func test_perform_pendingEventsExist() async throws {
        // Mock
        // Pending events are pulled.
        updateEventsSync.pull_MockMethod = {}

        // Some pending events.
        var storedEnvelopes = [
            Scaffolding.event1,
            Scaffolding.event2,
            Scaffolding.event3
        ]

        // Pendeng events are stored in batches.
        store.fetchStoredEventEnvelopesLimit_MockMethod = { _ in
            let envelopes = storedEnvelopes
            storedEnvelopes = []
            return envelopes
        }

        // Pending events are deleted in batches.
        store.deleteNextPendingEventsLimit_MockMethod = { _ in }

        // Some live events, some of which were already pulled.
        let pushChannel = MockPushChannelProtocol()
        pushChannel.open_MockValue = AsyncThrowingStream { continuation in
            Task {
                continuation.yield(Scaffolding.event2)
                continuation.yield(Scaffolding.event3)
                continuation.yield(Scaffolding.event4)
                continuation.yield(Scaffolding.event5)
                continuation.finish()
            }
        }

        pushChannelAPI.createPushChannelClientID_MockMethod = { _ in pushChannel }

        // Some indices at which live events will be stored.
        var indices = [Int64(10), 11, 12, 13, 14, 15]
        store.indexOfLastEventEnvelope_MockMethod = { indices.remove(at: 0) }

        // Live envelopes are peristed and deleted one by one.
        store.persistEventEnvelopeIndex_MockMethod = { _, _ async throws in }
        store.deleteEventEnvelopeAtIndex_MockMethod = { _ in }

        // Live events are decrypted.
        decryptor.decryptEventsIn_MockMethod = { $0.events }

        // Events are processed.
        processor.processEvent_MockMethod = { _ in }

        // When
        let token = try await sut.perform()
        await token.task.value

        // Then push channel was created.
        XCTAssertEqual(
            pushChannelAPI.createPushChannelClientID_Invocations,
            [Scaffolding.selfClientID]
        )

        // Then push channel was opened.
        XCTAssertEqual(pushChannel.open_Invocations.count, 1)

        // Then pending events were pulled.
        XCTAssertEqual(updateEventsSync.pull_Invocations.count, 1)

        // Then live events were decrypted (duplicates skipped).
        XCTAssertEqual(
            decryptor.decryptEventsIn_Invocations,
            [Scaffolding.event4, Scaffolding.event5]
        )

        // Then live events were stored (duplicates skipped).
        XCTAssertEqual(store.indexOfLastEventEnvelope_Invocations.count, 2)

        // Then live events were stored (duplicates skipped).
        let storeInvocations = store.persistEventEnvelopeIndex_Invocations
        try XCTAssertCount(storeInvocations, count: 2)
        XCTAssertEqual(storeInvocations[0].eventEnvelope, Scaffolding.event4)
        XCTAssertEqual(storeInvocations[0].index, 11)
        XCTAssertEqual(storeInvocations[1].eventEnvelope, Scaffolding.event5)
        XCTAssertEqual(storeInvocations[1].index, 12)

        // Then all events were processed once (duplicates skipped).
        XCTAssertEqual(
            processor.processEvent_Invocations,
            [
                Scaffolding.event1,
                Scaffolding.event2,
                Scaffolding.event3,
                Scaffolding.event4,
                Scaffolding.event5
            ].flatMap(\.events)
        )

        // Then pending events were deleted.
        XCTAssertEqual(store.deleteNextPendingEventsLimit_Invocations, [500])

        // Then live events were deleted (duplicates skipped).
        XCTAssertEqual(store.deleteEventEnvelopeAtIndex_Invocations, [11, 12])
    }

}

private enum Scaffolding {

    static let selfClientID = "selfClientID"

    static let event1 = createEvent(
        message: "hello",
        timeIntervalSinceNow: -10
    )

    static let event2 = createEvent(
        message: "ciao",
        timeIntervalSinceNow: -9
    )

    static let event3 = createEvent(
        message: "hola",
        timeIntervalSinceNow: -8
    )

    static let event4 = createEvent(
        message: "hallo",
        timeIntervalSinceNow: -7
    )

    static let event5 = createEvent(
        message: "bonjour",
        timeIntervalSinceNow: -6
    )

    static func createEvent(
        message: String,
        timeIntervalSinceNow: TimeInterval
    ) -> UpdateEventEnvelope {
        let event = ConversationProteusMessageAddEvent(
            conversationID: ConversationID(
                uuid: UUID(),
                domain: "example.com"
            ),
            senderID: UserID(
                uuid: UUID(),
                domain: "example.com"
            ),
            timestamp: Date(timeIntervalSinceNow: timeIntervalSinceNow),
            message: MessageContent(
                encryptedMessage: message,
                decryptedMessage: nil
            ),
            externalData: nil,
            messageSenderClientID: "senderClientID",
            messageRecipientClientID: selfClientID
        )
        return UpdateEventEnvelope(
            id: UUID(),
            events: [.conversation(.proteusMessageAdd(event))],
            isTransient: false
        )
    }

}
