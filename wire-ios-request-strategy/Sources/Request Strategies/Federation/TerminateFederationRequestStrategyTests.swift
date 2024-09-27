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
@testable import WireRequestStrategy

// MARK: - TerminateFederationRequestStrategyTests

class TerminateFederationRequestStrategyTests: MessagingTestBase {
    // MARK: - Properties

    var sut: TerminateFederationRequestStrategy!
    var mockApplicationStatus: MockApplicationStatus!
    var manager: MockFederationTerminationManager!

    override func setUp() {
        super.setUp()
        mockApplicationStatus = MockApplicationStatus()
        mockApplicationStatus.mockSynchronizationState = .slowSyncing

        sut = TerminateFederationRequestStrategy(
            withManagedObjectContext: syncMOC,
            applicationStatus: mockApplicationStatus
        )
        manager = MockFederationTerminationManager()
        sut.federationTerminationManager = manager
    }

    override func tearDown() {
        mockApplicationStatus = nil
        manager = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Processing events

    func testThatItProcessesEvent_FederationDelete() {
        syncMOC.performGroupedAndWait {
            // GIVEN
            let payload: NSDictionary = [
                "type": "federation.delete",
                "domain": "example.com",
            ]

            let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)!

            // WHEN
            self.sut.processEvents([event], liveEvents: false, prefetchResult: nil)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertTrue(manager.didCallHandleFederationTerminationWith)
    }

    func testThatItProcessesEvent_federationConnectionRemoved() {
        syncMOC.performGroupedAndWait {
            // GIVEN
            let payload: NSDictionary = [
                "type": "federation.connectionRemoved",
                "domains": ["anta.wire.link", "foma.wire.link"],
            ]

            let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)!

            // WHEN
            self.sut.processEvents([event], liveEvents: false, prefetchResult: nil)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertTrue(manager.didCallhandleFederationTerminationBetween)
    }
}

// MARK: - MockFederationTerminationManager

class MockFederationTerminationManager: FederationTerminationManagerInterface {
    var didCallHandleFederationTerminationWith = false
    var didCallhandleFederationTerminationBetween = false

    func handleFederationTerminationWith(_: String) {
        didCallHandleFederationTerminationWith = true
    }

    func handleFederationTerminationBetween(_ domain: String, otherDomain: String) {
        didCallhandleFederationTerminationBetween = true
    }
}
