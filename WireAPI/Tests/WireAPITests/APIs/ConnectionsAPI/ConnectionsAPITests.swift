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

import Foundation
import XCTest
@testable import WireAPI

class ConnectionsAPITests: XCTestCase {
    /// Verifies generation of request for each API versions
    func testGetConnectionsRequest() async throws {
        // given
        let apiSnapshotHelper = APISnapshotHelper<any ConnectionsAPI> { httpClient, apiVersion in
            let builder = ConnectionsAPIBuilder(httpClient: httpClient)
            return builder.makeAPI(for: apiVersion)
        }

        // when
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
        let httpClient = try HTTPClientMock(
            code: .ok,
            payloadResourceName: "GetConnectionsSuccessResponseV0"
        )

        let sut = ConnectionsAPIV0(httpClient: httpClient)

        // When
        let pager = try await sut.getConnections()
        var iterator = pager.makeAsyncIterator()
        let result = try await iterator.next()

        // Then
        let expectedConnection = try Connection(
            senderID: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ac")!,
            receiverID: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!,
            receiverQualifiedID: QualifiedID(
                uuid: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!,
                domain: "example.com"
            ),
            conversationID: UUID(
                uuidString: "302c59b0-037c-4b0f-a3ed-ccdbfb4cfe2c"
            )!,
            qualifiedConversationID: QualifiedID(
                uuid: UUID(uuidString: "302c59b0-037c-4b0f-a3ed-ccdbfb4cfe2c")!,
                domain: "example.com"
            ),
            lastUpdate: XCTUnwrap(
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
        let httpClient = try HTTPClientMock(
            code: .badRequest, errorLabel: ""
        )

        let sut = ConnectionsAPIV0(httpClient: httpClient)

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
        var requestIndex = 0
        // We fake responses with 1 element per page even if batchSize is 500
        // pager is driven by has_more attribute in response
        let httpClient = HTTPClientMock { _ in
            let response = HTTPClientMock
                .PredefinedResponse(resourceName: "GetConnectionsMultiplePagesSuccessResponseV0.\(requestIndex)")
            requestIndex += 1

            let statusOk = HTTPStatusCode.ok.rawValue
            return try HTTPResponse(code: statusOk, payload: response.data())
        }

        // WHEN
        let sut = ConnectionsAPIV0(httpClient: httpClient)
        let pager = try await sut.getConnections()
        for try await _ in pager {
            // do something with the data
            // this will trigger the fetch when we wait for the page
        }

        // THEN
        XCTAssertEqual(httpClient.receivedRequests.count, 3)

        // checks we made the 3 correct requests
        for (index, receivedRequest) in httpClient.receivedRequests.enumerated() {
            await HTTPRequestSnapshotHelper().verifyRequest(
                request: receivedRequest,
                resourceName: "v0.\(index)"
            )
        }
    }
}
