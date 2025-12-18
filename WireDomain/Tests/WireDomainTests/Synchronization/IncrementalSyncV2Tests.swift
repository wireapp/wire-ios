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
import CoreData
import XCTest
@testable import WireDataModelSupport
@testable import WireDomain
@testable import WireDomainSupport
@testable import WireNetwork
@testable import WireNetworkSupport

final class IncrementalSyncV2Tests: XCTestCase {

    var sut: IncrementalSyncV2!
    var pushChannelAPI: MockPushChannelV2API!
    var pullServerTimeSync: MockPullServerTimeSyncProtocol!
    var decryptor: MockUpdateEventDecryptorProtocol!
    var updateEventsStore: MockUpdateEventsLocalStoreProtocol!
    var messageLocalStore: MockMessageLocalStoreProtocol!
    var processor: MockUpdateEventProcessorProtocol!
    var databaseSaver: MockDatabaseSaverProtocol!
    var syncStateSubject: CurrentValueSubject<SyncState, Never>!
    var liveDelegate: MockLiveSyncDelegate!
    var coreCryptoContext: MockCoreCryptoContextProtocol!
    var coreCrypto: MockCoreCryptoProtocol!
    var coreCryptoProvider: MockCoreCryptoProviderProtocol!
    var pushChannelState: MockPushChannelStateProtocol!
    var mlsGroupRepairAgent: MockMLSGroupRepairAgentProtocol!
    var journal: Journal!

    override func setUp() {
        pushChannelAPI = MockPushChannelV2API()
        pullServerTimeSync = MockPullServerTimeSyncProtocol()
        decryptor = MockUpdateEventDecryptorProtocol()
        updateEventsStore = MockUpdateEventsLocalStoreProtocol()
        messageLocalStore = MockMessageLocalStoreProtocol()
        processor = MockUpdateEventProcessorProtocol()
        databaseSaver = MockDatabaseSaverProtocol()
        liveDelegate = MockLiveSyncDelegate()
        syncStateSubject = .init(.idle)
        coreCryptoContext = MockCoreCryptoContextProtocol()
        coreCrypto = MockCoreCryptoProtocol()
        coreCrypto.mockTransaction(context: coreCryptoContext)
        coreCryptoProvider = MockCoreCryptoProviderProtocol()
        coreCryptoProvider.coreCrypto_MockValue = coreCrypto
        journal = Journal(
            userID: UUID(),
            storage: UserDefaults.temporary()
        )
        pushChannelState = MockPushChannelStateProtocol()
        mlsGroupRepairAgent = MockMLSGroupRepairAgentProtocol()

        sut = IncrementalSyncV2(
            selfClientID: Scaffolding.selfClientID,
            pullServerTimeSync: pullServerTimeSync,
            pushChannelAPI: pushChannelAPI,
            decryptor: decryptor,
            updateEventsStore: updateEventsStore,
            messageStore: messageLocalStore,
            processor: processor,
            databaseSaver: databaseSaver,
            syncStateSubject: syncStateSubject,
            coreCryptoProvider: coreCryptoProvider,
            journal: journal,
            mlsGroupRepairAgent: mlsGroupRepairAgent,
            createPushChannelState: {
                self.pushChannelState
            },
            syncMarkerGenerator: { Scaffolding.markerID }
        )
        sut.delegate = liveDelegate
        liveDelegate.isUpToDateSync_MockMethod = { _ in }
        liveDelegate.didMissedEventsSync_MockMethod = { _ in }
        liveDelegate.didStartSync_MockMethod = { _ in }
        pullServerTimeSync.pull_MockMethod = {}
        pushChannelState.markAsOpen_MockMethod = {}
        pushChannelState.markAsClosed_MockMethod = {}
        // Repair broken MLS conversations
        mlsGroupRepairAgent.repairConversations_MockMethod = {}
    }

    override func tearDown() {
        sut = nil
        pushChannelAPI = nil
        mlsGroupRepairAgent = nil
        pullServerTimeSync = nil
        decryptor = nil
        updateEventsStore = nil
        messageLocalStore = nil
        processor = nil
        databaseSaver = nil
        syncStateSubject = nil
        journal = nil
        liveDelegate = nil
        coreCrypto = nil
        coreCryptoProvider = nil
        coreCryptoContext = nil
    }

