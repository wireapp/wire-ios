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
import WireDomain
import WireDomainSupport
import XCTest

@testable import WireDataModelSupport
@testable import WireSyncEngine

final class SyncAgentTests: XCTestCase, InitialSyncProvider, IncrementalSyncProvider {

    var sut: SyncAgent!
    var journal: Journal!
    var lastUpdateEventIDRepository: MockLastEventIDRepositoryInterface!
    var legacySyncStatus: MockSyncStatusProtocol!
    var initialSync: MockInitialSyncProtocol!
    var incrementalSync: MockIncrementalSyncProtocol!
    var liveSync: MockLiveSyncProtocol!
    var networkStateSubject: CurrentValueSubject<NetworkState, Never>!
    var syncStateSubject: CurrentValueSubject<SyncState, Never>!
    var coreCryptoProvider: MockCoreCryptoProviderProtocol!
    var backgroundActivity: BackgroundActivityFactory!
    var backgroundActivityManager: MockBackgroundActivityManager!
    var featureConfigRepository: MockFeatureConfigRepositoryProtocol!
    var mainAppPushChannelCoordinator: MockMainAppPushChannelCoordinatorProtocol!
    var conversationUpdatesGenerator: MockConversationUpdatesGeneratorProtocol!

    var incrementalSyncDidFinish: XCTestExpectation!

    override func setUp() {
        journal = Journal(
            userID: UUID(),
            storage: UserDefaults.temporary()
        )
        lastUpdateEventIDRepository = MockLastEventIDRepositoryInterface()
        legacySyncStatus = MockSyncStatusProtocol()
        initialSync = MockInitialSyncProtocol()
        incrementalSync = MockIncrementalSyncProtocol()
        liveSync = MockLiveSyncProtocol()
        syncStateSubject = CurrentValueSubject(.idle)
        networkStateSubject = CurrentValueSubject(.online)
        coreCryptoProvider = MockCoreCryptoProviderProtocol()
        backgroundActivityManager = MockBackgroundActivityManager()
        backgroundActivity = BackgroundActivityFactory.shared
        backgroundActivity.backgroundTaskTimeout = 2
        backgroundActivity.activityManager = backgroundActivityManager
        featureConfigRepository = MockFeatureConfigRepositoryProtocol()
        mainAppPushChannelCoordinator = MockMainAppPushChannelCoordinatorProtocol()
        conversationUpdatesGenerator = MockConversationUpdatesGeneratorProtocol()
        conversationUpdatesGenerator.start_MockMethod = {}
        conversationUpdatesGenerator.stop_MockMethod = {}

        sut = SyncAgent(
            journal: journal,
            lastUpdateEventIDRepository: lastUpdateEventIDRepository,
            coreCryptoProvider: coreCryptoProvider,
            initialSyncProvider: self,
            incrementalSyncProvider: self,
            legacySyncStatus: legacySyncStatus,
            featureConfigRepository: featureConfigRepository,
            syncStateSubject: syncStateSubject,
            pushChannelCoordinator: mainAppPushChannelCoordinator,
            conversationUpdatesGenerator: conversationUpdatesGenerator,
            networkStatePublisher: networkStateSubject.eraseToAnyPublisher()
        )

        incrementalSyncDidFinish = XCTestExpectation(description: "incrementalSyncDidFinish")
    }

    override func tearDown() {
        sut = nil
        journal = nil
        lastUpdateEventIDRepository = nil
        legacySyncStatus = nil
        initialSync = nil
        incrementalSync = nil
        liveSync = nil
        syncStateSubject = nil
        backgroundActivityManager.reset()
        backgroundActivityManager = nil
        backgroundActivity = nil
        featureConfigRepository = nil
        mainAppPushChannelCoordinator = nil
        conversationUpdatesGenerator = nil
        incrementalSyncDidFinish = nil
    }

    func provideInitialSync() throws -> any InitialSyncProtocol {
        initialSync
    }

    func provideIncrementalSync() throws -> any IncrementalSyncProtocol {
        incrementalSync
    }

