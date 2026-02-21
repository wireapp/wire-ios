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

import Combine
import CoreData
import XCTest
@testable import WireDataModel
@testable import WireDataModelSupport
@testable import WireDomain
@testable import WireDomainSupport
@testable import WireNetwork
@testable import WireNetworkSupport

private class MockNotificationContext: NSObject, NotificationContext {}

final class IncrementalSyncTests: XCTestCase {

    var sut: IncrementalSync!
    var journal: Journal!
    var pushChannelAPI: MockPushChannelAPI!
    var updateEventsSync: MockPullPendingUpdateEventsSyncProtocol!
    var decryptor: MockUpdateEventDecryptorProtocol!
    var updateEventsStore: MockUpdateEventsLocalStoreProtocol!
    var messageLocalStore: MockMessageLocalStoreProtocol!
    var processor: MockUpdateEventProcessorProtocol!
    var databaseSaver: MockDatabaseSaverProtocol!
    var syncStateSubject: CurrentValueSubject<SyncState, Never>!
    var liveBrokenGroupSubject: PassthroughSubject<Set<String>, Never>!
    var mlsGroupRepairAgent: MockMLSGroupRepairAgentProtocol!
    var cancellables: Set<AnyCancellable>!
    var earService: MockEARServiceInterface!
    fileprivate var notificationContext: MockNotificationContext!

    override func setUp() {
        journal = Journal(
            userID: UUID(),
            storage: UserDefaults.temporary()
        )
        pushChannelAPI = MockPushChannelAPI()
        updateEventsSync = MockPullPendingUpdateEventsSyncProtocol()
        decryptor = MockUpdateEventDecryptorProtocol()
        updateEventsStore = MockUpdateEventsLocalStoreProtocol()
        messageLocalStore = MockMessageLocalStoreProtocol()
        processor = MockUpdateEventProcessorProtocol()
        databaseSaver = MockDatabaseSaverProtocol()
        syncStateSubject = CurrentValueSubject(.idle)
        liveBrokenGroupSubject = PassthroughSubject()
        mlsGroupRepairAgent = MockMLSGroupRepairAgentProtocol()
        cancellables = Set<AnyCancellable>()
        earService = MockEARServiceInterface()
        notificationContext = MockNotificationContext()

        earService.underlyingIsLocked = false
        earService.fetchPublicKeys_MockMethod = { nil }
        earService.fetchPrivateKeysIncludingPrimary_MockMethod = { _ in nil }

        sut = IncrementalSync(
            selfClientID: Scaffolding.selfClientID,
            pushChannelAPI: pushChannelAPI,
            updateEventsSync: updateEventsSync,
            decryptor: decryptor,
            updateEventsStore: updateEventsStore,
            messageStore: messageLocalStore,
            processor: processor,
            databaseSaver: databaseSaver,
            syncStateSubject: syncStateSubject,
            liveBrokenGroupSubject: liveBrokenGroupSubject,
            journal: journal,
            mlsGroupRepairAgent: mlsGroupRepairAgent,
            earService: earService
        )
    }

    override func tearDown() {
        sut = nil
        journal = nil
        pushChannelAPI = nil
        updateEventsSync = nil
        decryptor = nil
        updateEventsStore = nil
        messageLocalStore = nil
        processor = nil
        databaseSaver = nil
        syncStateSubject = nil
        liveBrokenGroupSubject = nil
        mlsGroupRepairAgent = nil
        cancellables = nil
    }