    func testPerform_pendingEventsExist() async throws {
        // Mock

        // Some live events, some of which were already pulled.
        let pushChannel = MockPushChannelV2Protocol()

        pushChannel.open_MockValue = AsyncThrowingStream { continuation in
            Task {
                continuation.yield(PushChannelV2.Element.events([Scaffolding.event2]))
                continuation.yield(PushChannelV2.Element.syncMarker(
                    id: Scaffolding.markerID,
                    deliveryTag: Scaffolding.markerDeliveryTag
                ))
                continuation.finish()
            }
        }
        pushChannel.acknowledgeEventDeliveryTagMultiple_MockMethod = { _, _ in }
        pushChannel.close_MockMethod = {}
        pushChannelAPI.createPushChannelClientIDMarker_MockMethod = { _, _ in pushChannel }

        // Events stored from NSE which needs to be processed
        setPendingEvents(envelopes: [
            (Scaffolding.event4, NSManagedObjectID())
        ])

        // Pending events are deleted in batches.
        updateEventsStore.deleteNextPendingEventsWith_MockMethod = { _ in }

        // Some indices at which live events will be stored.
        var indices = [Int64(10)]
        updateEventsStore.indexOfLastEventEnvelope_MockMethod = { indices.remove(at: 0) }

        // Live envelopes are peristed one by one and deleted by batch.
        updateEventsStore.persistEventEnvelopeIndex_MockMethod = { _, _ async throws in }
        updateEventsStore.deleteEventEnvelopesAt_MockMethod = { _ in }

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

        // When
        let token = try await sut.perform()
        let numberOfStoredEventEnvelopesInvocations = 2
        let numberOfInvocationInProcessEvents = 1

        XCTAssertEqual(pullServerTimeSync.pull_Invocations.count, 1)

        // sync bar is shown
        XCTAssertEqual(liveDelegate.didStartSync_Invocations.count, 1)

        // Then stored events were processed
        XCTAssertEqual(
            updateEventsStore.fetchStoredEventEnvelopesLimit_Invocations.count,
            numberOfStoredEventEnvelopesInvocations
        )
        XCTAssertEqual(processor.processEvent_Invocations.count, 1)
        XCTAssertEqual(updateEventsStore.deleteNextPendingEventsWith_Invocations.count, 1)
        XCTAssertEqual(
            updateEventsStore.calculateLastUnreadMessages_Invocations.count,
            numberOfInvocationInProcessEvents
        )
        XCTAssertEqual(databaseSaver.save_Invocations.count, numberOfInvocationInProcessEvents)

        // When
        await token.task.value

        try XCTAssertCount(
            pushChannelState.markAsOpen_Invocations, count: 1
        )
        // Then push channel was created.
        try XCTAssertCount(
            pushChannelAPI.createPushChannelClientIDMarker_Invocations, count: 1
        )
        let invocation = try XCTUnwrap(pushChannelAPI.createPushChannelClientIDMarker_Invocations.first)

        XCTAssertEqual(invocation.clientID, Scaffolding.selfClientID)
        XCTAssertEqual(invocation.marker, Scaffolding.markerID)

        // Then push channel was opened.
        XCTAssertEqual(pushChannel.open_Invocations.count, 1)

        // Then live events were decrypted (duplicates skipped).
        XCTAssertEqual(
            decryptor.decryptEventsInContext_Invocations.map(\.eventEnvelope),
            [Scaffolding.event2]
        )

        // Then sync is up to date
        XCTAssertEqual(liveDelegate.isUpToDateSync_Invocations.count, 1)

        // Broken conversation IDs are stored
        XCTAssertEqual(journal[.brokenMLSGroupIDs].first, Scaffolding.mlsGroupID)

        // Then all events were processed once.
        XCTAssertEqual(
            processor.processEvent_Invocations,
            [
                Scaffolding.event4,
                Scaffolding.event2
            ].flatMap(\.events)
        )

        // Then unread messages are calculated once after processing pending events
        // and once after processing each live event.
        XCTAssertEqual(
            updateEventsStore.calculateLastUnreadMessages_Invocations.count,
            numberOfInvocationInProcessEvents + 1
        )

        // Then the database was saved once after processing pending events
        // and once after processing each live event.
        XCTAssertEqual(databaseSaver.save_Invocations.count, numberOfInvocationInProcessEvents + 1)

        // Then ack of events done after processing
        XCTAssertEqual(pushChannel.acknowledgeEventDeliveryTagMultiple_Invocations.count, 2)
        XCTAssertTrue(pushChannel.acknowledgeEventDeliveryTagMultiple_Invocations.first?.multiple == true)

        XCTAssertTrue(pushChannel.acknowledgeEventDeliveryTagMultiple_Invocations.last?.multiple == false)
        XCTAssertTrue(
            pushChannel.acknowledgeEventDeliveryTagMultiple_Invocations.last?.deliveryTag == Scaffolding
                .markerDeliveryTag
        )
    }

