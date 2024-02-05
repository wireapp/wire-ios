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

import XCTest
import WireDataModelSupport
@testable import WireSyncEngine

final class EvaluateOneOnOneConversationsStrategyTests: XCTestCase {

    private let coreDataHelper = CoreDataStackHelper()
    private var coreDataStack: CoreDataStack!

    // need to decide on some api version, even though it should be not relevant for this test.
    private let apiVersion: APIVersion = .v5

    private var mockApplicationStatus: MockApplicationStatus!
    private var mockLastEventIDRepository: LastEventIDRepository!
    private var mockSyncStatus: MockSyncStatus!

    override func setUp() async throws {
        try await super.setUp()

        coreDataStack = try await coreDataHelper.createStack()

        mockApplicationStatus = MockApplicationStatus()
        mockLastEventIDRepository = LastEventIDRepository(
            userID: UUID(),
            sharedUserDefaults: .temporary()
        )
        mockSyncStatus = MockSyncStatus(
            managedObjectContext: coreDataStack.syncContext,
            lastEventIDRepository: mockLastEventIDRepository
        )
    }

    override func tearDown() async throws {
        mockLastEventIDRepository = nil
        mockSyncStatus = nil
        mockApplicationStatus = nil

        coreDataStack = nil
        try coreDataHelper.cleanupDirectory()

        try await super.tearDown()
    }

    func testInitialState() {
        // given
        let strategy = EvaluateOneOnOneConversationsStrategy(
            withManagedObjectContext: coreDataStack.syncContext,
            applicationStatus: mockApplicationStatus,
            syncStatus: mockSyncStatus
        )

        // when
        // then
        XCTAssertEqual(strategy.syncPhase, .evaluate1on1ConversationsForMLS)
    }

    func testNextRequest_givenSyncPhaseEvaluate1on1ConversationsForMLS_thenCallFinishSync() {
        // given
        mockSyncStatus.mockPhase = .evaluate1on1ConversationsForMLS

        let strategy = EvaluateOneOnOneConversationsStrategy(
            withManagedObjectContext: coreDataStack.syncContext,
            applicationStatus: mockApplicationStatus,
            syncStatus: mockSyncStatus
        )

        // when
        // then
        XCTAssertNil(strategy.nextRequest(for: apiVersion))
        XCTAssertTrue(mockSyncStatus.didCallFinishCurrentSyncPhase)
    }

    func testNextRequest_givenOtherSyncPhase_thenDoNotCallFinishSync() {
        // given
        mockSyncStatus.mockPhase = .fetchingLastUpdateEventID

        let strategy = EvaluateOneOnOneConversationsStrategy(
            withManagedObjectContext: coreDataStack.syncContext,
            applicationStatus: mockApplicationStatus,
            syncStatus: mockSyncStatus
        )

        // when
        // then
        XCTAssertNil(strategy.nextRequest(for: apiVersion))
        XCTAssertFalse(mockSyncStatus.didCallFinishCurrentSyncPhase)
    }
}
