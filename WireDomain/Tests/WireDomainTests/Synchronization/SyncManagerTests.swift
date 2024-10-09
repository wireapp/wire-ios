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

import Combine
import WireAPI
import WireAPISupport
import WireDataModel
import WireDataModelSupport
@testable import WireDomain
@testable import WireDomainSupport
import XCTest

final class SyncManagerTests: XCTestCase {

    private var sut: SyncManager!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var stack: CoreDataStack!
    private var modelHelper: ModelHelper!
    private var updateEventsRepository: MockUpdateEventsRepositoryProtocol!
    private var updateEventProcessor: MockUpdateEventProcessorProtocol!
    private var teamRepository: MockTeamRepositoryProtocol!
    private var connectionsRepository: MockConnectionsRepositoryProtocol!
    private var conversationsRepository: MockConversationRepositoryProtocol!
    private var userRepository: MockUserRepositoryProtocol!
    private var conversationLabelsRepository: MockConversationLabelsRepositoryProtocol!
    private var featureConfigsRepository: MockFeatureConfigRepositoryProtocol!
    private var pushSupportedProtocolsUseCase: MockPushSupportedProtocolsUseCaseProtocol!
    private var mlsService: MockMLSServiceInterface!

    var context: NSManagedObjectContext {
        stack.syncContext
    }

    override func setUp() async throws {
        try await super.setUp()
        coreDataStackHelper = CoreDataStackHelper()
        stack = try await coreDataStackHelper.createStack()
        mlsService = MockMLSServiceInterface()
        modelHelper = ModelHelper()
        updateEventsRepository = MockUpdateEventsRepositoryProtocol()
        updateEventProcessor = MockUpdateEventProcessorProtocol()
        teamRepository = MockTeamRepositoryProtocol()
        connectionsRepository = MockConnectionsRepositoryProtocol()
        conversationsRepository = MockConversationRepositoryProtocol()
        userRepository = MockUserRepositoryProtocol()
        conversationLabelsRepository = MockConversationLabelsRepositoryProtocol()
        featureConfigsRepository = MockFeatureConfigRepositoryProtocol()
        pushSupportedProtocolsUseCase = MockPushSupportedProtocolsUseCaseProtocol()

        sut = SyncManager(
            updateEventsRepository: updateEventsRepository,
            teamRepository: teamRepository,
            connectionsRepository: connectionsRepository,
            conversationsRepository: conversationsRepository,
            userRepository: userRepository,
            conversationLabelsRepository: conversationLabelsRepository,
            featureConfigsRepository: featureConfigsRepository,
            updateEventProcessor: updateEventProcessor,
            pushSupportedProtocolsUseCase: pushSupportedProtocolsUseCase,
            mlsProvider: MLSProvider(service: mlsService, isMLSEnabled: true),
            context: context
        )

        // Base mocks.
        updateEventsRepository.startBufferingLiveEvents_MockValue = AsyncThrowingStream { _ in }
        updateEventsRepository.stopReceivingLiveEvents_MockMethod = {}
        updateEventsRepository.pullPendingEvents_MockMethod = {}
        updateEventsRepository.fetchNextPendingEventsLimit_MockValue = []
        updateEventsRepository.deleteNextPendingEventsLimit_MockMethod = { _ in }
        updateEventsRepository.storeLastEventEnvelopeID_MockMethod = { _ in }
        updateEventProcessor.processEvent_MockMethod = { _ in }
    }

    override func tearDown() async throws {
        try await super.tearDown()
        sut = nil
        modelHelper = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
        stack = nil
        mlsService = nil
        updateEventsRepository = nil
        updateEventProcessor = nil
        teamRepository = nil
        connectionsRepository = nil
        conversationsRepository = nil
        userRepository = nil
        conversationLabelsRepository = nil
        featureConfigsRepository = nil
        pushSupportedProtocolsUseCase = nil
    }

    // MARK: - Tests