    func testPerform_AcknowledgementFullSync() async throws {
        // Mock
        messageLocalStore.addPotentialGapSystemMessage_MockMethod = {}
        let pushChannel = MockPushChannelV2Protocol()
        pushChannel.acknowledgeFullSync_MockMethod = {}

        pushChannel.open_MockValue = AsyncThrowingStream { continuation in
            Task {
                continuation.yield(.events([Scaffolding.event2, Scaffolding.event3]))
                continuation.yield(.missedEvents)
                continuation.finish()
            }
        }
        pushChannel.acknowledgeEventDeliveryTagMultiple_MockMethod = { _, _ in }
        pushChannel.close_MockMethod = {}
        pushChannelAPI.createPushChannelClientIDMarker_MockMethod = { _, _ in pushChannel }

        // Events stored from NSE which needs to be processed
        setPendingEvents(envelopes: [])

        // Some indices at which live events will be stored.
        var indices = [Int64(10), 11]
        updateEventsStore.indexOfLastEventEnvelope_MockMethod = { indices.remove(at: 0) }

        // Live envelopes are peristed one by one and deleted by batch.
        updateEventsStore.persistEventEnvelopeIndex_MockMethod = { _, _ async throws in }
        updateEventsStore.deleteEventEnvelopesAt_MockMethod = { _ in }

        // Live events are decrypted.
        decryptor.decryptEventsInContext_MockMethod = { envelope, _ in
            EventDecryptorResult(events: envelope.events, brokenMLSGroupIDs: [])
        }

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

        // sync bar is shown
        XCTAssertEqual(liveDelegate.didStartSync_Invocations.count, 1)

        try XCTAssertCount(
            pushChannelState.markAsOpen_Invocations, count: 1
        )
        // Then push channel was created.
        try XCTAssertCount(
            pushChannelAPI.createPushChannelClientIDMarker_Invocations, count: 1
        )
        let invocation = try XCTUnwrap(pushChannelAPI.createPushChannelClientIDMarker_Invocations.first)

        XCTAssertEqual(invocation.clientID, Scaffolding.selfClientID)
        XCTAssertEqual(invocation.marker, Scaffolding.markerID)

        // Then push channel was opened.
        XCTAssertEqual(pushChannel.open_Invocations.count, 1)

        // Then live events were decrypted (duplicates skipped).
        XCTAssertEqual(
            decryptor.decryptEventsInContext_Invocations.map(\.eventEnvelope),
            [Scaffolding.event2, Scaffolding.event3]
        )

        // Then all events were processed once.
        XCTAssertEqual(
            processor.processEvent_Invocations,
            [
                Scaffolding.event2,
                Scaffolding.event3
            ].flatMap(\.events)
        )

        // Then ack of events done after processing
        XCTAssertEqual(pushChannel.acknowledgeEventDeliveryTagMultiple_Invocations.count, 1)
        XCTAssertTrue(pushChannel.acknowledgeEventDeliveryTagMultiple_Invocations.first?.multiple == true)

        XCTAssertEqual(messageLocalStore.addPotentialGapSystemMessage_Invocations.count, 1)
        XCTAssertEqual(liveDelegate.didMissedEventsSync_Invocations.count, 1)

        // Then unread messages are calculated once after each batch of events.
        XCTAssertEqual(updateEventsStore.calculateLastUnreadMessages_Invocations.count, 1)

        // Then the database was saved once after each batch of events.
        XCTAssertEqual(databaseSaver.save_Invocations.count, 1)
    }

