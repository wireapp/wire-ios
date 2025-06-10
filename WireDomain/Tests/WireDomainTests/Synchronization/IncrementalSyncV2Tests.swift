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

import Combine
import XCTest
@testable import WireAPI
@testable import WireAPISupport
@testable import WireDomain
@testable import WireDomainSupport

final class IncrementalSyncV2Tests: XCTestCase {

    var sut: IncrementalSyncV2!
    var pushChannelAPI: MockPushChannelV2API!
    var decryptor: MockUpdateEventDecryptorProtocol!
    var store: MockUpdateEventsLocalStoreProtocol!
    var processor: MockUpdateEventProcessorProtocol!
    var databaseSaver: MockDatabaseSaverProtocol!
    var syncStateSubject: CurrentValueSubject<SyncState, Never>!
    var liveDelegate: MockLiveSyncDelegate!
    var journal: Journal!

    override func setUp() {
        pushChannelAPI = MockPushChannelV2API()
        decryptor = MockUpdateEventDecryptorProtocol()
        store = MockUpdateEventsLocalStoreProtocol()
        processor = MockUpdateEventProcessorProtocol()
        databaseSaver = MockDatabaseSaverProtocol()
        liveDelegate = MockLiveSyncDelegate()
        syncStateSubject = .init(.idle)
        journal = Journal(
            userID: UUID(),
            storage: UserDefaults.temporary()
        )

        sut = IncrementalSyncV2(
            selfClientID: Scaffolding.selfClientID,
            pushChannelAPI: pushChannelAPI,
            decryptor: decryptor,
            store: store,
            processor: processor,
            databaseSaver: databaseSaver,
            syncStateSubject: syncStateSubject,
            journal: journal
        )
        sut.delegate = liveDelegate
        liveDelegate.isUpToDateSync_MockMethod = { _ in }
        liveDelegate.didMissedEventsSync_MockMethod = { _ in }

    }

    override func tearDown() {
        sut = nil
        pushChannelAPI = nil
        decryptor = nil
        store = nil
        processor = nil
        databaseSaver = nil
        syncStateSubject = nil
        journal = nil
        liveDelegate = nil
    }

    func testPerform_pendingEventsExist() async throws {
        // Mock

        // Some live events, some of which were already pulled.
        let pushChannel = MockPushChannelV2Protocol()
        pushChannel.acknowledgeMessageCount_MockMethod = {}

        pushChannel.open_MockValue = AsyncThrowingStream { continuation in
            Task {
                continuation.yield(PushChannelV2.Element.syncing(eventsCount: 1))
                continuation.yield(PushChannelV2.Element.event(Scaffolding.event2))
                continuation.yield(PushChannelV2.Element.upToDate)
                continuation.finish()
            }
        }
        pushChannel.acknowledgeEventDeliveryTagMultiple_MockMethod = { _, _ in }
        pushChannelAPI.createPushChannelClientID_MockMethod = { _ in pushChannel }

        // Some indices at which live events will be stored.
        var indices = [Int64(10)]
        store.indexOfLastEventEnvelope_MockMethod = { indices.remove(at: 0) }

        // Live envelopes are peristed and deleted one by one.
        store.persistEventEnvelopeIndex_MockMethod = { _, _ async throws in }
        store.deleteEventEnvelopeAtIndex_MockMethod = { _ in }

        // Live events are decrypted.
        decryptor.decryptEventsInContext_MockMethod = { envelope, _ in
            EventDecryptorResult(events: envelope.events, brokenMLSGroupIDs: [Scaffolding.mlsGroupID])
        }

        // Last event is being updated.
        store.storeLastEventIDId_MockMethod = { _ in }

        // Events are processed.
        processor.processEvent_MockMethod = { _ in }

        // Unread messages are set
        store.calculateLastUnreadMessages_MockMethod = {}

        // Database is saved.
        databaseSaver.save_MockMethod = {}

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

        // Then live events were decrypted (duplicates skipped).
        XCTAssertEqual(
            decryptor.decryptEventsInContext_Invocations.map(\.eventEnvelope),
            [Scaffolding.event2]
        )

        // Then sync is up to date
        XCTAssertEqual(liveDelegate.isUpToDateSync_Invocations.count, 1)
        XCTAssertEqual(pushChannel.acknowledgeMessageCount_Invocations.count, 1)

        // Then live events were stored.
        XCTAssertEqual(store.indexOfLastEventEnvelope_Invocations.count, 1)

        // Broken conversation IDs are stored
        XCTAssertEqual(journal[.brokenMLSGroupIDs].first, Scaffolding.mlsGroupID)

        // Then live events were stored.
        let storeInvocations = store.persistEventEnvelopeIndex_Invocations
        try XCTAssertCount(storeInvocations, count: 1)
        XCTAssertEqual(storeInvocations[0].eventEnvelope, Scaffolding.event2)
        XCTAssertEqual(storeInvocations[0].index, 11)

        // Then ack of events done adter storing
        XCTAssertEqual(pushChannel.acknowledgeEventDeliveryTagMultiple_Invocations.count, 1)

        // Then all events were processed once.
        XCTAssertEqual(
            processor.processEvent_Invocations,
            [
                Scaffolding.event2
            ].flatMap(\.events)
        )

        // Then live events were deleted.
        XCTAssertEqual(store.deleteEventEnvelopeAtIndex_Invocations, [11])

        // Then unread messages are calculated once after processing pending events
        // and once after processing each live event.
        XCTAssertEqual(store.calculateLastUnreadMessages_Invocations.count, 1)

        // Then the database was saved once after processing pending events
        // and once after processing each live event.
        XCTAssertEqual(databaseSaver.save_Invocations.count, 1)
    }

