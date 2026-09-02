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
import WireDomain
import WireDomainSupport
import WireSystem
import XCTest

@testable import WireDataModelSupport
@testable import WireSyncEngine

final class SyncAgentTests: XCTestCase, InitialSyncProvider, IncrementalSyncProvider {

    var sut: SyncAgent!
    var journal: Journal!
    var lastUpdateEventIDRepository: MockLastEventIDRepositoryInterface!
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

    var incrementalSyncDidFinish: XCTestExpectation!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        journal = Journal(
            userID: UUID(),
            storage: UserDefaults.temporary()
        )
        lastUpdateEventIDRepository = MockLastEventIDRepositoryInterface()
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

        sut = SyncAgent(
            journal: journal,
            coreCryptoProvider: coreCryptoProvider,
            initialSyncProvider: self,
            incrementalSyncProvider: self,
            featureConfigRepository: featureConfigRepository,
            syncStateSubject: syncStateSubject,
            pushChannelCoordinator: mainAppPushChannelCoordinator,
            networkStatePublisher: networkStateSubject.eraseToAnyPublisher(),
            backgroundTaskExecuter: PassthroughTaskExecuter()
        )

        incrementalSyncDidFinish = XCTestExpectation(description: "incrementalSyncDidFinish")
        cancellables = []
    }

    override func tearDown() {
        sut = nil
        journal = nil
        lastUpdateEventIDRepository = nil
        initialSync = nil
        incrementalSync = nil
        liveSync = nil
        syncStateSubject = nil
        backgroundActivityManager.reset()
        backgroundActivityManager = nil
        backgroundActivity = nil
        featureConfigRepository = nil
        mainAppPushChannelCoordinator = nil
        incrementalSyncDidFinish = nil
        cancellables = nil
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
        await fulfillment(of: [incrementalSyncDidFinish], timeout: 2)
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
        featureConfigRepository.isFeatureEnabled_MockValue = false

        // When
        try await sut.performSync()

        // Then
        XCTAssertEqual(initialSync.performSkipPullingLastUpdateEventID_Invocations, [false])
        XCTAssertEqual(incrementalSync.perform_Invocations.count, 1)
    }

    func testPerformSyncIfNeeded_ResourcesSync() async throws {
        // Given
        journal[.isResourcesSyncRequired] = true

        // Mock
        initialSync.performSkipPullingLastUpdateEventID_MockMethod = { _ in }
        incrementalSync.perform_MockMethod = {
            IncrementalSync.Token(
                task: Task {},
                closePushChannel: {}
            )
        }

        // When
        try await sut.performSync()

        // Then
        XCTAssertEqual(initialSync.performSkipPullingLastUpdateEventID_Invocations, [true])
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
    }

    func testSuspend_Sync_State_Update_To_Suspended_And_Background_Task_Is_Active() async throws {
        // Given
        journal[.isSyncV2Enabled] = true

        enum Failure: Error {
            case failed
        }
        incrementalSync.perform_MockMethod = { throw Failure.failed }
        lastUpdateEventIDRepository.fetchLastEventID_MockValue = .mockID1

        // Then — assertion fires inside the sink, synchronously during send(.suspended),
        // before endBackgroundActivity runs.
        let suspended = expectationForSyncSuspended {
            XCTAssertEqual(BackgroundActivityFactory.shared.isActive, true)
        }

        // When
        await sut.suspend()

        await fulfillment(of: [suspended])
    }

    func test_TearDown_NilsDelegate() async {
        // Given
        sut.delegate = self

        let suspended = expectationForSyncSuspended()

        // When
        sut.tearDown()
        await fulfillment(of: [suspended])

        // Then
        XCTAssertNil(sut.delegate)
    }

    func test_TearDown_SuspendsPushChannel() async throws {
        // Given
        journal[.isSyncV2Enabled] = true
        let pushChannelClosed = expectation(description: "push channel closed")

        incrementalSync.perform_MockMethod = {
            IncrementalSync.Token(
                task: Task { try? await Task.sleep(nanoseconds: 10_000_000_000) },
                closePushChannel: { pushChannelClosed.fulfill() }
            )
        }

        let suspended = expectationForSyncSuspended()

        // Start an incremental sync to get an active token with a push channel
        try await sut.performIncrementalSync()

        // When
        sut.tearDown()

        // Then — wait for both: push channel closed and suspend() fully completed
        // (ensures endBackgroundActivity is called before the next test starts)
        await fulfillment(of: [pushChannelClosed, suspended], timeout: 2)
    }

    func test_Resume_DuringSuspensionStartsNewSyncAfterSuspensionCompletes() async throws {
        // Given an existing incremental sync
        journal[.isSyncV2Enabled] = true
        sut.delegate = self

        let firstSyncStarted = expectation(description: "first sync started")
        let secondSyncStarted = expectation(description: "second sync started")
        let invocationCounter = InvocationCounter()
        let gate = TestGate()

        incrementalSync.perform_MockMethod = {
            let invocation = await invocationCounter.increment()

            let task: Task<Void, Never>
            switch invocation {
            case 1:
                task = Task { await gate.wait() }
                firstSyncStarted.fulfill()
            case 2:
                task = Task {}
                secondSyncStarted.fulfill()
            default:
                task = Task {}
                XCTFail("Unexpected invocation count: \(invocation)")
            }

            return IncrementalSync.Token(task: task, closePushChannel: {})
        }

        sut.resume()
        await fulfillment(of: [firstSyncStarted], timeout: 2)

        // When the sync is suspended and resumed before the suspension completes
        let suspensionTask = Task { [sut] in
            await sut?.suspend()
        }

        sut.resume()

        let invocationsBeforeSuspensionCompleted = await invocationCounter.value
        XCTAssertEqual(invocationsBeforeSuspensionCompleted, 1)

        await gate.open()
        await suspensionTask.value

        // Then a new resume starts after the suspension completes
        await fulfillment(of: [secondSyncStarted], timeout: 2)
        let invocationsAfterSuspensionCompleted = await invocationCounter.value
        XCTAssertEqual(invocationsAfterSuspensionCompleted, 2)
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

    // MARK: - Helpers

    private func expectationForSyncSuspended(onSuspended: (() -> Void)? = nil) -> XCTestExpectation {
        let suspended = expectation(description: "sync suspended")
        syncStateSubject
            .filter { if case .suspended = $0 { true } else { false } }
            .sink { _ in
                onSuspended?()
                suspended.fulfill()
            }
            .store(in: &cancellables)
        return suspended
    }

    func provideLiveSync(delegate: any WireDomain.LiveSyncDelegate) throws -> any WireDomain.LiveSyncProtocol {

        liveSync
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

}

private actor InvocationCounter {

    private(set) var value = 0

    func increment() -> Int {
        value += 1
        return value
    }
}

private actor TestGate {

    private var isOpen = false
    private var continuations: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        if isOpen { return }
        await withCheckedContinuation { continuations.append($0) }
    }

    func open() {
        guard !isOpen else { return }
        isOpen = true
        let toResume = continuations
        continuations = []
        for continuation in toResume {
            continuation.resume()
        }
    }
}