    func testPerform_multipleBatches() async throws {
        // Mock

        // Some live events, some of which were already pulled.
        let pushChannel = MockPushChannelV2Protocol()

        pushChannel.open_MockValue = AsyncThrowingStream { continuation in
            Task {
                continuation.yield(PushChannelV2.Element.events([Scaffolding.event2, Scaffolding.event5]))
                continuation.yield(PushChannelV2.Element.events([Scaffolding.event3, Scaffolding.event4]))
                continuation.yield(PushChannelV2.Element.syncMarker(
                    id: Scaffolding.markerID,
                    deliveryTag: Scaffolding.markerDeliveryTag
                ))
                continuation.finish()
            }
        }
        pushChannel.acknowledgeEventDeliveryTagMultiple_MockMethod = { _, _ in }
        pushChannel.close_MockMethod = {}
        pushChannelAPI.createPushChannelClientIDMarker_MockMethod = { _, _ in pushChannel }

        // Events stored from NSE which needs to be processed
        setPendingEvents(envelopes: [])

        // Live envelopes are peristed one by one and deleted by batch.
        updateEventsStore.persistEventEnvelopeIndex_MockMethod = { _, _ async throws in }
        updateEventsStore.deleteEventEnvelopesAt_MockMethod = { _ in }

        // Some indices at which live events will be stored.
        var indices = [Int64(10), Int64(11), Int64(12), Int64(13)]
        updateEventsStore.indexOfLastEventEnvelope_MockMethod = { indices.remove(at: 0) }

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

        // When
        let token = try await sut.perform()

        // sync bar is shown
        XCTAssertEqual(liveDelegate.didStartSync_Invocations.count, 1)

        let numberOfInvocationInProcessEvents = 0
        // Then stored events were processed
        XCTAssertEqual(updateEventsStore.fetchStoredEventEnvelopesLimit_Invocations.count, 1)
        XCTAssertEqual(processor.processEvent_Invocations.count, numberOfInvocationInProcessEvents)

        XCTAssertEqual(
            updateEventsStore.calculateLastUnreadMessages_Invocations.count,
            numberOfInvocationInProcessEvents
        )
        XCTAssertEqual(databaseSaver.save_Invocations.count, numberOfInvocationInProcessEvents)

        // When
        await token.task.value

        // Then push channel was created.
        try XCTAssertCount(
            pushChannelState.markAsOpen_Invocations, count: 1
        )
        try XCTAssertCount(
            pushChannelAPI.createPushChannelClientIDMarker_Invocations, count: 1
        )
        let invocation = try XCTUnwrap(pushChannelAPI.createPushChannelClientIDMarker_Invocations.first)

        XCTAssertEqual(invocation.clientID, Scaffolding.selfClientID)
        XCTAssertEqual(invocation.marker, Scaffolding.markerID)

        // Then push channel was opened.
        XCTAssertEqual(pushChannel.open_Invocations.count, 1)

        // Then live events were decrypted (duplicates skipped).
        XCTAssertEqual(
            decryptor.decryptEventsInContext_Invocations.map(\.eventEnvelope),
            [Scaffolding.event2, Scaffolding.event5, Scaffolding.event3, Scaffolding.event4]
        )

        // Then sync is up to date
        XCTAssertEqual(liveDelegate.isUpToDateSync_Invocations.count, 1)

        // Broken conversation IDs are stored
        XCTAssertEqual(journal[.brokenMLSGroupIDs].first, Scaffolding.mlsGroupID)

        // Then all events were processed once.
        XCTAssertEqual(
            processor.processEvent_Invocations,
            [
                Scaffolding.event2,
                Scaffolding.event5,
                Scaffolding.event3,
                Scaffolding.event4
            ].flatMap(\.events)
        )

        // Then unread messages are calculated once after processing pending events
        // and once after processing each live event.
        XCTAssertEqual(
            updateEventsStore.calculateLastUnreadMessages_Invocations.count,
            numberOfInvocationInProcessEvents + 2
        )

        // Then the database was saved once after processing pending events
        // and once after processing each live event.
        XCTAssertEqual(databaseSaver.save_Invocations.count, numberOfInvocationInProcessEvents + 2)

        // Then ack of events done after processing
        try XCTAssertCount(pushChannel.acknowledgeEventDeliveryTagMultiple_Invocations, count: 3)

        for i in 0 ... 1 {
            XCTAssertTrue(pushChannel.acknowledgeEventDeliveryTagMultiple_Invocations[i].multiple == true)
        }

        XCTAssertTrue(pushChannel.acknowledgeEventDeliveryTagMultiple_Invocations.last?.multiple == false)
        XCTAssertTrue(
            pushChannel.acknowledgeEventDeliveryTagMultiple_Invocations.last?.deliveryTag == Scaffolding
                .markerDeliveryTag
        )
    }

