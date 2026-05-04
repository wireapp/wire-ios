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

import WireDataModelSupport
import WireRequestStrategySupport
import WireTransport
import XCTest
@testable import WireRequestStrategy

final class ConnectionRequestStrategyTests: MessagingTestBase {

    var sut: ConnectionRequestStrategy!
    var mockApplicationStatus: MockApplicationStatus!

    override func setUp() {
        super.setUp()

        mockApplicationStatus = MockApplicationStatus()
        mockApplicationStatus.mockSynchronizationState = .online
    }

    override func tearDown() {
        sut = nil
        mockApplicationStatus = nil
        super.tearDown()
    }

    func createSUT(
        apiVersion: APIVersion,
        isFederationEnabled: Bool
    ) -> ConnectionRequestStrategy {
        ConnectionRequestStrategy(
            withManagedObjectContext: syncMOC,
            applicationStatus: mockApplicationStatus,
            apiVersion: apiVersion,
            localDomain: "wire.com",
            isFederationEnabled: isFederationEnabled
        )
    }

    // MARK: Request generation

    func testThatRequestToFetchConversationIsGenerated_WhenNeedsToBeUpdatedFromBackendIsTrue_Federated() {
        syncMOC.performGroupedAndWait {
            // given
            let apiVersion = APIVersion.v1
            self.sut = self.createSUT(apiVersion: apiVersion, isFederationEnabled: true)

            let connection = ZMConnection.insertNewObject(in: self.syncMOC)
            connection.to = self.otherUser
            connection.needsToBeUpdatedFromBackend = true
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([connection])) }

            // when
            let request = self.sut.nextRequest(for: apiVersion)!

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
            let apiVersion = APIVersion.v0
            self.sut = self.createSUT(apiVersion: apiVersion, isFederationEnabled: false)

            let connection = ZMConnection.insertNewObject(in: self.syncMOC)
            connection.to = self.otherUser
            connection.needsToBeUpdatedFromBackend = true
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([connection])) }

            // when
            let request = self.sut.nextRequest(for: apiVersion)!

            // then
            XCTAssertEqual(request.path, "/connections/\(self.otherUser.remoteIdentifier!.transportString())")
            XCTAssertEqual(request.method, .get)
        }
    }

    // MARK: Response processing

    func testThatConnectionResetsNeedsToBeUpdatedFromBackend_OnPermanentErrors_Federated() {
        // given
        let apiVersion = APIVersion.v1
        sut = createSUT(apiVersion: apiVersion, isFederationEnabled: true)

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
        let apiVersion = APIVersion.v1
        sut = createSUT(apiVersion: apiVersion, isFederationEnabled: false)

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
        let apiVersion = APIVersion.v1
        sut = createSUT(apiVersion: apiVersion, isFederationEnabled: true)

        var payload: Payload.Connection!
        syncMOC.performGroupedAndWait {
            payload = self.createConnectionPayload(self.oneToOneConnection, status: .cancelled)
        }

        // when
        fetchConnection(oneToOneConnection, response: successfulResponse(connection: payload, apiVersion: apiVersion))

        // then
        syncMOC.performGroupedAndWait {
            XCTAssertEqual(self.oneToOneConnection.status, .cancelled)
        }
    }

    func testThatConnectionPayloadIsProcessed_OnSuccessfulResponse_NonFederated() {
        // given
        let apiVersion = APIVersion.v1
        sut = createSUT(apiVersion: apiVersion, isFederationEnabled: false)

        var payload: Payload.Connection!
        syncMOC.performGroupedAndWait {
            payload = self.createConnectionPayload(self.oneToOneConnection, status: .cancelled)
        }

        // when
        fetchConnection(oneToOneConnection, response: successfulResponse(connection: payload, apiVersion: apiVersion))

        // then
        syncMOC.performGroupedAndWait {
            XCTAssertEqual(self.oneToOneConnection.status, .cancelled)
        }
    }

    // MARK: Helpers

    func fetchConnection(_ connection: ZMConnection, response: ZMTransportResponse) {
        syncMOC.performGroupedAndWait {
            // given
            let apiVersion = APIVersion(rawValue: response.apiVersion)!
            self.sut = self.createSUT(apiVersion: apiVersion, isFederationEnabled: true)

            connection.needsToBeUpdatedFromBackend = true
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([connection])) }

            // when
            let request = self.sut.nextRequest(for: apiVersion)!
            request.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func fetchConnectionsDuringSlowSync(connections: [Payload.Connection]) {
        syncMOC.performGroupedAndWait {
            let apiVersion = APIVersion.v1
            self.sut = self.createSUT(apiVersion: apiVersion, isFederationEnabled: true)

            let request = self.sut.nextRequest(for: apiVersion)!
            guard let payload = Payload.PaginationStatus(request) else {
                return XCTFail("Invalid Payload")
            }

            request.complete(with: self.successfulResponse(
                request: payload,
                connections: connections,
                apiVersion: apiVersion
            ))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func fetchConnectionsDuringSlowSyncWithPermanentError() {
        syncMOC.performGroupedAndWait {
            let apiVersion = APIVersion.v1
            self.sut = self.createSUT(apiVersion: apiVersion, isFederationEnabled: true)

            let request = self.sut.nextRequest(for: apiVersion)!
            request.complete(with: self.responseFailure(code: 404, label: .noEndpoint, apiVersion: apiVersion))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func successfulResponse(
        request: Payload.PaginationStatus,
        connections: [Payload.Connection],
        apiVersion: APIVersion
    ) -> ZMTransportResponse {

        let payload = Payload.PaginatedConnectionList(
            connections: connections,
            pagingState: "",
            hasMore: false
        )

        let payloadData = payload.payloadData()!
        let payloadString = String(bytes: payloadData, encoding: .utf8)!
        return ZMTransportResponse(
            payload: payloadString as ZMTransportData,
            httpStatus: 200,
            transportSessionError: nil,
            apiVersion: apiVersion.rawValue
        )
    }

    func successfulResponse(
        connection: Payload.Connection,
        apiVersion: APIVersion
    ) -> ZMTransportResponse {
        let payloadData = connection.payloadData()!
        let payloadString = String(bytes: payloadData, encoding: .utf8)!
        return ZMTransportResponse(
            payload: payloadString as ZMTransportData,
            httpStatus: 200,
            transportSessionError: nil,
            apiVersion: apiVersion.rawValue
        )
    }

}
