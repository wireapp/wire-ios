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
import WireTransport
import XCTest
@testable import WireRequestStrategy

final class ConnectionRequestStrategyTests: MessagingTestBase {
    var sut: ConnectionRequestStrategy!
    var mockApplicationStatus: MockApplicationStatus!
    var mockSyncProgress: MockSyncProgress!
    var mockOneOnOneResolver: MockOneOnOneResolverInterface!

    var apiVersion: APIVersion! {
        didSet {
            BackendInfo.apiVersion = apiVersion
        }
    }

    override func setUp() {
        super.setUp()

        mockApplicationStatus = MockApplicationStatus()
        mockApplicationStatus.mockSynchronizationState = .online

        mockSyncProgress = MockSyncProgress()
        mockSyncProgress.currentSyncPhase = .done
        mockSyncProgress.finishCurrentSyncPhasePhase_MockMethod = { _ in }
        mockSyncProgress.failCurrentSyncPhasePhase_MockMethod = { _ in }

        mockOneOnOneResolver = MockOneOnOneResolverInterface()

        sut = ConnectionRequestStrategy(
            withManagedObjectContext: syncMOC,
            applicationStatus: mockApplicationStatus,
            syncProgress: mockSyncProgress,
            oneOneOneResolver: mockOneOnOneResolver
        )

        apiVersion = .v0
    }

    override func tearDown() {
        sut = nil
        mockSyncProgress = nil
        mockApplicationStatus = nil
        mockOneOnOneResolver = nil
        super.tearDown()
    }

    // MARK: Request generation

    func testThatRequestToFetchConversationIsGenerated_WhenNeedsToBeUpdatedFromBackendIsTrue_Federated() {
        syncMOC.performGroupedAndWait {
            // given
            self.apiVersion = .v1

            let connection = ZMConnection.insertNewObject(in: self.syncMOC)
            connection.to = self.otherUser
            connection.needsToBeUpdatedFromBackend = true
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([connection])) }

            // when
            let request = self.sut.nextRequest(for: self.apiVersion)!