    func testPerform_skipsSyncMarkerIfInterrupted() async throws {
        // Mock

        // Some live events, some of which were already pulled.
        let pushChannel = MockPushChannelV2Protocol()

        pushChannel.open_MockValue = AsyncThrowingStream { continuation in
            Task {
                continuation.yield(PushChannelV2.Element.events([Scaffolding.event2, Scaffolding.event5]))
                continuation.yield(PushChannelV2.Element.syncMarker(
                    id: "to ignore",
                    deliveryTag: 3
                ))
                continuation.yield(PushChannelV2.Element.events([Scaffolding.event3, Scaffolding.event4]))
                continuation.yield(PushChannelV2.Element.syncMarker(
                    id: Scaffolding.markerID,
                    deliveryTag: Scaffolding.markerDeliveryTag
                ))
                continuation.finish()
            }
        }
        pushChannel.acknowledgeEventDeliveryTagMultiple_MockMethod = { _, _ in }
        pushChannel.close_MockMethod = {}
        pushChannelAPI.createPushChannelClientIDMarker_MockMethod = { _, _ in pushChannel }

        // Events stored from NSE which needs to be processed
        setPendingEvents(envelopes: [])

        // Live envelopes are peristed one by one and deleted by batch.
        updateEventsStore.persistEventEnvelopeIndex_MockMethod = { _, _ async throws in }
        updateEventsStore.deleteEventEnvelopesAt_MockMethod = { _ in }

        // Some indices at which live events will be stored.
        var indices = [Int64(10), Int64(11), Int64(12), Int64(13)]
        updateEventsStore.indexOfLastEventEnvelope_MockMethod = { indices.remove(at: 0) }

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

        // When
        let token = try await sut.perform()

        let numberOfInvocationInProcessEvents = 0
        // Then stored events were processed
        XCTAssertEqual(updateEventsStore.fetchStoredEventEnvelopesLimit_Invocations.count, 1)
        XCTAssertEqual(processor.processEvent_Invocations.count, numberOfInvocationInProcessEvents)

        XCTAssertEqual(
            updateEventsStore.calculateLastUnreadMessages_Invocations.count,
            numberOfInvocationInProcessEvents
        )
        XCTAssertEqual(databaseSaver.save_Invocations.count, numberOfInvocationInProcessEvents)

        // When
        await token.task.value

        // Then push channel was created.
        try XCTAssertCount(
            pushChannelAPI.createPushChannelClientIDMarker_Invocations, count: 1
        )
        let invocation = try XCTUnwrap(pushChannelAPI.createPushChannelClientIDMarker_Invocations.first)

        XCTAssertEqual(invocation.clientID, Scaffolding.selfClientID)
        XCTAssertEqual(invocation.marker, Scaffolding.markerID)

        // Then push channel was opened.
        XCTAssertEqual(pushChannel.open_Invocations.count, 1)

        // Then live events were decrypted (duplicates skipped).
        XCTAssertEqual(
            decryptor.decryptEventsInContext_Invocations.map(\.eventEnvelope),
            [Scaffolding.event2, Scaffolding.event5, Scaffolding.event3, Scaffolding.event4]
        )

        // Then sync is up to date
        XCTAssertEqual(liveDelegate.isUpToDateSync_Invocations.count, 1)

        // Broken conversation IDs are stored
        XCTAssertEqual(journal[.brokenMLSGroupIDs].first, Scaffolding.mlsGroupID)

        // Then all events were processed once.
        XCTAssertEqual(
            processor.processEvent_Invocations,
            [
                Scaffolding.event2,
                Scaffolding.event5,
                Scaffolding.event3,
                Scaffolding.event4
            ].flatMap(\.events)
        )

        // Then unread messages are calculated once after processing pending events
        // and once after processing each live event.
        XCTAssertEqual(
            updateEventsStore.calculateLastUnreadMessages_Invocations.count,
            numberOfInvocationInProcessEvents + 2
        )

        // Then the database was saved once after processing pending events
        // and once after processing each live event.
        XCTAssertEqual(databaseSaver.save_Invocations.count, numberOfInvocationInProcessEvents + 2)

        // Then ack of events done after processing
        try XCTAssertCount(pushChannel.acknowledgeEventDeliveryTagMultiple_Invocations, count: 4)

        for i in [0, 2] {
            XCTAssertTrue(pushChannel.acknowledgeEventDeliveryTagMultiple_Invocations[i].multiple == true)
        }
        for i in [1, 3] {
            XCTAssertTrue(pushChannel.acknowledgeEventDeliveryTagMultiple_Invocations[i].multiple == false)
        }
        XCTAssertTrue(
            pushChannel.acknowledgeEventDeliveryTagMultiple_Invocations.last?.deliveryTag == Scaffolding
                .markerDeliveryTag
        )
    }