    func testNetworkStateChangeResumeSync() async throws {
        // GIVEN
        journal[.isSyncV2Enabled] = true
        journal[.isInitialSyncRequired] = false

        incrementalSync.perform_MockMethod = {
            IncrementalSync.Token(
                task: Task {},
                closePushChannel: {}
            )
        }
        XCTAssertFalse(sut.syncRunning)
        sut.delegate = self

        // WHEN
        networkStateSubject.send(.offline)
        networkStateSubject.send(.online)

        // THEN
        wait(for: [incrementalSyncDidFinish], timeout: 2)
    }

    func testPerformSyncIfNeeded_InitialSync() async throws {
        // Given
        journal[.isSyncV2Enabled] = true
        journal[.isInitialSyncRequired] = true

        // Mock
        lastUpdateEventIDRepository.fetchLastEventID_MockValue = .some(nil)
        initialSync.performSkipPullingLastUpdateEventID_MockMethod = { _ in }
        incrementalSync.perform_MockMethod = {
            IncrementalSync.Token(
                task: Task {},
                closePushChannel: {}
            )
        }
        legacySyncStatus.performQuickSync_MockMethod = {}
        featureConfigRepository.isFeatureEnabled_MockValue = false

        // When
        try await sut.performSync()

        // Then
        XCTAssertEqual(initialSync.performSkipPullingLastUpdateEventID_Invocations, [false])
        XCTAssertEqual(incrementalSync.perform_Invocations.count, 1)
    }

    func testPerformSyncIfNeeded_IncrementalSync() async throws {
        // Given
        journal[.isSyncV2Enabled] = true

        // Mock
        lastUpdateEventIDRepository.fetchLastEventID_MockValue = .some(UUID())
        incrementalSync.perform_MockMethod = {
            IncrementalSync.Token(
                task: Task {},
                closePushChannel: {}
            )
        }
        featureConfigRepository.isFeatureEnabled_MockValue = false

        // When
        try await sut.performSync()

        // Then
        XCTAssertEqual(initialSync.performSkipPullingLastUpdateEventID_Invocations.count, 0)
        XCTAssertEqual(incrementalSync.perform_Invocations.count, 1)
    }

    func testPerformInitialSync() async throws {
        // Given
        journal[.isSyncV2Enabled] = true

        // Mock
        initialSync.performSkipPullingLastUpdateEventID_MockMethod = { _ in }
        incrementalSync.perform_MockMethod = {
            IncrementalSync.Token(
                task: Task {},
                closePushChannel: {}
            )
        }
        featureConfigRepository.isFeatureEnabled_MockValue = false

        // When
        try await sut.performInitialSync()

        // Then
        XCTAssertEqual(initialSync.performSkipPullingLastUpdateEventID_Invocations, [false])
        XCTAssertEqual(incrementalSync.perform_Invocations.count, 1)
    }

    func testPerformInitialSync_Legacy() async throws {
        // Given
        journal[.isSyncV2Enabled] = false

        // Mock
        legacySyncStatus.forceSlowSync_MockMethod = {}
        featureConfigRepository.isFeatureEnabled_MockValue = false

        // When
        try await sut.performInitialSync()

        // Then
        XCTAssertEqual(legacySyncStatus.forceSlowSync_Invocations.count, 1)
    }

    func testPerformResourceSync() async throws {
        // Given
        journal[.isSyncV2Enabled] = true

        // Mock
        initialSync.performSkipPullingLastUpdateEventID_MockMethod = { _ in }
        incrementalSync.perform_MockMethod = {
            IncrementalSync.Token(
                task: Task {},
                closePushChannel: {}
            )
        }
        featureConfigRepository.isFeatureEnabled_MockValue = false

        // When
        try await sut.performResourceSync()

        // Then
        XCTAssertEqual(initialSync.performSkipPullingLastUpdateEventID_Invocations, [true])
        XCTAssertEqual(incrementalSync.perform_Invocations.count, 1)
    }

    func testPerformResourceSync_Legacy() async throws {
        // Given
        journal[.isSyncV2Enabled] = false

        // Mock
        legacySyncStatus.resyncResources_MockMethod = {}
        featureConfigRepository.isFeatureEnabled_MockValue = false

        // When
        try await sut.performResourceSync()

        // Then
        XCTAssertEqual(legacySyncStatus.resyncResources_Invocations.count, 1)
    }