            // then
            XCTAssertEqual(
                request.path,
                "/v1/connections/\(self.otherUser.domain!)/\(self.otherUser.remoteIdentifier!.transportString())"
            )
            XCTAssertEqual(request.method, .get)
        }
    }

    func testThatRequestToFetchConversationIsGenerated_WhenNeedsToBeUpdatedFromBackendIsTrue_NonFederated() {
        syncMOC.performGroupedAndWait {
            // given
            let connection = ZMConnection.insertNewObject(in: self.syncMOC)
            connection.to = self.otherUser
            connection.needsToBeUpdatedFromBackend = true
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([connection])) }

            // when
            let request = self.sut.nextRequest(for: self.apiVersion)!

            // then
            XCTAssertEqual(request.path, "/connections/\(self.otherUser.remoteIdentifier!.transportString())")
            XCTAssertEqual(request.method, .get)
        }
    }

    // MARK: Slow sync

    func testThatRequestToFetchAllConnectionsIsGenerated_DuringFetchingConnectionsSyncPhase_Federated() {
        syncMOC.performGroupedAndWait {
            // given
            self.apiVersion = .v1

            self.mockSyncProgress.currentSyncPhase = .fetchingConnections

            // when
            let request = self.sut.nextRequest(for: self.apiVersion)!

            // then
            XCTAssertEqual(request.path, "/v1/list-connections")
            XCTAssertEqual(request.method, .post)
        }
    }

    func testThatRequestToFetchAllConnectionsIsGenerated_DuringFetchingConnectionsSyncPhase_NonFederated() {
        syncMOC.performGroupedAndWait {
            // given
            self.mockSyncProgress.currentSyncPhase = .fetchingConnections

            // when
            let request = self.sut.nextRequest(for: self.apiVersion)!

            // then
            XCTAssertEqual(request.path, "/connections?size=200")
            XCTAssertEqual(request.method, .get)
        }
    }

    func testThatRequestToFetchAllConnectionsIsNotGenerated_WhenFetchIsAlreadyInProgress() {
        syncMOC.performGroupedAndWait {
            // given
            self.apiVersion = .v1
            self.mockSyncProgress.currentSyncPhase = .fetchingConnections
            XCTAssertNotNil(self.sut.nextRequest(for: self.apiVersion))

            // then
            XCTAssertNil(self.sut.nextRequest(for: self.apiVersion))
        }
    }

    func testThatFetchingConnectionsSyncPhaseIsFinished_WhenFetchIsCompleted() {
        // given
        apiVersion = .v1
        startSlowSync()

        // when
        fetchConnectionsDuringSlowSync(connections: [createConnectionPayload()])

        // then
        XCTAssertEqual(mockSyncProgress.finishCurrentSyncPhasePhase_Invocations, [.fetchingConnections])
    }

    func testThatFetchingConnectionsSyncPhaseIsFinished_WhenThereIsNoConnectionsToFetch() {
        // given
        apiVersion = .v1
        startSlowSync()

        // when
        fetchConnectionsDuringSlowSync(connections: [])

        // then
        XCTAssertEqual(mockSyncProgress.finishCurrentSyncPhasePhase_Invocations, [.fetchingConnections])
    }

    func testThatFetchingConnectionsSyncPhaseIsFailed_WhenReceivingAPermanentError() {
        // given
        apiVersion = .v1
        startSlowSync()

        // when
        fetchConnectionsDuringSlowSyncWithPermanentError()

        // then
        XCTAssertEqual(mockSyncProgress.failCurrentSyncPhasePhase_Invocations, [.fetchingConnections])
    }

    // MARK: Response processing

    func testThatConnectionResetsNeedsToBeUpdatedFromBackend_OnPermanentErrors_Federated() {
        // given
        apiVersion = .v1

        // when
        fetchConnection(
            oneToOneConnection,
            response: responseFailure(code: 403, label: .unknown, apiVersion: apiVersion)
        )

        // then
        syncMOC.performGroupedAndWait {
            XCTAssertFalse(self.oneToOneConnection.needsToBeUpdatedFromBackend)
        }
    }

    func testThatConnectionResetsNeedsToBeUpdatedFromBackend_OnPermanentErrors_NonFederated() {
        // when
        fetchConnection(
            oneToOneConnection,
            response: responseFailure(code: 403, label: .unknown, apiVersion: apiVersion)
        )

        // then
        syncMOC.performGroupedAndWait {
            XCTAssertFalse(self.oneToOneConnection.needsToBeUpdatedFromBackend)
        }
    }

    func testThatConnectionPayloadIsProcessed_OnSuccessfulResponse_Federated() {
        // given
        apiVersion = .v1
        var payload: Payload.Connection!
        syncMOC.performGroupedAndWait {
            payload = self.createConnectionPayload(self.oneToOneConnection, status: .cancelled)
        }

        // when
        fetchConnection(oneToOneConnection, response: successfulResponse(connection: payload))

        // then
        syncMOC.performGroupedAndWait {
            XCTAssertEqual(self.oneToOneConnection.status, .cancelled)
        }
    }

    func testThatConnectionPayloadIsProcessed_OnSuccessfulResponse_NonFederated() {
        // given
        var payload: Payload.Connection!
        syncMOC.performGroupedAndWait {
            payload = self.createConnectionPayload(self.oneToOneConnection, status: .cancelled)
        }

        // when
        fetchConnection(oneToOneConnection, response: successfulResponse(connection: payload))

        // then
        syncMOC.performGroupedAndWait {
            XCTAssertEqual(self.oneToOneConnection.status, .cancelled)
        }
    }

    // MARK: Event processing

    func testThatItProcessConnectionEvents() {
        syncMOC.performAndWait {
            // given
            let connection = createConnectionPayload(self.oneToOneConnection, status: .blocked)
            let eventType = ZMUpdateEvent.eventTypeString(for: Payload.Connection.eventType)!
            let eventPayload = Payload.UserConnectionEvent(connection: connection, type: eventType)
            let event = updateEvent(from: eventPayload.payloadData()!)

            // when
            self.sut.processEvents([event], liveEvents: true, prefetchResult: nil)

            // then
            XCTAssertEqual(self.oneToOneConnection.status, .blocked)
        }
    }

    func testOneOnOneResolverInvocationTiming() throws {
        // GIVEN
        let expectation1 =
            XCTestExpectation(description: "OneOnOneResolver should not be invoked within the specified timeout")
        let expectation2 =
            XCTestExpectation(description: "OneOnOneResolver should be invoked within the specified timeout")
        expectation1.isInverted = true // We expect this expectation to not be fulfilled within the timeout

        try syncMOC.performAndWait {
            let connection = createConnectionPayload(self.oneToOneConnection, status: .accepted)
            let eventType = try XCTUnwrap(
                ZMUpdateEvent.eventTypeString(for: Payload.Connection.eventType),
                "eventType is nil"
            )
            let eventPayload = Payload.UserConnectionEvent(connection: connection, type: eventType)
            let payloadData = try XCTUnwrap(eventPayload.payloadData(), "payloadData is nil")
            let event = updateEvent(from: payloadData)

            mockOneOnOneResolver.resolveOneOnOneConversationWithIn_MockMethod = { _, _ in
                expectation1.fulfill() // Attempt to fulfill the first expectation
                expectation2.fulfill() // Fulfill the second expectation
                return OneOnOneConversationResolution.noAction
            }

            sut.oneOnOneResolutionDelay = 1

            // WHEN
            self.sut.processEvents([event], liveEvents: true, prefetchResult: nil)
        }

        // THEN
        // Wait for the first expectation with a timeout of 0.5 seconds, expecting it to fail (not to be fulfilled)
        wait(for: [expectation1], timeout: 0.5)
        XCTAssertEqual(
            mockOneOnOneResolver.resolveOneOnOneConversationWithIn_Invocations.count,
            0,
            "Expected no invocation due to the first timeout."
        )

        // Wait for the second expectation with a timeout of 1 second, expecting it to succeed (to be fulfilled)
        wait(for: [expectation2], timeout: 1)
        XCTAssertEqual(
            mockOneOnOneResolver.resolveOneOnOneConversationWithIn_Invocations.count,
            1,
            "Expected one invocation after the second timeout."
        )
    }

    // MARK: Helpers

    func startSlowSync() {
        syncMOC.performGroupedAndWait {
            self.mockSyncProgress.currentSyncPhase = .fetchingConnections
        }
    }

    func fetchConnection(_ connection: ZMConnection, response: ZMTransportResponse) {
        syncMOC.performGroupedAndWait {
            // given
            connection.needsToBeUpdatedFromBackend = true
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([connection])) }

            // when
            let request = self.sut.nextRequest(for: self.apiVersion)!
            request.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func fetchConnectionsDuringSlowSync(connections: [Payload.Connection]) {
        syncMOC.performGroupedAndWait {
            let request = self.sut.nextRequest(for: self.apiVersion)!
            guard let payload = Payload.PaginationStatus(request) else {
                return XCTFail("Invalid Payload")
            }

            request.complete(with: self.successfulResponse(request: payload, connections: connections))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func fetchConnectionsDuringSlowSyncWithPermanentError() {
        syncMOC.performGroupedAndWait {
            let request = self.sut.nextRequest(for: self.apiVersion)!
            request.complete(with: self.responseFailure(code: 404, label: .noEndpoint, apiVersion: self.apiVersion))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func successfulResponse(
        request: Payload.PaginationStatus,
        connections: [Payload.Connection]
    ) -> ZMTransportResponse {
        let payload = Payload.PaginatedConnectionList(
            connections: connections,
            pagingState: "",
            hasMore: false
        )

        let payloadData = payload.payloadData()!
        let payloadString = String(bytes: payloadData, encoding: .utf8)!
        let response = ZMTransportResponse(
            payload: payloadString as ZMTransportData,
            httpStatus: 200,
            transportSessionError: nil,
            apiVersion: apiVersion.rawValue
        )

        return response
    }

    func successfulResponse(connection: Payload.Connection) -> ZMTransportResponse {
        let payloadData = connection.payloadData()!
        let payloadString = String(bytes: payloadData, encoding: .utf8)!
        let response = ZMTransportResponse(
            payload: payloadString as ZMTransportData,
            httpStatus: 200,
            transportSessionError: nil,
            apiVersion: apiVersion.rawValue
        )

        return response
    }
}
