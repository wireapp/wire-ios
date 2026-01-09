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

import Foundation
import XCTest
@testable import WireNetwork
@testable import WireNetworkSupport

class ConnectionsAPITests: XCTestCase {

    private var apiSnapshotHelper: APIServiceSnapshotHelper<any ConnectionsAPI>!

    // MARK: - Setup

    override func setUp() {
        apiSnapshotHelper = APIServiceSnapshotHelper<any ConnectionsAPI> { apiService, apiVersion in
            let builder = ConnectionsAPIBuilder(apiService: apiService)
            return builder.makeAPI(for: apiVersion)
        }
    }

    override func tearDown() {
        apiSnapshotHelper = nil
    }

    /// Verifies generation of request for each API versions
    func testGetConnectionsRequest() async throws {
        // then
        try await apiSnapshotHelper.verifyRequestForAllAPIVersions { sut in
            let pager = try await sut.getConnections()
            for try await _ in pager {
                // this triggers fetching the data
            }
        }
    }

    func testGetConnections_SuccessResponse_200_V0() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "GetConnectionsSuccessResponseV0")
        ])

        let sut = ConnectionsAPIV0(apiService: apiService)

        // When
        let pager = try await sut.getConnections()
        var iterator = pager.makeAsyncIterator()
        let result = try await iterator.next()

        // Then
        let expectedConnection = Connection(
            senderID: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ac")!,
            receiverID: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!,
            receiverQualifiedID: QualifiedID(
                id: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!,
                domain: "example.com"
            ),
            conversationID: UUID(uuidString: "302c59b0-037c-4b0f-a3ed-ccdbfb4cfe2c")!,
            qualifiedConversationID: QualifiedID(
                id: UUID(uuidString: "302c59b0-037c-4b0f-a3ed-ccdbfb4cfe2c")!,
                domain: "example.com"
            ),
            lastUpdate: try XCTUnwrap(
                ISO8601DateFormatter.fractionalInternetDateTime
                    .date(from: "2021-05-12T10:52:02.671Z")
            ),
            status: .accepted
        )
        let connection = try XCTUnwrap(result?.first)
        XCTAssertEqual(connection, expectedConnection)
    }

    func testGetConnections_FailureResponse_400_V0() async throws {
        // Given

        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .badRequest,
            label: ""
        )

        let sut = ConnectionsAPIV0(apiService: apiService)

        // When
        let pager = try await sut.getConnections()
        var iterator = pager.makeAsyncIterator()

        // Then
        do {
            _ = try await iterator.next()
            XCTFail("Expected error")
        } catch {
            let error = try XCTUnwrap(error as? ConnectionsAPIError)
            XCTAssertEqual(error, .invalidBody)
        }
    }

    func testGetConnections_MultiplePages_SuccessResponse_V0() async throws {
        // Given
        // We fake responses with 1 element per page even if batchSize is 500
        // pager is driven by has_more attribute in response

        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "GetConnectionsMultiplePagesSuccessResponseV0.0"),
            (.ok, "GetConnectionsMultiplePagesSuccessResponseV0.1"),
            (.ok, "GetConnectionsMultiplePagesSuccessResponseV0.2")
        ])

        try await apiSnapshotHelper.verifyRequest(for: [.v0], apiService: apiService) { sut in
            // WHEN
            let pager = try await sut.getConnections()
            for try await _ in pager {
                // do something with the data
                // this will trigger the fetch when we wait for the page
            }
        }

        // THEN
        let invokedRequest = apiService.executeRequestRequiringAccessToken_Invocations
        XCTAssertEqual(invokedRequest.count, 3)
    }
}