    func test_perform_pendingEventsExist() async throws {
        // Mock
        // Pending events are pulled.
        updateEventsSync.pullPublicKeys_MockMethod = { _ in AsyncStream { [] } }

        // Some pending events.
        let managedObjectID1 = NSManagedObjectID()
        let managedObjectID2 = NSManagedObjectID()
        let managedObjectID3 = NSManagedObjectID()

        var storedEnvelopes = [
            (Scaffolding.event1, managedObjectID1),
            (Scaffolding.event2, managedObjectID2),
            (Scaffolding.event3, managedObjectID3)
        ]

        // Pending events are stored in batches.
        updateEventsStore.fetchStoredEventEnvelopesLimitPrivateKeysBackgroundAccessibleOnly_MockMethod = { _, _, _ in
            let envelopes = storedEnvelopes
            storedEnvelopes = []
            return envelopes
        }

        // Pending events are deleted in batches.
        updateEventsStore.deleteNextPendingEventsWith_MockMethod = { _ in }

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
        updateEventsStore.persistEventEnvelopeIndexPublicKeys_MockMethod = { _, _, _ async throws in }
        updateEventsStore.deleteEventEnvelopeAtIndex_MockMethod = { _ in }

        // Live events are decrypted.
        decryptor.decryptEventsInContext_MockMethod = { envelope, _ in
            EventDecryptorResult(events: envelope.events, brokenMLSGroupIDs: [Scaffolding.mlsGroupID])
        }

        // Last event is being updated.
        updateEventsStore.storeLastEventIDId_MockMethod = { _ in }

        // Events are processed.
        processor.processEvent_MockMethod = { _ in }

        // Unread messages are set
        updateEventsStore.calculateLastUnreadMessages_MockMethod = {}

        // Database is saved.
        databaseSaver.save_MockMethod = {}

        // Repair broken MLS conversations
        mlsGroupRepairAgent.repairConversations_MockMethod = {}

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
        XCTAssertEqual(updateEventsSync.pullPublicKeys_Invocations.count, 1)

        // Then live events were decrypted (duplicates skipped).
        XCTAssertEqual(
            decryptor.decryptEventsInContext_Invocations.map(\.eventEnvelope),
            [Scaffolding.event4, Scaffolding.event5]
        )

        // Then live events were stored (duplicates skipped).
        XCTAssertEqual(updateEventsStore.indexOfLastEventEnvelope_Invocations.count, 2)

        // Broken conversation IDs are stored
        XCTAssertEqual(journal[.brokenMLSGroupIDs].first, Scaffolding.mlsGroupID)

        let storeInvocations = updateEventsStore.persistEventEnvelopeIndexPublicKeys_Invocations
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
        XCTAssertEqual(
            updateEventsStore.deleteNextPendingEventsWith_Invocations,
            [[managedObjectID1, managedObjectID2, managedObjectID3]]
        )

        // Then live events were deleted (duplicates skipped).
        XCTAssertEqual(updateEventsStore.deleteEventEnvelopeAtIndex_Invocations, [11, 12])

        // Then unread messages are calculated once after processing pending events
        // and once after processing each live event.
        XCTAssertEqual(updateEventsStore.calculateLastUnreadMessages_Invocations.count, 3)

        // Then the database was saved once after processing pending events
        // and once after processing each live event.
        XCTAssertEqual(databaseSaver.save_Invocations.count, 3)
    }

