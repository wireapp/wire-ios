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

final class IncrementalSyncTests: XCTestCase {

    var sut: IncrementalSync!
    var pushChannelAPI: MockPushChannelAPI!
    var updateEventsSync: MockPullPendingUpdateEventsSyncProtocol!
    var decryptor: MockUpdateEventDecryptorProtocol!
    var updateEventsStore: MockUpdateEventsLocalStoreProtocol!
    var messageStore: MockMessageLocalStoreProtocol!
    var processor: MockUpdateEventProcessorProtocol!
    var databaseSaver: MockDatabaseSaverProtocol!
    var syncStateSubject: CurrentValueSubject<SyncState, Never>!
    var didCallMissedEventsCallback = false

    override func setUp() {
        pushChannelAPI = MockPushChannelAPI()
        updateEventsSync = MockPullPendingUpdateEventsSyncProtocol()
        decryptor = MockUpdateEventDecryptorProtocol()
        updateEventsStore = MockUpdateEventsLocalStoreProtocol()
        messageStore = MockMessageLocalStoreProtocol()
        processor = MockUpdateEventProcessorProtocol()
        databaseSaver = MockDatabaseSaverProtocol()
        syncStateSubject = CurrentValueSubject(.idle)
        sut = IncrementalSync(
            selfClientID: Scaffolding.selfClientID,
            pushChannelAPI: pushChannelAPI,
            updateEventsSync: updateEventsSync,
            decryptor: decryptor,
            updateEventsStore: updateEventsStore,
            messageStore: messageStore,
            processor: processor,
            databaseSaver: databaseSaver,
            syncStateSubject: syncStateSubject,
            onMissedEvents: { self.didCallMissedEventsCallback = true }
        )
    }

    override func tearDown() {
        sut = nil
        pushChannelAPI = nil
        updateEventsSync = nil
        decryptor = nil
        updateEventsStore = nil
        messageStore = nil
        processor = nil
        databaseSaver = nil
        syncStateSubject = nil
    }

    func test_perform_pendingEventsExist() async throws {
        // Mock
        // Pending events are pulled.
        updateEventsSync.pull_MockMethod = { AsyncStream { [] } }

        // Some pending events.
        var storedEnvelopes = [
            Scaffolding.event1,
            Scaffolding.event2,
            Scaffolding.event3
        ]

        // Pendeng events are stored in batches.
        updateEventsStore.fetchStoredEventEnvelopesLimit_MockMethod = { _ in
            let envelopes = storedEnvelopes
            storedEnvelopes = []
            return envelopes
        }

        // Pending events are deleted in batches.
        updateEventsStore.deleteNextPendingEventsLimit_MockMethod = { _ in }

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
        updateEventsStore.indexOfLastEventEnvelope_MockMethod = { indices.remove(at: 0) }

        // Live envelopes are peristed and deleted one by one.
        updateEventsStore.persistEventEnvelopeIndex_MockMethod = { _, _ async throws in }
        updateEventsStore.deleteEventEnvelopeAtIndex_MockMethod = { _ in }

        // Live events are decrypted.
        decryptor.decryptEventsIn_MockMethod = { $0.events }

        // Last event is being updated.
        updateEventsStore.storeLastEventIDId_MockMethod = { _ in }

        // Events are processed.
        processor.processEvent_MockMethod = { _ in }

        // Unread messages are set
        updateEventsStore.calculateLastUnreadMessages_MockMethod = {}

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

        // Then pending events were pulled.
        XCTAssertEqual(updateEventsSync.pull_Invocations.count, 1)

        // Then live events were decrypted (duplicates skipped).
        XCTAssertEqual(
            decryptor.decryptEventsIn_Invocations,
            [Scaffolding.event4, Scaffolding.event5]
        )

        // Then live events were stored (duplicates skipped).
        XCTAssertEqual(updateEventsStore.indexOfLastEventEnvelope_Invocations.count, 2)

        let storeInvocations = updateEventsStore.persistEventEnvelopeIndex_Invocations
        try XCTAssertCount(storeInvocations, count: 2)
        XCTAssertEqual(storeInvocations[0].eventEnvelope, Scaffolding.event4)
        XCTAssertEqual(storeInvocations[0].index, 11)
        XCTAssertEqual(storeInvocations[1].eventEnvelope, Scaffolding.event5)
        XCTAssertEqual(storeInvocations[1].index, 12)

        // Then last event id was updated once (for the non-transient live
        // event)
        try XCTAssertCount(updateEventsStore.storeLastEventIDId_Invocations, count: 1)
        XCTAssertEqual(updateEventsStore.storeLastEventIDId_Invocations[0], Scaffolding.event5.id)

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
        XCTAssertEqual(updateEventsStore.deleteNextPendingEventsLimit_Invocations, [500])

        // Then live events were deleted (duplicates skipped).
        XCTAssertEqual(updateEventsStore.deleteEventEnvelopeAtIndex_Invocations, [11, 12])

        // Then unread messages are calculated once after processing pending events
        // and once after processing each live event.
        XCTAssertEqual(updateEventsStore.calculateLastUnreadMessages_Invocations.count, 3)

        // Then the database was saved once after processing pending events
        // and once after processing each live event.
        XCTAssertEqual(databaseSaver.save_Invocations.count, 3)
    }