    func testItStartsSuspended() async throws {
        // Given we just initialized the sync manager.

        // Then it's suspended.
        guard case .suspended = sut.syncState else {
            XCTFail("unexpected sync state: \(sut.syncState)")
            return
        }

        // Then is has not requested any live events.
        XCTAssertTrue(updateEventsRepository.startBufferingLiveEvents_Invocations.isEmpty)
    }

    // MARK: - Suspension

    func testItDoesNotSuspendIfItIsAlreadySuspended() async throws {
        // Given it's already suspended.
        guard case .suspended = sut.syncState else {
            XCTFail("unexpected sync state: \(sut.syncState)")
            return
        }

        // When
        try await sut.suspend()

        // Then it didn't do anything.
        XCTAssertTrue(updateEventsRepository.stopReceivingLiveEvents_Invocations.isEmpty)
    }

    func testItSuspendsWhenLive() async throws {
        // Given it goes live.
        try await sut.performQuickSync()

        guard case .live = sut.syncState else {
            XCTFail("unexpected sync state: \(sut.syncState)")
            return
        }

        // When it suspends.
        try await sut.suspend()

        // Then the push channel was closed.
        XCTAssertEqual(updateEventsRepository.stopReceivingLiveEvents_Invocations.count, 1)

        // Then it goes to the suspended state.
        guard case .suspended = sut.syncState else {
            XCTFail("unexpected sync state: \(sut.syncState)")
            return
        }
    }

    func testItSuspendsWhenQuickSyncing() async throws {
        let didPullEvents = XCTestExpectation()
        let didSuspend = XCTestExpectation()

        updateEventsRepository.pullPendingEvents_MockMethod = {
            didPullEvents.fulfill()
        }

        updateEventsRepository.fetchNextPendingEventsLimit_MockMethod = { _ in
            // Wait here until we suspend.
            await self.fulfillment(of: [didSuspend])
            return [Scaffolding.makeEnvelope(with: Scaffolding.event1)]
        }

        let ongoingQuickSync = Task {
            // Given we are quick syncing.
            try await sut.performQuickSync()
        }

        // Let quick sync run, wait until it pulls events.
        await fulfillment(of: [didPullEvents])

        // When it suspends.
        try await sut.suspend()
        didSuspend.fulfill()

        do {
            // Wait for the quick sync to finish.
            try await ongoingQuickSync.value
            XCTFail("expected the quick sync to cancel but it did not")
            return
        } catch is CancellationError {
            // Then the quick sync was cancelled.
        } catch {
            XCTFail("expected a cancellation error but got: \(error)")
            return
        }

        // Then the push channel was closed.
        XCTAssertEqual(updateEventsRepository.stopReceivingLiveEvents_Invocations.count, 1)

        // Then it goes to the suspended state.
        guard case .suspended = sut.syncState else {
            XCTFail("unexpected sync state: \(sut.syncState)")
            return
        }
    }

    // MARK: - Quick sync