    func test_perform_OutOfSyncLiveEventsAreNotified() async throws {
        // Mock
        // Pending events are pulled.
        updateEventsSync.pullPublicKeys_MockMethod = { _ in AsyncStream { [] } }

        // Pending events are stored in batches.
        updateEventsStore.fetchStoredEventEnvelopesLimitPrivateKeysBackgroundAccessibleOnly_MockMethod = { _, _, _ in
            []
        }

        // Pending events are deleted in batches.
        updateEventsStore.deleteNextPendingEventsWith_MockMethod = { _ in }

        // Some live events, some of which were already pulled.
        let pushChannel = MockPushChannelProtocol()
        let mlsEvent = Scaffolding.createMLSEvent(message: "hello 1", timeIntervalSinceNow: .oneSecond)
        let mlsOutOfSyncEvent = Scaffolding.createMLSEvent(message: "hello 2", timeIntervalSinceNow: .oneMinute)
        pushChannel.open_MockValue = AsyncThrowingStream { continuation in
            Task {
                continuation.yield(mlsEvent)
                continuation.yield(mlsOutOfSyncEvent)
                continuation.finish()
            }
        }

        pushChannelAPI.createPushChannelClientID_MockMethod = { _ in pushChannel }

        // Some indices at which live events will be stored.
        var indices = [Int64(10), 11]
        updateEventsStore.indexOfLastEventEnvelope_MockMethod = { indices.remove(at: 0) }

        // Live envelopes are peristed and deleted one by one.
        updateEventsStore.persistEventEnvelopeIndexPublicKeys_MockMethod = { _, _, _ async throws in }
        updateEventsStore.deleteEventEnvelopeAtIndex_MockMethod = { _ in }

        // Live events are decrypted.
        decryptor.decryptEventsInContext_MockMethod = { envelope, _ in
            if envelope.id == mlsOutOfSyncEvent.id {
                EventDecryptorResult(events: envelope.events, brokenMLSGroupIDs: [Scaffolding.mlsGroupID])
            } else {
                EventDecryptorResult(events: envelope.events, brokenMLSGroupIDs: [])
            }
        }

        // Last event is being updated.
        updateEventsStore.storeLastEventIDId_MockMethod = { _ in }

        // Events are processed.
        processor.processEvent_MockMethod = { _ in }

        // Unread messages are set
        updateEventsStore.calculateLastUnreadMessages_MockMethod = {}

        // Database is saved.
        databaseSaver.save_MockMethod = {}

        // Repair broken MLS conversations
        mlsGroupRepairAgent.repairConversations_MockMethod = {}

        // When
        let expectation = expectation(description: "one mls broken group should be detected live")
        liveBrokenGroupSubject.sink { value in
            print(value)
            XCTAssertTrue(value.contains(Scaffolding.mlsGroupID))
            expectation.fulfill()
        }.store(in: &cancellables)

        let token = try await sut.perform()
        await token.task.value
        wait(for: [expectation])

        // Then live events were decrypted (duplicates skipped).
        XCTAssertEqual(
            decryptor.decryptEventsInContext_Invocations.count,
            2
        )

        // Broken conversation IDs are stored
        XCTAssertEqual(journal[.brokenMLSGroupIDs].first, Scaffolding.mlsGroupID)
    }

    func test_perform_Cancelled_Push_Channel_Closed() async throws {
        // Mock
        // Pending events are pulled.
        updateEventsSync.pullPublicKeys_MockMethod = { _ in AsyncStream { [] } }

        // Some pending events.
        var storedEnvelopes = [
            Scaffolding.event1,
            Scaffolding.event2,
            Scaffolding.event3
        ]

        // Pending events are stored in batches.
        updateEventsStore.fetchStoredEventEnvelopesLimitPrivateKeysBackgroundAccessibleOnly_MockMethod = { _, _, _ in
            let envelopes = storedEnvelopes
            storedEnvelopes = []
            return envelopes.map { ($0, NSManagedObjectID()) }
        }

        // Pending events are deleted in batches.
        updateEventsStore.deleteNextPendingEventsWith_MockMethod = { _ in }

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
        updateEventsStore.persistEventEnvelopeIndexPublicKeys_MockMethod = { _, _, _ async throws in }
        updateEventsStore.deleteEventEnvelopeAtIndex_MockMethod = { _ in }

        // Live events are decrypted.
        decryptor.decryptEventsInContext_MockMethod = { envelope, _ async in .init(
            events: envelope.events,
            brokenMLSGroupIDs: []
        ) }

        // Last event is being updated.
        updateEventsStore.storeLastEventIDId_MockMethod = { _ in }

        // Events are processed.
        processor.processEvent_MockMethod = { _ in }

        // Unread messages are set
        updateEventsStore.calculateLastUnreadMessages_MockMethod = {}

        // Database is saved.
        databaseSaver.save_MockMethod = {}
        pushChannel.close_MockMethod = {}

        // Repair broken MLS conversations
        mlsGroupRepairAgent.repairConversations_MockMethod = {}

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
        pushChannel.open_MockValue = AsyncThrowingStream { _ in }
        pushChannel.close_MockMethod = {}
        pushChannelAPI.createPushChannelClientID_MockMethod = { _ in pushChannel }
        updateEventsSync.pullPublicKeys_MockError = UpdateEventsAPIError.notFound
        messageLocalStore.addPotentialGapSystemMessage_MockMethod = {}
        updateEventsStore.storeLastEventIDId_MockMethod = { _ in }
        updateEventsStore.resetLastEventID_MockMethod = {}

        await XCTAssertThrowsErrorAsync(IncrementalSync.Failure.missedEvents) {
            // When
            try await self.sut.perform()
        }

        // Then
        XCTAssertEqual(messageLocalStore.addPotentialGapSystemMessage_Invocations.count, 1)
        XCTAssertEqual(updateEventsStore.resetLastEventID_Invocations.count, 1)
    }