    func testPerform_AcknowledgementFullSync() async throws {
        // Mock
        let pushChannel = MockPushChannelV2Protocol()
        pushChannel.acknowledgeFullSync_MockMethod = {}

        pushChannel.open_MockValue = AsyncThrowingStream { continuation in
            Task {
                continuation.yield(.event(Scaffolding.event2))
                continuation.yield(.event(Scaffolding.event3))
                continuation.yield(.missedEvents)
                continuation.finish()
            }
        }
        pushChannel.acknowledgeEventDeliveryTagMultiple_MockMethod = { _, _ in }
        pushChannelAPI.createPushChannelClientID_MockMethod = { _ in pushChannel }

        // Some indices at which live events will be stored.
        var indices = [Int64(10), 11]
        store.indexOfLastEventEnvelope_MockMethod = { indices.remove(at: 0) }

        // Live envelopes are peristed and deleted one by one.
        store.persistEventEnvelopeIndex_MockMethod = { _, _ async throws in }
        store.deleteEventEnvelopeAtIndex_MockMethod = { _ in }

        // Live events are decrypted.
        decryptor.decryptEventsInContext_MockMethod = { envelope, _ in
            EventDecryptorResult(events: envelope.events, brokenMLSGroupIDs: [])
        }

        // Last event is being updated.
        store.storeLastEventIDId_MockMethod = { _ in }

        // Events are processed.
        processor.processEvent_MockMethod = { _ in }

        // Unread messages are set
        store.calculateLastUnreadMessages_MockMethod = {}

        // Database is saved.
        databaseSaver.save_MockMethod = {}

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

        // Then live events were decrypted (duplicates skipped).
        XCTAssertEqual(
            decryptor.decryptEventsInContext_Invocations.map(\.eventEnvelope),
            [Scaffolding.event2, Scaffolding.event3]
        )

        // Then live events were stored.
        XCTAssertEqual(store.indexOfLastEventEnvelope_Invocations.count, 2)

        // Then live events were stored.
        let storeInvocations = store.persistEventEnvelopeIndex_Invocations
        try XCTAssertCount(storeInvocations, count: 2)
        XCTAssertEqual(storeInvocations[0].eventEnvelope, Scaffolding.event2)
        XCTAssertEqual(storeInvocations[1].eventEnvelope, Scaffolding.event3)
        // Then ack of events done after storing
        XCTAssertEqual(pushChannel.acknowledgeEventDeliveryTagMultiple_Invocations.count, 2)

        // Then all events were processed once.
        XCTAssertEqual(
            processor.processEvent_Invocations,
            [
                Scaffolding.event2,
                Scaffolding.event3
            ].flatMap(\.events)
        )

        XCTAssertEqual(liveDelegate.didMissedEventsSync_Invocations.count, 1)

        // Then live events were deleted.
        XCTAssertEqual(store.deleteEventEnvelopeAtIndex_Invocations, [11, 12])

        // Then unread messages are calculated once after processing pending events
        // and once after processing each live event.
        XCTAssertEqual(store.calculateLastUnreadMessages_Invocations.count, 2)

        // Then the database was saved once after processing pending events
        // and once after processing each live event.
        XCTAssertEqual(databaseSaver.save_Invocations.count, 2)
    }

}

private enum Scaffolding {

    static let selfClientID = "selfClientID"
    static let mlsGroupID = "ASDF"

    static let event2 = createEvent(
        message: "ciao",
        timeIntervalSinceNow: -9,
        deliveryTag: 2
    )

    static let event3 = createEvent(
        message: "hola",
        timeIntervalSinceNow: -8,
        deliveryTag: 3
    )

    static let event4 = createEvent(
        message: "hallo",
        timeIntervalSinceNow: -7,
        deliveryTag: 4
    )

    static let event5 = createEvent(
        message: "bonjour",
        timeIntervalSinceNow: -6,
        deliveryTag: 5
    )

    static func createEvent(
        message: String,
        timeIntervalSinceNow: TimeInterval,
        deliveryTag: UInt64? = nil
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
            isTransient: false,
            deliveryTag: deliveryTag
        )
    }

}
