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

@testable import WireAPI

final class ConversationsAPITests: XCTestCase {

    private var snapshotHelper: RequestSnapshotHelper<ConversationsAPIBuilder>!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        snapshotHelper = .init()
    }

    override func tearDown() {
        snapshotHelper = nil
    }

    // MARK: - Tests

    func testGetConversationIdentifiers() async throws {
        // given
        try await snapshotHelper.verifyRequestForAllAPIVersions { sut in
            // when
            let pager = try await sut.getConversationIdentifiers()

            // then
            for try await _ in pager {
                // trigger fetching data
            }
        }
    }

    func testGetConversationIdentifiers_givenV1AndSuccessResponse200_thenValidateRequests() async throws {
        // given
        let httpClient = MockHTTPResponsesClient()
        httpClient.httpResponses = [
            try HTTPResponse.mockJSONResource(code: 200, jsonResource: "testGetConversationIdentifiers_givenV1AndSuccessResponse200")
        ]

        // when
        let api = ConversationsAPIV1(httpClient: httpClient)
        let pager = try await api.getConversationIdentifiers()

        for try await _ in pager {
            // trigger fetching date
        }

        // then
        for (index, request) in httpClient.receivedRequests.enumerated() {
            try await snapshotHelper.verifyRequest(request: request, resourceName: "v1.\(index)")
        }
    }

    func testGetConversationIdentifiers_givenV1AndSuccessResponse200_thenValidateResponse() async throws {
        // given
        let httpClient = MockHTTPResponsesClient()
        httpClient.httpResponses = [
            try HTTPResponse.mockJSONResource(code: 200, jsonResource: "testGetConversationIdentifiers_givenV1AndSuccessResponse200")
        ]

        let expectedIDs: [[QualifiedID]] = [[
            QualifiedID(
                uuid: try XCTUnwrap(UUID(uuidString: "14c3f0ff-1a46-4e66-8845-ae084f09c483")),
                domain: "staging.zinfra.io"
            )
        ]]

        let api = ConversationsAPIV1(httpClient: httpClient)

        // when
        let pager = try await api.getConversationIdentifiers()

        // then
        for try await ids in pager {
            // validate responses
            XCTAssertEqual(ids, expectedIDs)
        }
    }
}
