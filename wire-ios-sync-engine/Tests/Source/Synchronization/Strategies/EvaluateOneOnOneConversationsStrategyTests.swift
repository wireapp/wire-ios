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

    private var coreDataHelper: CoreDataStackHelper!

    // need to decide on some api version, even though it should be not relevant for this test.
    private let apiVersion: APIVersion = .v5

    private var mockApplicationStatus: MockApplicationStatus!
    private var mockCoreDataStack: CoreDataStack!
    private var mockLastEventIDRepository: LastEventIDRepository!
    private var mockSyncStatus: MockSyncStatus!

    private var syncContext: NSManagedObjectContext { mockCoreDataStack.syncContext }

    override func setUp() async throws {
        try await super.setUp()

        coreDataHelper = CoreDataStackHelper()
        mockCoreDataStack = try await coreDataHelper.createStack()

        mockApplicationStatus = MockApplicationStatus()
        mockLastEventIDRepository = LastEventIDRepository(
            userID: UUID(),
            sharedUserDefaults: .temporary()
        )
        mockSyncStatus = MockSyncStatus(
            managedObjectContext: syncContext,
            lastEventIDRepository: mockLastEventIDRepository
        )
    }

    override func tearDown() async throws {
        mockLastEventIDRepository = nil
        mockSyncStatus = nil
        mockApplicationStatus = nil

        mockCoreDataStack = nil
        try coreDataHelper.cleanupDirectory()
        coreDataHelper = nil

        try await super.tearDown()
    }

    func testInitialState() {
        // given
        let strategy = EvaluateOneOnOneConversationsStrategy(
            withManagedObjectContext: syncContext,
            applicationStatus: mockApplicationStatus,
            syncStatus: mockSyncStatus
        )

        // when
        // then
        XCTAssertEqual(strategy.syncPhase, .evaluate1on1ConversationsForMLS)
    }

    func testNextRequest_givenSyncPhaseEvaluate1on1ConversationsForMLS_thenCallFinishSync() async {
        // given
        mockSyncStatus.mockPhase = .evaluate1on1ConversationsForMLS

        let expectation = self.expectation(description: "EvaluateOneOnOneConversationsStrategy")
        let strategy = EvaluateOneOnOneConversationsStrategy(
            withManagedObjectContext: syncContext,
            applicationStatus: mockApplicationStatus,
            syncStatus: mockSyncStatus
        )
        strategy.taskCompletion = { expectation.fulfill() }

        // when
        XCTAssertNil(strategy.nextRequest(for: apiVersion))

        // then
        await fulfillment(of: [expectation], timeout: 0.1)

        XCTAssertTrue(mockSyncStatus.didCallFinishCurrentSyncPhase)
    }

    func testNextRequest_givenOtherSyncPhase_thenDoNotCallFinishSync() async {
        // given
        mockSyncStatus.mockPhase = .fetchingLastUpdateEventID

        let expectation = self.expectation(description: "EvaluateOneOnOneConversationsStrategy")
        expectation.isInverted = true
        let strategy = EvaluateOneOnOneConversationsStrategy(
            withManagedObjectContext: syncContext,
            applicationStatus: mockApplicationStatus,
            syncStatus: mockSyncStatus
        )
        strategy.taskCompletion = { expectation.fulfill() }

        // when
        XCTAssertNil(strategy.nextRequest(for: apiVersion))

        // then
        await fulfillment(of: [expectation], timeout: 0.1)

        XCTAssertFalse(mockSyncStatus.didCallFinishCurrentSyncPhase)
    }
}
