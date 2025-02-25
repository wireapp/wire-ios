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

import WireDomain
import XCTest
@testable import WireDataModelSupport
@testable import WireDomainSupport
@testable import WireSyncEngine

final class SyncAgentTests: XCTestCase, InitialSyncProvider, IncrementalSyncProvider {

    var sut: SyncAgent!
    var lastUpdateEventIDRepository: MockLastEventIDRepositoryInterface!
    var legacySyncStatus: MockSyncStatusProtocol!
    var initialSync: MockInitialSyncProtocol!
    var incrementalSync: MockIncrementalSyncProtocol!

    override func setUp() {
        lastUpdateEventIDRepository = MockLastEventIDRepositoryInterface()
        legacySyncStatus = MockSyncStatusProtocol()
        initialSync = MockInitialSyncProtocol()
        incrementalSync = MockIncrementalSyncProtocol()
        sut = SyncAgent(
            lastUpdateEventIDRepository: lastUpdateEventIDRepository,
            initialSyncProvider: self,
            incrementalSyncProvider: self,
            legacySyncStatus: legacySyncStatus
        )
    }

    override func tearDown() {
        sut = nil
        lastUpdateEventIDRepository = nil
        legacySyncStatus = nil
        initialSync = nil
        incrementalSync = nil
        DeveloperFlag.newInitialSync.enable(false, storage: .temporary())
    }

    func provideInitialSync() throws -> any InitialSyncProtocol {
        initialSync
    }

    func provideIncrementalSync() throws -> any IncrementalSyncProtocol {
        incrementalSync
    }

    func testPerformSyncIfNeeded_InitialSync() async throws {
        // Given
        DeveloperFlag.newInitialSync.enable(true, storage: .temporary())

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

        // When
        try await sut.performSync()

        // Then
        XCTAssertEqual(initialSync.performSkipPullingLastUpdateEventID_Invocations, [false])
        XCTAssertEqual(incrementalSync.perform_Invocations.count, 1)
    }

    func testPerformSyncIfNeeded_IncrementalSync() async throws {
        // Given
        DeveloperFlag.newInitialSync.enable(true, storage: .temporary())

        // Mock
        lastUpdateEventIDRepository.fetchLastEventID_MockValue = .some(UUID())
        incrementalSync.perform_MockMethod = {
            IncrementalSync.Token(
                task: Task {},
                closePushChannel: {}
            )
        }

        // When
        try await sut.performSync()

        // Then
        XCTAssertEqual(initialSync.performSkipPullingLastUpdateEventID_Invocations.count, 0)
        XCTAssertEqual(incrementalSync.perform_Invocations.count, 1)
    }

    func testPerformInitialSync() async throws {
        // Given
        DeveloperFlag.newInitialSync.enable(true, storage: .temporary())

        // Mock
        initialSync.performSkipPullingLastUpdateEventID_MockMethod = { _ in }
        incrementalSync.perform_MockMethod = {
            IncrementalSync.Token(
                task: Task {},
                closePushChannel: {}
            )
        }

        // When
        try await sut.performInitialSync()

        // Then
        XCTAssertEqual(initialSync.performSkipPullingLastUpdateEventID_Invocations, [false])
        XCTAssertEqual(incrementalSync.perform_Invocations.count, 1)
    }

    func testPerformInitialSync_Legacy() async throws {
        // Given
        DeveloperFlag.newInitialSync.enable(false, storage: .temporary())

        // Mock
        legacySyncStatus.forceSlowSync_MockMethod = {}

        // When
        try await sut.performInitialSync()

        // Then
        XCTAssertEqual(legacySyncStatus.forceSlowSync_Invocations.count, 1)
    }

    func testPerformResourceSync() async throws {
        // Given
        DeveloperFlag.newInitialSync.enable(true, storage: .temporary())

        // Mock
        initialSync.performSkipPullingLastUpdateEventID_MockMethod = { _ in }
        incrementalSync.perform_MockMethod = {
            IncrementalSync.Token(
                task: Task {},
                closePushChannel: {}
            )
        }

        // When
        try await sut.performResourceSync()

        // Then
        XCTAssertEqual(initialSync.performSkipPullingLastUpdateEventID_Invocations, [true])
        XCTAssertEqual(incrementalSync.perform_Invocations.count, 1)
    }

    func testPerformResourceSync_Legacy() async throws {
        // Given
        DeveloperFlag.newInitialSync.enable(false, storage: .temporary())

        // Mock
        legacySyncStatus.resyncResources_MockMethod = {}

        // When
        try await sut.performResourceSync()

        // Then
        XCTAssertEqual(legacySyncStatus.resyncResources_Invocations.count, 1)
    }

    func testPerformIncrementalSync() async throws {
        // Given
        DeveloperFlag.newInitialSync.enable(true, storage: .temporary())

        // Mock
        incrementalSync.perform_MockMethod = {
            IncrementalSync.Token(
                task: Task {},
                closePushChannel: {}
            )
        }

        // When
        try await sut.performIncrementalSync()

        // Then
        XCTAssertEqual(incrementalSync.perform_Invocations.count, 1)
    }

}