    func test_perform_Cancelled_Push_Channel_Closed() async throws {
        // Mock
        // Pending events are pulled.
        updateEventsSync.pull_MockMethod = { AsyncStream { [] } }

        // Some pending events.
        var storedEnvelopes = [
            Scaffolding.event1,
            Scaffolding.event2,
            Scaffolding.event3
        ]

        // Pendeng events are stored in batches.
        updateEventsStore.fetchStoredEventEnvelopesLimit_MockMethod = { _ in
            let envelopes = storedEnvelopes
            storedEnvelopes = []
            return envelopes
        }

        // Pending events are deleted in batches.
        updateEventsStore.deleteNextPendingEventsLimit_MockMethod = { _ in }

        // Some live events, some of which were already pulled.
        let pushChannel = MockPushChannelProtocol()
        let liveEventsStream = AsyncThrowingStream { continuation in
            Task {
                continuation.yield(Scaffolding.event2)
                continuation.yield(Scaffolding.event3)
                continuation.yield(Scaffolding.event4)
                continuation.yield(Scaffolding.event5)
                continuation.finish()
            }
        }
        pushChannel.open_MockValue = liveEventsStream
        pushChannelAPI.createPushChannelClientID_MockMethod = { _ in pushChannel }
        // Some indices at which live events will be stored.
        var indices = [Int64(10), 11, 12, 13, 14, 15]
        updateEventsStore.indexOfLastEventEnvelope_MockMethod = { indices.remove(at: 0) }

        // Live envelopes are peristed and deleted one by one.
        updateEventsStore.persistEventEnvelopeIndex_MockMethod = { _, _ async throws in }
        updateEventsStore.deleteEventEnvelopeAtIndex_MockMethod = { _ in }

        // Live events are decrypted.
        decryptor.decryptEventsIn_MockMethod = { $0.events }

        // Last event is being updated.
        updateEventsStore.storeLastEventIDId_MockMethod = { _ in }

        // Events are processed.
        processor.processEvent_MockMethod = { _ in }

        // Unread messages are set
        updateEventsStore.calculateLastUnreadMessages_MockMethod = {}

        // Database is saved.
        databaseSaver.save_MockMethod = {}
        pushChannel.close_MockMethod = {}

        // When
        let task = Task {
            try await sut.perform()
        }

        // Then
        do {
            _ = try await task.value
        } catch {
            XCTAssertEqual(pushChannel.close_Invocations.count, 1)
            XCTAssertTrue(error is CancellationError)
        }
    }

    func test_perform_Missed_Events() async throws {
        // Mock
        let pushChannel = MockPushChannelProtocol()
        pushChannel.open_MockValue = AsyncThrowingStream { _ in [] }
        pushChannel.close_MockMethod = {}
        pushChannelAPI.createPushChannelClientID_MockMethod = { _ in pushChannel }
        updateEventsSync.pull_MockError = UpdateEventsAPIError.notFound
        messageStore.addPotentialGapSystemMessage_MockMethod = {}

        await XCTAssertThrowsErrorAsync(UpdateEventsAPIError.notFound) {
            // When
            try await self.sut.perform()
        }

        // Then
        XCTAssertEqual(didCallMissedEventsCallback, true)
        XCTAssertEqual(messageStore.addPotentialGapSystemMessage_Invocations.count, 1)
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
        timeIntervalSinceNow: -7,
        isTransient: true
    )

    static let event5 = createEvent(
        message: "bonjour",
        timeIntervalSinceNow: -6
    )

    static func createEvent(
        message: String,
        timeIntervalSinceNow: TimeInterval,
        isTransient: Bool = false
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
            isTransient: isTransient
        )
    }

}