    // MARK: - EAR Database Lock Tests

    func test_perform_databaseUnlocked_succeeds() async throws {
        // Given: Database is not locked
        earService.underlyingIsLocked = false
        earService.fetchPublicKeys_MockMethod = { nil }
        earService.fetchPrivateKeysIncludingPrimary_MockMethod = { _ in nil }

        // Setup other required mocks
        setPendingEvents(envelopes: [])
        setupPushChannel()
        updateEventsSync.pullPublicKeys_MockMethod = { _ in AsyncStream { [] } }
        updateEventsStore.calculateLastUnreadMessages_MockMethod = {}
        databaseSaver.save_MockMethod = {}
        mlsGroupRepairAgent.repairConversations_MockMethod = {}

        // When
        _ = try await sut.perform()

        // Then: Should fetch keys with includingPrimary: true
        XCTAssertEqual(earService.fetchPrivateKeysIncludingPrimary_Invocations.count, 1)
        XCTAssertTrue(earService.fetchPrivateKeysIncludingPrimary_Invocations[0])
    }

    func test_perform_databaseLocked_throwsError() async throws {
        // Given: Database is locked
        earService.underlyingIsLocked = true

        // When/Then: Should throw databaseLocked error immediately
        await XCTAssertThrowsErrorAsync(IncrementalSync.Failure.databaseLocked) {
            try await self.sut.perform()
        }

        // Verify no sync operations were attempted
        XCTAssertEqual(pushChannelAPI.createPushChannelClientID_Invocations.count, 0)
    }

    func test_performInBackgroundForCallingEvents_EAREnabled_usesSecondaryKeysAndFiltersEvents() async throws {
        // Given: EAR is enabled (database may be locked in background)
        earService.underlyingIsEAREnabled = true
        earService.fetchPublicKeys_MockMethod = { nil }
        earService.fetchPrivateKeysIncludingPrimary_MockMethod = { includingPrimary in
            XCTAssertFalse(includingPrimary, "Should not include primary keys")
            return nil
        }

        // Setup other required mocks
        setPendingEvents(envelopes: [])
        setupPushChannel()
        updateEventsSync.pullPublicKeys_MockMethod = { _ in AsyncStream { [] } }
        updateEventsStore.calculateLastUnreadMessages_MockMethod = {}
        databaseSaver.save_MockMethod = {}
        mlsGroupRepairAgent.repairConversations_MockMethod = {}

        // When
        _ = try await sut.performInBackgroundForCallingEvents()

        // Then: Should proceed with only secondary keys
        XCTAssertEqual(earService.fetchPrivateKeysIncludingPrimary_Invocations.count, 1)
        XCTAssertFalse(earService.fetchPrivateKeysIncludingPrimary_Invocations[0])

        // Should process only background-accessible events
        XCTAssertEqual(
            updateEventsStore.fetchStoredEventEnvelopesLimitPrivateKeysBackgroundAccessibleOnly_Invocations.count,
            1
        )
        XCTAssertTrue(
            updateEventsStore.fetchStoredEventEnvelopesLimitPrivateKeysBackgroundAccessibleOnly_Invocations[0]
                .backgroundAccessibleOnly
        )
    }

