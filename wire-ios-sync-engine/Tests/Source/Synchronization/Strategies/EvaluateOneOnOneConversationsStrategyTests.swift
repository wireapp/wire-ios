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

import WireDataModelSupport
import WireRequestStrategySupport
import XCTest
@testable import WireSyncEngine

final class EvaluateOneOnOneConversationsStrategyTests: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        try await super.setUp()

        coreDataHelper = CoreDataStackHelper()
        mockCoreDataStack = try await coreDataHelper.createStack()

        mockApplicationStatus = MockApplicationStatus()
        mockSyncStatus = MockSyncProgress()
    }

    override func tearDown() async throws {
        mockSyncStatus = nil
        mockApplicationStatus = nil

        mockCoreDataStack = nil
        try coreDataHelper.cleanupDirectory()
        coreDataHelper = nil

        try await super.tearDown()
    }

    func testInitialState() {
        // given
        let strategy = makeStrategy()

        // when
        // then
        XCTAssertEqual(strategy.syncPhase, .evaluate1on1ConversationsForMLS)
    }

    func testNextRequest_givenSyncPhaseEvaluate1on1ConversationsForMLS_thenCallFinishSync() async {
        // given
        let expectation = expectation(description: "EvaluateOneOnOneConversationsStrategy")

        mockSyncStatus.currentSyncPhase = .evaluate1on1ConversationsForMLS
        mockSyncStatus.finishCurrentSyncPhasePhase_MockMethod = { _ in
            expectation.fulfill()
        }

        let strategy = makeStrategy()

        // when
        await syncContext.perform {
            XCTAssertNil(strategy.nextRequest(for: self.apiVersion))
        }

        // then
        await fulfillment(of: [expectation], timeout: 0.1)

        XCTAssertEqual(mockSyncStatus.finishCurrentSyncPhasePhase_Invocations.count, 1)
    }

    func testNextRequest_givenOtherSyncPhase_thenDoNotCallFinishSync() async {
        // given
        let expectation = expectation(description: "EvaluateOneOnOneConversationsStrategy")
        expectation.isInverted = true

        mockSyncStatus.currentSyncPhase = .fetchingLastUpdateEventID
        mockSyncStatus.finishCurrentSyncPhasePhase_MockMethod = { _ in
            expectation.fulfill()
        }

        let strategy = makeStrategy()

        // when
        await syncContext.perform {
            XCTAssertNil(strategy.nextRequest(for: self.apiVersion))
        }

        // then
        await fulfillment(of: [expectation], timeout: 0.1)

        XCTAssert(mockSyncStatus.finishCurrentSyncPhasePhase_Invocations.isEmpty)
    }

    // MARK: Private

    private var coreDataHelper: CoreDataStackHelper!

    // need to decide on some api version, even though it should be not relevant for this test.
    private let apiVersion: APIVersion = .v5

    private var mockApplicationStatus: MockApplicationStatus!
    private var mockCoreDataStack: CoreDataStack!
    private var mockSyncStatus: MockSyncProgress!

    private var syncContext: NSManagedObjectContext { mockCoreDataStack.syncContext }

    // MARK: - Helpers

    private func makeStrategy() -> EvaluateOneOnOneConversationsStrategy {
        EvaluateOneOnOneConversationsStrategy(
            withManagedObjectContext: syncContext,
            applicationStatus: mockApplicationStatus,
            syncProgress: mockSyncStatus
        )
    }
}
