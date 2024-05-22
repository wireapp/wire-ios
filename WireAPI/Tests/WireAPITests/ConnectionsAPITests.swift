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
@testable import WireAPI
import XCTest

class ConnectionsAPITests: XCTestCase {

    /// Verifies generation of request
    func testGetConnectionsRequest() async throws {
        try await RequestSnapshotHelper<ConnectionsAPIBuilder>().verifyRequestForAllAPIVersions { sut in
            let pager = try await sut.fetchConnections()
            for try await page in pager {
                print(page)
            }
        }
    }

    func testGetConnections_SuccessResponse_200_V0() async throws {
        // Given
        let httpClient = try HTTPClientMock(
            code: 200,
            payloadResourceName: "GetConnectionsSuccessResponseV0"
        )

        let sut = ConnectionsAPIV0(httpClient: httpClient)

        // When
        let pager = try await sut.fetchConnections()
        var iterator = pager.makeAsyncIterator()
        let result = try await iterator.next()

        // Then
        let expectedConnection = Connection(senderId: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ac")!,
                                            receiverId: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!,
                                            receiverQualifiedId: QualifiedID(uuid: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!,
                                                                             domain: "example.com"),
                                            conversationId: UUID(uuidString: "302c59b0-037c-4b0f-a3ed-ccdbfb4cfe2c")!,
                                            qualifiedConversationId: QualifiedID(uuid: UUID(uuidString: "302c59b0-037c-4b0f-a3ed-ccdbfb4cfe2c")!,
                                                                                 domain: "example.com"),
                                            lastUpdate: try XCTUnwrap(ISO8601DateFormatter.default.date(from: "2021-05-12T10:52:02.671Z")),
                                            status: .accepted)
        let connection = try XCTUnwrap(result?.first)
        XCTAssertEqual(connection, expectedConnection)
    }

    func testGetConnections_FailureResponse_400_V0() async throws {
        // Given
        let httpClient = try HTTPClientMock(
            code: 400, errorLabel: ""
        )

        let sut = ConnectionsAPIV0(httpClient: httpClient)

        // When
        let pager = try await sut.fetchConnections()
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

    func testGetConnections_Paging_V0() async throws {
        try await RequestSnapshotHelper<ConnectionsAPIBuilder>().verifyRequest(apiVersion: .v0) { sut in

            let pager = try await sut.fetchConnections()

            for try await page in pager {
                print(page)
            }
        }
    }
}
