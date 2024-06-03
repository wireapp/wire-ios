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

    private var httpRequestSnapshotHelper: HTTPRequestSnapshotHelper!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        httpRequestSnapshotHelper = HTTPRequestSnapshotHelper()
    }

    override func tearDown() {
        httpRequestSnapshotHelper = nil
        super.tearDown()
    }

    // MARK: - Tests

    // MARK: getLegacyConversation

    func testGetLegacyConversationIdentifiers() async throws {
        // given
        let apiVersions: [APIVersion] = [.v0]

        let apiSnapshotHelper = APISnapshotHelper<ConversationsAPI> { httpClient, apiVersion in
            let builder = ConversationsAPIBuilder(httpClient: httpClient)
            return builder.makeAPI(for: apiVersion)
        }

        // when
        // then
        try await apiSnapshotHelper.verifyRequest(for: apiVersions) { sut in
            let pager = try await sut.getLegacyConversationIdentifiers()

            for try await _ in pager {
                // trigger fetching data
            }
        }
    }

    func testGetConversationIdentifiers() async throws {
        // given
        let apiVersions = Set(APIVersion.allCases).subtracting([.v0])

        let apiSnapshotHelper = APISnapshotHelper<ConversationsAPI> { httpClient, apiVersion in
            let builder = ConversationsAPIBuilder(httpClient: httpClient)
            return builder.makeAPI(for: apiVersion)
        }

        // when
        // then
        try await apiSnapshotHelper.verifyRequest(for: apiVersions) { sut in
            let pager = try await sut.getConversationIdentifiers()

            for try await _ in pager {
                // trigger fetching data
            }
        }
    }

    func testGetLegacyConversationIdentifiers_givenV0AndSuccessResponse200_thenVerifyRequests() async throws {
        // given
        let httpClient = MockHTTPResponsesClient()
        httpClient.httpResponses = [
            try HTTPResponse.mockJSONResource(code: 200, jsonResource: "testGetLegacyConversationIdentifiers_givenV0AndSuccessResponse200")
        ]

        // when
        let api = ConversationsAPIV0(httpClient: httpClient)
        let pager = try await api.getLegacyConversationIdentifiers()

        for try await _ in pager {
            // trigger fetching date
        }

        // then
        for (index, request) in httpClient.receivedRequests.enumerated() {
            await httpRequestSnapshotHelper.verifyRequest(request: request, resourceName: "v0.\(index)")
        }
    }

    func testGetLegacyConversationIdentifiers_givenV0AndSuccessResponse200_thenVerifyResponse() async throws {
        // given
        let httpClient = MockHTTPResponsesClient()
        httpClient.httpResponses = [
            try HTTPResponse.mockJSONResource(code: 200, jsonResource: "testGetLegacyConversationIdentifiers_givenV0AndSuccessResponse200")
        ]

        let expectedIDs: [UUID] = [
            try XCTUnwrap(UUID(uuidString: "14c3f0ff-1a46-4e66-8845-ae084f09c483"))
        ]

        let api = ConversationsAPIV0(httpClient: httpClient)

        // when
        let pager = try await api.getLegacyConversationIdentifiers()

        // then
        for try await ids in pager {
            // validate responses
            XCTAssertEqual(ids, expectedIDs)
        }
    }

    func testGetLegacyConversationIdentifiers_givenV0AndErrorResponse() async throws {
        // given
        let httpClient = MockHTTPResponsesClient()
        httpClient.httpResponses = [
            try HTTPResponse.mockError(code: 503, label: "service unavailable")
        ]

        let api = ConversationsAPIV0(httpClient: httpClient)

        // when
        // then
        do {
            _ = try await api.getLegacyConversationIdentifiers()
        } catch let error as FailureResponse {
            XCTAssertEqual(error.code, 503)
            XCTAssertEqual(error.label, "service unavailable")
        } catch {
            XCTFail("expected error 'FailureResponse'")
        }
    }

    // MARK: getConversationIdentifiers

    func testGetConversationIdentifiers_givenV1AndSuccessResponse200_thenVerifyRequests() async throws {
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
            await httpRequestSnapshotHelper.verifyRequest(request: request, resourceName: "v1.\(index)")
        }
    }

    func testGetConversationIdentifiers_givenV1AndSuccessResponse200_thenVerifyResponse() async throws {
        // given
        let httpClient = MockHTTPResponsesClient()
        httpClient.httpResponses = [
            try HTTPResponse.mockJSONResource(code: 200, jsonResource: "testGetConversationIdentifiers_givenV1AndSuccessResponse200")
        ]

        let expectedIDs: [QualifiedID] = [
            QualifiedID(
                uuid: try XCTUnwrap(UUID(uuidString: "14c3f0ff-1a46-4e66-8845-ae084f09c483")),
                domain: "staging.zinfra.io"
            )
        ]

        let api = ConversationsAPIV1(httpClient: httpClient)

        // when
        let pager = try await api.getConversationIdentifiers()

        // then
        for try await ids in pager {
            // validate responses
            XCTAssertEqual(ids, expectedIDs)
        }
    }

    func testGetConversationIdentifiers_givenV1AndErrorResponse() async throws {
        // given
        let httpClient = MockHTTPResponsesClient()
        httpClient.httpResponses = [
            try HTTPResponse.mockError(code: 503, label: "service unavailable")
        ]

        let api = ConversationsAPIV1(httpClient: httpClient)

        // when
        // then
        do {
            _ = try await api.getConversationIdentifiers()
        } catch let error as FailureResponse {
            XCTAssertEqual(error.code, 503)
            XCTAssertEqual(error.label, "service unavailable")
        } catch {
            XCTFail("expected error 'FailureResponse'")
        }
    }

    // MARK: getConversations

    func testGetConversations_givenV0AndSuccessResponse200() async throws {
        // given
        let httpClient = MockHTTPResponsesClient()
        httpClient.httpResponses = [
            try HTTPResponse.mockJSONResource(
                code: 200,
                jsonResource: "testGetConversations_givenV0AndSuccessResponse200"
            )
        ]

        let api = ConversationsAPIV0(httpClient: httpClient)

        // when
        // then
        let list = try await api.getConversations(for: [])
        XCTAssertEqual(list.found.count, 1)
        XCTAssertEqual(list.notFound.count, 1)
        XCTAssertEqual(list.failed.count, 1)
    }

    func testGetConversations_givenV0AndSuccessResponse400() async throws {
        // given
        let httpClient = MockHTTPResponsesClient()
        httpClient.httpResponses = [
            try HTTPResponse.mockError(code: 400, label: "invalid body")
        ]

        let api = ConversationsAPIV0(httpClient: httpClient)

        // when
        // then
        do {
            _ = try await api.getConversations(for: [])
        } catch let error as FailureResponse {
            XCTAssertEqual(error.code, 400)
            XCTAssertEqual(error.label, "invalid body")
        } catch {
            XCTFail("expected error 'FailureResponse'")
        }
    }

    func testGetConversations_givenV0AndSuccessResponse503() async throws {
        // given
        let httpClient = MockHTTPResponsesClient()
        httpClient.httpResponses = [
            try HTTPResponse.mockError(code: 503, label: "service unavailable")
        ]

        let api = ConversationsAPIV0(httpClient: httpClient)

        // when
        // then
        do {
            _ = try await api.getConversations(for: [])
        } catch let error as FailureResponse {
            XCTAssertEqual(error.code, 503)
            XCTAssertEqual(error.label, "service unavailable")
        } catch {
            XCTFail("expected error 'FailureResponse'")
        }
    }
}