    func testPerform_skipsProcessingPendingTypingEvent() async throws {
        // Mock

        // Some live events, some of which were already pulled.
        let pushChannel = MockPushChannelV2Protocol()

        pushChannel.open_MockValue = AsyncThrowingStream { continuation in
            continuation.yield(PushChannelV2.Element.syncMarker(
                id: Scaffolding.markerID,
                deliveryTag: Scaffolding.markerDeliveryTag
            ))
            continuation.finish()
        }

        pushChannel.acknowledgeEventDeliveryTagMultiple_MockMethod = { _, _ in }
        pushChannel.close_MockMethod = {}
        pushChannelAPI.createPushChannelClientIDMarker_MockMethod = { _, _ in pushChannel }

        // Events stored from NSE which needs to be processed
        setPendingEvents(envelopes: [
            (Scaffolding.typingEvent, NSManagedObjectID())
        ])

        // Pending events are deleted in batches.
        updateEventsStore.deleteNextPendingEventsWith_MockMethod = { _ in }

        // Live envelopes are peristed one by one and deleted by batch.
        updateEventsStore.persistEventEnvelopeIndex_MockMethod = { _, _ async throws in }
        updateEventsStore.deleteEventEnvelopesAt_MockMethod = { _ in }

        // Some indices at which live events will be stored.
        var indices = [Int64(10), Int64(11), Int64(12), Int64(13)]
        updateEventsStore.indexOfLastEventEnvelope_MockMethod = { indices.remove(at: 0) }

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

        // When
        _ = try await sut.perform()

        let numberOfPendingEvents = 1
        // Then stored events were processed, we fetch N+1 with N the number of envelopes
        XCTAssertEqual(updateEventsStore.fetchStoredEventEnvelopesLimit_Invocations.count, numberOfPendingEvents + 1)
        // typing event is skipped
        XCTAssertEqual(processor.processEvent_Invocations.count, 0)
        // typing event is deleted
        XCTAssertEqual(updateEventsStore.deleteNextPendingEventsWith_Invocations.count, numberOfPendingEvents)
        XCTAssertEqual(
            updateEventsStore.calculateLastUnreadMessages_Invocations.count,
            numberOfPendingEvents
        )
        XCTAssertEqual(databaseSaver.save_Invocations.count, numberOfPendingEvents)
    }

    func testPerform_MarkAsCloseWhenClosesPushChannel() async throws {

        // Mock
        liveDelegate.didFailSyncError_MockMethod = { _, _ in }

        // Some live events, some of which were already pulled.
        let pushChannel = MockPushChannelV2Protocol()
        pushChannel.close_MockMethod = {}
        pushChannel.open_MockValue = AsyncThrowingStream { continuation in
            continuation.finish(throwing: TestError(message: "something went wrong"))
        }

        pushChannel.acknowledgeEventDeliveryTagMultiple_MockMethod = { _, _ in }
        pushChannelAPI.createPushChannelClientIDMarker_MockMethod = { _, _ in pushChannel }

        // Events stored from NSE which needs to be processed
        setPendingEvents(envelopes: [])

        // Pending events are deleted in batches.
        updateEventsStore.deleteNextPendingEventsWith_MockMethod = { _ in }

        // Live envelopes are peristed one by one and deleted by batch.
        updateEventsStore.persistEventEnvelopeIndex_MockMethod = { _, _ async throws in }
        updateEventsStore.deleteEventEnvelopesAt_MockMethod = { _ in }

        // Some indices at which live events will be stored.
        var indices = [Int64(10)]
        updateEventsStore.indexOfLastEventEnvelope_MockMethod = { indices.remove(at: 0) }

        // Live events are decrypted.
        decryptor.decryptEventsInContext_MockMethod = { envelope, _ in
            EventDecryptorResult(events: envelope.events, brokenMLSGroupIDs: [])
        }

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
        await token.suspend()

        try XCTAssertCount(pushChannel.close_Invocations, count: 1)
        try XCTAssertCount(pushChannelState.markAsClosed_Invocations, count: 1)

    }