    func testItQuickSyncs() async throws {
        // Given no stored events.
        var storedEvents = [UpdateEventEnvelope]()

        // Mock live event stream.
        var liveEventsContinuation: AsyncThrowingStream<UpdateEventEnvelope, Error>.Continuation?
        updateEventsRepository.startBufferingLiveEvents_MockValue = AsyncThrowingStream { continuation in
            liveEventsContinuation = continuation
        }

        // Mock pull events from remote, store locally.
        updateEventsRepository.pullPendingEvents_MockMethod = {
            storedEvents = [
                Scaffolding.makeEnvelope(with: Scaffolding.event1),
                Scaffolding.makeEnvelope(with: Scaffolding.event2),
                Scaffolding.makeEnvelope(with: Scaffolding.event3)
            ]
        }

        // Mock fetch the next batch.
        updateEventsRepository.fetchNextPendingEventsLimit_MockMethod = { limit in
            Array(storedEvents.prefix(Int(limit)))
        }

        // Mock delete the next batch.
        updateEventsRepository.deleteNextPendingEventsLimit_MockMethod = { limit in
            storedEvents = Array(storedEvents.dropFirst(Int(limit)))
        }

        let didProcessEvent = XCTestExpectation()
        let didProcessEvent5 = XCTestExpectation()
        let didPushLiveEvents = XCTestExpectation()

        updateEventProcessor.processEvent_MockMethod = { event in
            switch event {
            case Scaffolding.event1:
                didProcessEvent.fulfill()

            case Scaffolding.event2:
                // Stop processing, wait for live events.
                await self.fulfillment(of: [didPushLiveEvents])

            case Scaffolding.event5:
                didProcessEvent5.fulfill()

            default:
                break
            }
        }

        // Run in another task so we can send events through the push channel.
        let whenTask = Task.detached {
            // When
            try await self.sut.performQuickSync()
        }

        // Wait for event 1 to be processed.
        await fulfillment(of: [didProcessEvent])

        // Push 2 live events through push channel
        let liveEnvelope1 = Scaffolding.makeEnvelope(
            with: Scaffolding.event4,
            isTransient: true
        )
        liveEventsContinuation?.yield(liveEnvelope1)

        let liveEnvelope2 = Scaffolding.makeEnvelope(
            with: Scaffolding.event5,
            isTransient: false
        )
        liveEventsContinuation?.yield(liveEnvelope2)
        didPushLiveEvents.fulfill()

        // Wait for "when" to finish.
        try await whenTask.value

        // We also need to wait to get the two live events...
        await fulfillment(of: [didProcessEvent5])

        // Then it requested live events.
        XCTAssertEqual(updateEventsRepository.startBufferingLiveEvents_Invocations.count, 1)

        // Then it pulls pending events.
        XCTAssertEqual(updateEventsRepository.pullPendingEvents_Invocations.count, 1)

        // Then it tries to fetch 2 event batches (1st is non-empty, 2nd is empty).
        XCTAssertEqual(updateEventsRepository.fetchNextPendingEventsLimit_Invocations, [500, 500])

        // Then it processed 5 events, in the correct order.
        let processEventInvocations = updateEventProcessor.processEvent_Invocations

        guard processEventInvocations.count == 5 else {
            XCTFail("expected 5 events to be processed, got \(processEventInvocations.count)")
            return
        }

        // These were the stored events.
        XCTAssertEqual(processEventInvocations[0], Scaffolding.event1)
        XCTAssertEqual(processEventInvocations[1], Scaffolding.event2)
        XCTAssertEqual(processEventInvocations[2], Scaffolding.event3)

        // These were the buffered events.
        XCTAssertEqual(processEventInvocations[3], Scaffolding.event4)
        XCTAssertEqual(processEventInvocations[4], Scaffolding.event5)

        // Then it deleted 1 batch (i.e all) of the stored events.
        XCTAssertEqual(updateEventsRepository.deleteNextPendingEventsLimit_Invocations, [500])
        XCTAssertTrue(storedEvents.isEmpty)

        // Then it update the last event id for the non-transient live events.
        XCTAssertEqual(
            updateEventsRepository.storeLastEventEnvelopeID_Invocations,
            [liveEnvelope2.id]
        )

        // Then it is live.
        guard case .live = sut.syncState else {
            XCTFail("unexpected sync state: \(sut.syncState)")
            return
        }

        XCTAssertEqual(updateEventsRepository.stopReceivingLiveEvents_Invocations.count, 0)
    }

