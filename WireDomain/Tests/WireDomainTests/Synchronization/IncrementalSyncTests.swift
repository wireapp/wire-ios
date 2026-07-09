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
import GenericMessageProtocol
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
            earService: earService,
            backgroundTaskExecuter: PassthroughTaskExecuter()
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
        wait(for: [expectation], timeout: 5)

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

    func test_perform_CancelledDuringLargeBatch_CancellationCheckIsReached() async throws {
        // Given: A large batch of stored events
        let largeEventCount = 100
        var largeEventBatch: [(UpdateEventEnvelope, NSManagedObjectID)] = []
        for i in 0..<largeEventCount {
            let event = Scaffolding.createEvent(
                message: "message \(i)",
                timeIntervalSinceNow: TimeInterval(-i)
            )
            largeEventBatch.append((event, NSManagedObjectID()))
        }

        updateEventsStore.fetchStoredEventEnvelopesLimitPrivateKeysBackgroundAccessibleOnly_MockMethod = { _, _, _ in
            let result = largeEventBatch
            largeEventBatch = []
            return result
        }

        updateEventsStore.deleteNextPendingEventsWith_MockMethod = { _ in }
        updateEventsStore.calculateLastUnreadMessages_MockMethod = {}
        databaseSaver.save_MockMethod = {}
        updateEventsSync.pullPublicKeys_MockMethod = { _ in AsyncStream { [] } }

        // Setup push channel
        let pushChannel = MockPushChannelProtocol()
        pushChannel.open_MockValue = AsyncThrowingStream { _ in }
        pushChannel.close_MockMethod = {}
        pushChannelAPI.createPushChannelClientID_MockMethod = { _ in pushChannel }

        // Cancel the task after processing a few events to simulate
        // cancellation during the batch processing
        var processedEventCount = 0
        let cancelAfterCount = 10
        let expectation = expectation(description: "task cancelled")
        var taskToCancel: Task<Void, any Error>?

        processor.processEvent_MockMethod = { _ in
            processedEventCount += 1
            if processedEventCount == cancelAfterCount {
                taskToCancel?.cancel()
                expectation.fulfill()
            }
        }

        // When: Start sync and cancel during processing
        taskToCancel = Task {
            _ = try await self.sut.perform()
        }

        // Wait for cancellation to occur
        await fulfillment(of: [expectation], timeout: 5)

        // Then: Should throw CancellationError
        do {
            _ = try await taskToCancel!.value
            XCTFail("Expected CancellationError to be thrown")
        } catch is CancellationError {
            // Expected - cancellation check was reached
            XCTAssertTrue(true, "Cancellation check was successfully reached during batch processing")
        } catch {
            XCTFail("Expected CancellationError but got: \(error)")
        }

        // Verify that:
        // 1. Some events were processed (at least up to the cancellation point)
        XCTAssertGreaterThanOrEqual(processedEventCount, cancelAfterCount)

        // 2. Not all events were processed (cancellation stopped processing)
        XCTAssertLessThan(processedEventCount, largeEventCount)

        // 3. Push channel was closed
        XCTAssertEqual(pushChannel.close_Invocations.count, 1)

        // 4. Partial batch was committed (only the events processed before cancellation)
        XCTAssertEqual(updateEventsStore.deleteNextPendingEventsWith_Invocations.count, 1)
        XCTAssertLessThan(
            updateEventsStore.deleteNextPendingEventsWith_Invocations[0].count,
            largeEventCount
        )
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
        try XCTAssertCount(earService.fetchPrivateKeysIncludingPrimary_Invocations, count: 1)
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

    func test_performForCallingEventsOnly_EAREnabled_usesSecondaryKeysAndFiltersEvents() async throws {
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
        _ = try await sut.performForCallingEventsOnly()

        // Then: Should proceed with only secondary keys
        try XCTAssertCount(earService.fetchPrivateKeysIncludingPrimary_Invocations, count: 1)
        XCTAssertFalse(earService.fetchPrivateKeysIncludingPrimary_Invocations[0])

        // Should process only background-accessible events
        try XCTAssertCount(
            updateEventsStore.fetchStoredEventEnvelopesLimitPrivateKeysBackgroundAccessibleOnly_Invocations,
            count: 1
        )
        XCTAssertTrue(
            updateEventsStore.fetchStoredEventEnvelopesLimitPrivateKeysBackgroundAccessibleOnly_Invocations[0]
                .backgroundAccessibleOnly
        )
    }

    func test_performForCallingEventsOnly_filterEvents() async throws {
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
        _ = try await sut.performForCallingEventsOnly()

        // Then: Should filter events (background-accessible only)
        try XCTAssertCount(
            updateEventsStore.fetchStoredEventEnvelopesLimitPrivateKeysBackgroundAccessibleOnly_Invocations,
            count: 1
        )
        XCTAssertTrue(
            updateEventsStore.fetchStoredEventEnvelopesLimitPrivateKeysBackgroundAccessibleOnly_Invocations[0]
                .backgroundAccessibleOnly
        )
    }

    func test_processEventEnvelopes_databaseLocksAfterFirstEnvelope_partialCommitAndAbort() async throws {
        // Given: database is initially unlocked
        earService.underlyingIsLocked = false

        let objectID1 = NSManagedObjectID()
        let objectID2 = NSManagedObjectID()
        var storedEnvelopes: [(UpdateEventEnvelope, NSManagedObjectID)] = [
            (Scaffolding.event1, objectID1),
            (Scaffolding.event2, objectID2)
        ]
        updateEventsStore.fetchStoredEventEnvelopesLimitPrivateKeysBackgroundAccessibleOnly_MockMethod = { _, _, _ in
            defer { storedEnvelopes = [] }
            return storedEnvelopes
        }
        updateEventsStore.deleteNextPendingEventsWith_MockMethod = { _ in }
        updateEventsStore.calculateLastUnreadMessages_MockMethod = {}
        databaseSaver.save_MockMethod = {}
        updateEventsSync.pullPublicKeys_MockMethod = { _ in AsyncStream { [] } }
        setupPushChannel()
        mlsGroupRepairAgent.repairConversations_MockMethod = {}

        // Simulate lock occurring while processing the first envelope's events
        processor.processEvent_MockMethod = { [weak self] _ in
            self?.earService.underlyingIsLocked = true
        }

        // When/Then: sync aborts with databaseLocked
        await XCTAssertThrowsErrorAsync(IncrementalSync.Failure.databaseLocked) {
            _ = try await self.sut.perform()
        }

        // Only the first envelope's events were processed
        XCTAssertEqual(processor.processEvent_Invocations.count, Scaffolding.event1.events.count)

        // Only the first envelope was committed to deletion
        XCTAssertEqual(
            updateEventsStore.deleteNextPendingEventsWith_Invocations,
            [[objectID1]]
        )
    }

    func test_processStoredEvents_databaseLocksBeforeSecondBatch_commitsFirstBatchAndAborts() async throws {
        // Given: database starts unlocked, two separate batches
        earService.underlyingIsLocked = false

        let objectID1 = NSManagedObjectID()
        let objectID2 = NSManagedObjectID()
        var batches: [[(UpdateEventEnvelope, NSManagedObjectID)]] = [
            [(Scaffolding.event1, objectID1)],
            [(Scaffolding.event2, objectID2)]
        ]
        updateEventsStore.fetchStoredEventEnvelopesLimitPrivateKeysBackgroundAccessibleOnly_MockMethod = { _, _, _ in
            batches.isEmpty ? [] : batches.removeFirst()
        }
        updateEventsStore.deleteNextPendingEventsWith_MockMethod = { _ in }
        updateEventsStore.calculateLastUnreadMessages_MockMethod = {}
        processor.processEvent_MockMethod = { _ in }
        updateEventsSync.pullPublicKeys_MockMethod = { _ in AsyncStream { [] } }
        setupPushChannel()
        mlsGroupRepairAgent.repairConversations_MockMethod = {}

        // Simulate the database locking after batch 1 is saved (between batches)
        databaseSaver.save_MockMethod = { [weak self] in
            self?.earService.underlyingIsLocked = true
        }

        // When/Then: sync aborts with databaseLocked
        await XCTAssertThrowsErrorAsync(IncrementalSync.Failure.databaseLocked) {
            _ = try await self.sut.perform()
        }

        // Only batch 1's events were processed
        XCTAssertEqual(processor.processEvent_Invocations.count, Scaffolding.event1.events.count)

        // Only batch 1 was committed to deletion
        XCTAssertEqual(
            updateEventsStore.deleteNextPendingEventsWith_Invocations,
            [[objectID1]]
        )
    }

    func test_processLiveEvents_databaseLocked_skipsNonBackgroundAccessibleEvent() async throws {
        // Given: database starts unlocked, no stored events
        earService.underlyingIsLocked = false
        setPendingEvents(envelopes: [])
        updateEventsSync.pullPublicKeys_MockMethod = { _ in AsyncStream { [] } }
        updateEventsStore.calculateLastUnreadMessages_MockMethod = {}
        databaseSaver.save_MockMethod = {}

        // Lock the database between stored-event phase and live-event phase
        mlsGroupRepairAgent.repairConversations_MockMethod = { [weak self] in
            self?.earService.underlyingIsLocked = true
        }

        var indices = [Int64(10)]
        updateEventsStore.indexOfLastEventEnvelope_MockMethod = { indices.remove(at: 0) }
        updateEventsStore.persistEventEnvelopeIndexPublicKeys_MockMethod = { _, _, _ in }
        updateEventsStore.storeLastEventIDId_MockMethod = { _ in }
        updateEventsStore.deleteEventEnvelopeAtIndex_MockMethod = { _ in }
        decryptor.decryptEventsInContext_MockMethod = { envelope, _ in
            .init(events: envelope.events, brokenMLSGroupIDs: [])
        }
        processor.processEvent_MockMethod = { _ in }

        let pushChannel = MockPushChannelProtocol()
        pushChannel.open_MockValue = AsyncThrowingStream { continuation in
            Task {
                continuation.yield(Scaffolding.event1) // non-background-accessible
                continuation.finish()
            }
        }
        pushChannel.close_MockMethod = {}
        pushChannelAPI.createPushChannelClientID_MockMethod = { _ in pushChannel }

        // When
        let token = try await sut.perform()
        await token.task.value

        // Then: event was persisted to the store...
        XCTAssertEqual(updateEventsStore.persistEventEnvelopeIndexPublicKeys_Invocations.count, 1)

        // ...but NOT processed
        XCTAssertEqual(processor.processEvent_Invocations.count, 0)

        // ...and NOT deleted (stays in DB for post-unlock reprocessing)
        XCTAssertEqual(updateEventsStore.deleteEventEnvelopeAtIndex_Invocations.count, 0)
    }

    func test_processLiveEvents_databaseLocked_processesBackgroundAccessibleEvent() async throws {
        // Given: database starts unlocked, no stored events
        earService.underlyingIsLocked = false
        setPendingEvents(envelopes: [])
        updateEventsSync.pullPublicKeys_MockMethod = { _ in AsyncStream { [] } }
        updateEventsStore.calculateLastUnreadMessages_MockMethod = {}
        databaseSaver.save_MockMethod = {}

        // Lock the database between stored-event phase and live-event phase
        mlsGroupRepairAgent.repairConversations_MockMethod = { [weak self] in
            self?.earService.underlyingIsLocked = true
        }

        var indices = [Int64(10)]
        updateEventsStore.indexOfLastEventEnvelope_MockMethod = { indices.remove(at: 0) }
        updateEventsStore.persistEventEnvelopeIndexPublicKeys_MockMethod = { _, _, _ in }
        updateEventsStore.storeLastEventIDId_MockMethod = { _ in }
        updateEventsStore.deleteEventEnvelopeAtIndex_MockMethod = { _ in }
        decryptor.decryptEventsInContext_MockMethod = { envelope, _ in
            .init(events: envelope.events, brokenMLSGroupIDs: [])
        }
        processor.processEvent_MockMethod = { _ in }

        let callingEnvelope = Scaffolding.createCallingEnvelope()

        let pushChannel = MockPushChannelProtocol()
        pushChannel.open_MockValue = AsyncThrowingStream { continuation in
            Task {
                continuation.yield(callingEnvelope) // background-accessible calling event
                continuation.finish()
            }
        }
        pushChannel.close_MockMethod = {}
        pushChannelAPI.createPushChannelClientID_MockMethod = { _ in pushChannel }

        // When
        let token = try await sut.perform()
        await token.task.value

        // Then: event was persisted...
        XCTAssertEqual(updateEventsStore.persistEventEnvelopeIndexPublicKeys_Invocations.count, 1)

        // ...AND processed despite the lock (background-accessible)
        XCTAssertEqual(processor.processEvent_Invocations.count, 1)

        // ...AND deleted from store after processing
        XCTAssertEqual(updateEventsStore.deleteEventEnvelopeAtIndex_Invocations, [11])
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

    static func createCallingEnvelope() -> UpdateEventEnvelope {
        let callingMessage = GenericMessage(
            content: Calling(content: "calling", conversationId: .init(uuid: UUID(), domain: "")),
            nonce: UUID()
        )
        let callingData = try! callingMessage.serializedData().base64String()
        let event = ConversationProteusMessageAddEvent(
            conversationID: ConversationID(id: UUID(), domain: "example.com"),
            senderID: UserID(id: UUID(), domain: "example.com"),
            timestamp: Date(),
            message: MessageContent(
                encryptedMessage: "encrypted",
                decryptedMessage: callingData
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