    func testPerform_ClosesPushChannelOnErrorProcessingPendingEvents() async throws {
        let expectedError = TestError(message: "error occured")
        // Mock
        liveDelegate.didFailSyncError_MockMethod = { _, _ in }

        // Some live events, some of which were already pulled.
        let pushChannel = MockPushChannelV2Protocol()

        pushChannel.close_MockMethod = {}
        pushChannel.open_MockValue = AsyncThrowingStream { continuation in
            continuation.finish()
        }

        pushChannel.acknowledgeEventDeliveryTagMultiple_MockMethod = { _, _ in }
        pushChannelAPI.createPushChannelClientIDMarker_MockMethod = { _, _ in pushChannel }

        // Events stored from NSE which needs to be processed
        updateEventsStore.fetchStoredEventEnvelopesLimit_MockError = expectedError

        // Pending events are deleted in batches.
        updateEventsStore.deleteNextPendingEventsWith_MockMethod = { _ in }

        // Live envelopes are peristed one by one and deleted by batch.
        updateEventsStore.persistEventEnvelopeIndex_MockMethod = { _, _ async throws in }
        updateEventsStore.deleteEventEnvelopesAt_MockMethod = { _ in }

        // Some indices at which live events will be stored.
        var indices = [Int64(10)]
        updateEventsStore.indexOfLastEventEnvelope_MockMethod = { indices.remove(at: 0) }

        // Live events are decrypted.
        decryptor.decryptEventsInContext_MockMethod = { envelope, _ in
            EventDecryptorResult(events: envelope.events, brokenMLSGroupIDs: [])
        }

        // Last event is being updated.
        updateEventsStore.storeLastEventIDId_MockMethod = { _ in }

        // Events are processed.
        processor.processEvent_MockMethod = { _ in }

        // Unread messages are set
        updateEventsStore.calculateLastUnreadMessages_MockMethod = {}

        // Database is saved.
        databaseSaver.save_MockMethod = {}

        // When
        await XCTAssertThrowsErrorAsync(expectedError) {
            _ = try await self.sut.perform()
        }

        try XCTAssertCount(pushChannel.close_Invocations, count: 1)
        try XCTAssertCount(pushChannelState.markAsClosed_Invocations, count: 1)

    }

    func testPerform_ThrowsIfNSEPushChannelAlreadyOpened() async throws {
        let expectedError = IncrementalSyncV2.Failure.nsePushChannelAlreadyOpened
        // Mock
        liveDelegate.didFailSyncError_MockMethod = { _, _ in }
        pushChannelState.markAsOpen_MockError = .some(PushChannelState.Failure.alreadyLocked(sameProcess: false))

        // When
        await XCTAssertThrowsErrorAsync(expectedError) {
            _ = try await self.sut.perform()
        }
    }

    func testPerform_ThrowsIfMainPushChannelAlreadyOpened() async throws {
        let expectedError = IncrementalSyncV2.Failure.mainAppPushChannelAlreadyOpened
        // Mock
        liveDelegate.didFailSyncError_MockMethod = { _, _ in }
        pushChannelState.markAsOpen_MockError = .some(PushChannelState.Failure.alreadyLocked(sameProcess: true))

        // When
        await XCTAssertThrowsErrorAsync(expectedError) {
            _ = try await self.sut.perform()
        }
    }

    private func setPendingEvents(envelopes: [(UpdateEventEnvelope, NSManagedObjectID)]) {
        var storedEnvelopes = envelopes
        updateEventsStore.fetchStoredEventEnvelopesLimit_MockMethod = { _ in
            let envelopes = storedEnvelopes
            storedEnvelopes = []
            return envelopes
        }
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

    static let typingEvent = UpdateEventEnvelope(
        id: UUID(),
        events: [
            UpdateEvent.conversation(.typing(.init(conversationID: ConversationID(
                id: UUID(),
                domain: "example.com"
            ), senderID: UserID(
                id: UUID(),
                domain: "example.com"
            ), isTyping: true)))
        ], isTransient: false,
        deliveryTag: 10
    )

    static let markerID = "marker-id"
    static let markerDeliveryTag: UInt64 = 123

    static func createEvent(
        message: String,
        timeIntervalSinceNow: TimeInterval,
        deliveryTag: UInt64? = nil
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
            isTransient: false,
            deliveryTag: deliveryTag
        )
    }

}
