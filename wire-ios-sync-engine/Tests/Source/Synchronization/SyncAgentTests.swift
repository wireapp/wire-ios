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
@testable import WireSyncEngine
@testable import WireDataModelSupport
@testable import WireDomainSupport

final class SyncAgentTests: XCTestCase {

    var sut: SyncAgent!
    var lastUpdateEventIDRepository: MockLastEventIDRepositoryInterface!
    var initialSyncBuilder: MockInitialSyncBuilderProtocol!
    var legacySyncStatus: MockSyncStatusProtocol!
    var initialSync: MockInitialSyncProtocol!

    override func setUp() {
        lastUpdateEventIDRepository = MockLastEventIDRepositoryInterface()
        initialSyncBuilder = MockInitialSyncBuilderProtocol()
        legacySyncStatus = MockSyncStatusProtocol()
        initialSync = MockInitialSyncProtocol()
        sut = SyncAgent(
            lastUpdateEventIDRepository: lastUpdateEventIDRepository,
            initialSyncBuilder: initialSyncBuilder,
            legacySyncStatus: legacySyncStatus
        )
        initialSyncBuilder.build_MockValue = initialSync
        DeveloperFlag.storage = .temporary()
    }

    override func tearDown() {
        sut = nil
        lastUpdateEventIDRepository = nil
        initialSyncBuilder = nil
        legacySyncStatus = nil
    }

    func testPerformSyncIfNeeded_InitialSync() async throws {
        // Given
        var flag = DeveloperFlag.newInitialSync
        flag.isOn = true

        // Mock
        lastUpdateEventIDRepository.fetchLastEventID_MockValue = .some(nil)
        initialSync.performSkipPullingLastUpdateEventID_MockMethod = { _ in }
        legacySyncStatus.performQuickSync_MockMethod = {}

        // When
        try await sut.performSyncIfNeeded()

        // Then
        XCTAssertEqual(initialSync.performSkipPullingLastUpdateEventID_Invocations, [false])
        XCTAssertEqual(legacySyncStatus.performQuickSync_Invocations.count, 1)
    }

    func testPerformSyncIfNeeded_IncrementalSync() async throws {
        // Given
        var flag = DeveloperFlag.newInitialSync
        flag.isOn = true

        // Mock
        lastUpdateEventIDRepository.fetchLastEventID_MockValue = .some(UUID())
        legacySyncStatus.performQuickSync_MockMethod = {}

        // When
        try await sut.performSyncIfNeeded()

        // Then
        XCTAssertEqual(initialSync.performSkipPullingLastUpdateEventID_Invocations.count, 0)
        XCTAssertEqual(legacySyncStatus.performQuickSync_Invocations.count, 1)
    }

    func testPerformInitialSync() async throws {
        // Given
        var flag = DeveloperFlag.newInitialSync
        flag.isOn = true

        // Mock
        initialSync.performSkipPullingLastUpdateEventID_MockMethod = { _ in }
        legacySyncStatus.performQuickSync_MockMethod = {}

        // When
        try await sut.performInitialSync()

        // Then
        XCTAssertEqual(initialSync.performSkipPullingLastUpdateEventID_Invocations, [false])
        XCTAssertEqual(legacySyncStatus.performQuickSync_Invocations.count, 1)
    }

    func testPerformInitialSync_Legacy() async throws {
        // Given
        var flag = DeveloperFlag.newInitialSync
        flag.isOn = false

        // Mock
        legacySyncStatus.forceSlowSync_MockMethod = {}

        // When
        try await sut.performInitialSync()

        // Then
        XCTAssertEqual(legacySyncStatus.forceSlowSync_Invocations.count, 1)
    }

    func testPerformResourceSync() async throws {
        // Given
        var flag = DeveloperFlag.newInitialSync
        flag.isOn = true

        // Mock
        initialSync.performSkipPullingLastUpdateEventID_MockMethod = { _ in }
        legacySyncStatus.performQuickSync_MockMethod = {}

        // When
        try await sut.performResourceSync()

        // Then
        XCTAssertEqual(initialSync.performSkipPullingLastUpdateEventID_Invocations, [true])
        XCTAssertEqual(legacySyncStatus.performQuickSync_Invocations.count, 1)
    }

    func testPerformResourceSync_Legacy() async throws {
        // Given
        var flag = DeveloperFlag.newInitialSync
        flag.isOn = false

        // Mock
        legacySyncStatus.resyncResources_MockMethod = {}

        // When
        try await sut.performResourceSync()

        // Then
        XCTAssertEqual(legacySyncStatus.resyncResources_Invocations.count, 1)
    }

    func testPerformIncrementalSync() async throws {
        // Mock
        legacySyncStatus.performQuickSync_MockMethod = {}

        // When
        try await sut.performIncrementalSync()

        // Then
        XCTAssertEqual(legacySyncStatus.performQuickSync_Invocations.count, 1)
    }

}