    func testPerformIncrementalSync() async throws {
        // Given
        journal[.isSyncV2Enabled] = true

        // Mock
        incrementalSync.perform_MockMethod = {
            IncrementalSync.Token(
                task: Task {},
                closePushChannel: {}
            )
        }
        featureConfigRepository.isFeatureEnabled_MockValue = false

        // When
        try await sut.performIncrementalSync()

        // Then
        XCTAssertEqual(incrementalSync.perform_Invocations.count, 1)
    }

    func testPerformIncrementalSync_Sync_State_Update_To_Suspended_When_Throwing_Error() async throws {
        // Given
        journal[.isSyncV2Enabled] = true
        let expectation = XCTestExpectation()

        enum Failure: Error {
            case failed
        }

        // Mock
        incrementalSync.perform_MockMethod = {
            throw Failure.failed
        }
        featureConfigRepository.isFeatureEnabled_MockValue = false

        var cancellable: AnyCancellable?

        cancellable = syncStateSubject
            .dropFirst()
            .sink { state in
                switch state {
                case .suspended:
                    // Then
                    expectation.fulfill()
                default:
                    XCTFail("Sync should be suspended when an error is thrown")
                }
            }

        do {
            // When
            try await sut.performIncrementalSync()
        } catch {}

        await fulfillment(of: [expectation])

        try XCTAssertCount(conversationUpdatesGenerator.start_Invocations, count: 1)
    }

    func testSuspend_Sync_State_Update_To_Suspended_And_Background_Task_Is_Active() async throws {
        // Given
        journal[.isSyncV2Enabled] = true
        let expectation = XCTestExpectation()

        enum Failure: Error {
            case failed
        }

        // Mock
        incrementalSync.perform_MockMethod = {
            throw Failure.failed
        }
        lastUpdateEventIDRepository.fetchLastEventID_MockValue = .mockID1

        var cancellable: AnyCancellable?

        cancellable = syncStateSubject
            .dropFirst()
            .sink { state in
                switch state {
                case .suspended:
                    // Then
                    XCTAssertEqual(BackgroundActivityFactory.shared.isActive, true)
                    expectation.fulfill()
                default:
                    XCTFail("Sync should be suspended")
                }
            }

        // When
        await sut.suspend()

        await fulfillment(of: [expectation])

        try XCTAssertCount(conversationUpdatesGenerator.stop_Invocations, count: 1)
    }

    func provideLiveSync(delegate: any WireDomain.LiveSyncDelegate) throws -> any WireDomain.LiveSyncProtocol {

        liveSync
    }

    func testPerformIncrementalSync_V3() async throws {
        // Given
        featureConfigRepository.isFeatureEnabled_MockValue = true
        journal[.isConsumableNotificationsEnabled] = true
        journal[.isSyncV2Enabled] = true

        // Mock
        liveSync.perform_MockMethod = {
            IncrementalSync.Token(
                task: Task {},
                closePushChannel: {}
            )
        }

        // When
        try await sut.performIncrementalSync()

        // Then
        XCTAssertEqual(liveSync.perform_Invocations.count, 1)
    }
}

extension SyncAgentTests: SyncAgentDelegate {
    func syncAgentDidStartInitialSync(_ syncAgent: WireSyncEngine.SyncAgent) {}

    func syncAgentDidFinishInitialSync(_ syncAgent: WireSyncEngine.SyncAgent) {}

    func syncAgentDidStartIncrementalSync(_ syncAgent: WireSyncEngine.SyncAgent) {}

    func syncAgentDidFinishIncrementalSync(_ syncAgent: WireSyncEngine.SyncAgent, isRecovering: Bool) {
        incrementalSyncDidFinish.fulfill()
    }

    func syncAgentDidFailSyncing(_ syncAgent: WireSyncEngine.SyncAgent, error: any Error) {}

    func syncAgentDidStartLegacyInitialSync(_ syncAgent: WireSyncEngine.SyncAgent) {}

    func syncAgentDidFinishLegacyInitialSync(_ syncAgent: WireSyncEngine.SyncAgent) {}

    func syncAgentDidStartLegacyIncrementalSync(_ syncAgent: WireSyncEngine.SyncAgent) {}

    func syncAgentDidFinishLegacyIncrementalSync(_ syncAgent: WireSyncEngine.SyncAgent, isRecovering: Bool) {}

}