    func test_performInBackgroundForCallingEvents_EARDisabled_processesAllEvents() async throws {
        // Given: EAR is disabled
        earService.underlyingIsEAREnabled = false
        earService.fetchPublicKeys_MockMethod = { nil }
        earService.fetchPrivateKeysIncludingPrimary_MockMethod = { _ in nil }

        // Setup other required mocks
        setPendingEvents(envelopes: [])
        setupPushChannel()
        updateEventsSync.pullPublicKeys_MockMethod = { _ in AsyncStream { [] } }
        updateEventsStore.calculateLastUnreadMessages_MockMethod = {}
        databaseSaver.save_MockMethod = {}
        mlsGroupRepairAgent.repairConversations_MockMethod = {}

        // When
        _ = try await sut.performInBackgroundForCallingEvents()

        // Then: Should fetch all keys (primary included)
        XCTAssertEqual(earService.fetchPrivateKeysIncludingPrimary_Invocations.count, 1)
        XCTAssertTrue(earService.fetchPrivateKeysIncludingPrimary_Invocations[0])

        // Should process all events (not background-accessible only)
        XCTAssertEqual(
            updateEventsStore.fetchStoredEventEnvelopesLimitPrivateKeysBackgroundAccessibleOnly_Invocations.count,
            1
        )
        XCTAssertFalse(
            updateEventsStore.fetchStoredEventEnvelopesLimitPrivateKeysBackgroundAccessibleOnly_Invocations[0]
                .backgroundAccessibleOnly
        )
    }

    // MARK: - Helper Methods

    private func setPendingEvents(envelopes: [UpdateEventEnvelope]) {
        var storedEnvelopes = envelopes.map { ($0, NSManagedObjectID()) }
        updateEventsStore.fetchStoredEventEnvelopesLimitPrivateKeysBackgroundAccessibleOnly_MockMethod = { _, _, _ in
            let result = storedEnvelopes
            storedEnvelopes = []
            return result
        }
        updateEventsStore.deleteNextPendingEventsWith_MockMethod = { _ in }
    }

    private func setupPushChannel() {
        let pushChannel = MockPushChannelProtocol()
        pushChannel.open_MockValue = AsyncThrowingStream { continuation in
            continuation.finish()
        }
        pushChannel.close_MockMethod = {}
        pushChannelAPI.createPushChannelClientID_MockMethod = { _ in pushChannel }
    }
}

private enum Scaffolding {

    static let selfClientID = "selfClientID"
    static let mlsGroupID = "ASDF"

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
                id: UUID(),
                domain: "example.com"
            ),
            senderID: UserID(
                id: UUID(),
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

    static func createMLSEvent(
        message: String,
        timeIntervalSinceNow: TimeInterval,
        isTransient: Bool = false
    ) -> UpdateEventEnvelope {
        let event = ConversationMLSMessageAddEvent(
            conversationID: ConversationID(
                id: UUID(),
                domain: "example.com"
            ),
            senderID: UserID(
                id: UUID(),
                domain: "example.com"
            ),
            subconversation: nil,
            message: message,
            timestamp: Date(timeIntervalSinceNow: timeIntervalSinceNow),
            decryptedMessages: [
                .init(message: message, senderClientID: UUID().uuidString)
            ]
        )
        return UpdateEventEnvelope(
            id: UUID(),
            events: [.conversation(.mlsMessageAdd(event))],
            isTransient: isTransient
        )
    }
}