    func testPerformSlowSync() async throws {

        // Mock
        
        let user = await context.perform { [self] in
            modelHelper.createUser(in: context)
        }

        let selfUser = await context.perform { [self] in
            modelHelper.createSelfUser(in: context)
        }

        let conversation = await context.perform { [self] in
            modelHelper.createGroupConversation(in: context)
        }

        updateEventsRepository.pullLastEventID_MockMethod = {}
        teamRepository.pullSelfTeam_MockMethod = {}
        teamRepository.pullSelfTeamRoles_MockMethod = {}
        teamRepository.pullSelfTeamMembers_MockMethod = {}
        connectionsRepository.pullConnections_MockMethod = {}
        conversationsRepository.pullConversations_MockMethod = {}
        conversationsRepository.pullMLSOneToOneConversationUserIDDomain_MockValue = UUID().uuidString
        conversationsRepository.fetchMLSConversationWith_MockValue = conversation
        userRepository.pullKnownUsers_MockMethod = {}
        conversationLabelsRepository.pullConversationLabels_MockMethod = {}
        featureConfigsRepository.pullFeatureConfigs_MockMethod = {}
        userRepository.pullSelfUser_MockMethod = {}
        teamRepository.pullSelfLegalHoldStatus_MockMethod = {}
        pushSupportedProtocolsUseCase.invoke_MockMethod = {}
        userRepository.fetchAllUserIdsWithOneOnOneConversation_MockMethod = { [] }
        userRepository.fetchUserWithDomain_MockValue = user
        userRepository.fetchSelfUser_MockValue = selfUser
        mlsService.conversationExistsGroupID_MockValue = true
        mlsService.establishGroupForWithRemovalKeys_MockValue = .MLS_128_DHKEMP256_AES128GCM_SHA256_P256
        mlsService.joinGroupWith_MockMethod = { _ in }

        // When

        try await sut.performSlowSync()

        // Then

        XCTAssertEqual(updateEventsRepository.pullLastEventID_Invocations.count, 1)
        XCTAssertEqual(teamRepository.pullSelfTeam_Invocations.count, 1)
        XCTAssertEqual(teamRepository.pullSelfTeamRoles_Invocations.count, 1)
        XCTAssertEqual(teamRepository.pullSelfTeamMembers_Invocations.count, 1)
        XCTAssertEqual(connectionsRepository.pullConnections_Invocations.count, 1)
        XCTAssertEqual(conversationsRepository.pullConversations_Invocations.count, 1)
        XCTAssertEqual(userRepository.pullKnownUsers_Invocations.count, 1)
        XCTAssertEqual(conversationLabelsRepository.pullConversationLabels_Invocations.count, 1)
        XCTAssertEqual(featureConfigsRepository.pullFeatureConfigs_Invocations.count, 1)
        XCTAssertEqual(userRepository.pullSelfUser_Invocations.count, 1)
        XCTAssertEqual(teamRepository.pullSelfLegalHoldStatus_Invocations.count, 1)
        XCTAssertEqual(pushSupportedProtocolsUseCase.invoke_Invocations.count, 1)
    }

}

private enum Scaffolding {

    static let localDomain = "example.com"
    static let conversationID1 = ConversationID(uuid: UUID(), domain: localDomain)
    static let conversationID2 = ConversationID(uuid: UUID(), domain: localDomain)
    static let aliceID = UserID(uuid: UUID(), domain: localDomain)

    static let event1 = UpdateEvent.user(.clientAdd(UserClientAddEvent(client: UserClient(
        id: "userClientID",
        type: .permanent,
        activationDate: .now,
        capabilities: [.legalholdConsent]
    ))))

    static let event2 = UpdateEvent.conversation(.typing(ConversationTypingEvent(
        conversationID: conversationID1,
        senderID: aliceID,
        isTyping: true
    )))

    static let event3 = UpdateEvent.conversation(.delete(ConversationDeleteEvent(
        conversationID: conversationID1,
        senderID: aliceID,
        timestamp: .now
    )))

    static let event4 = UpdateEvent.conversation(.rename(ConversationRenameEvent(
        conversationID: conversationID2,
        senderID: aliceID,
        timestamp: .now,
        newName: "Foo"
    )))

    static let event5 = UpdateEvent.conversation(.rename(ConversationRenameEvent(
        conversationID: conversationID2,
        senderID: aliceID,
        timestamp: .now,
        newName: "Bar"
    )))

    static func makeEnvelope(
        with event: UpdateEvent,
        isTransient: Bool = false
    ) -> UpdateEventEnvelope {
        .init(
            id: UUID(),
            events: [event],
            isTransient: isTransient
        )
    }

}
