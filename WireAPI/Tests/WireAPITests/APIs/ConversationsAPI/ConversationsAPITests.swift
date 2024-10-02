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

@testable import WireAPI
import WireTestingPackage
import XCTest

final class ConversationsAPITests: XCTestCase {

    private var httpRequestSnapshotHelper: HTTPRequestSnapshotHelper!
    private var apiSnapshotHelper: APISnapshotHelper<any ConversationsAPI>!

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        httpRequestSnapshotHelper = HTTPRequestSnapshotHelper()
        apiSnapshotHelper = APISnapshotHelper<any ConversationsAPI> { httpClient, apiVersion in
            let builder = ConversationsAPIBuilder(httpClient: httpClient)
            return builder.makeAPI(for: apiVersion)
        }
    }

    override func tearDown() {
        apiSnapshotHelper = nil
        httpRequestSnapshotHelper = nil

        super.tearDown()
    }

    // MARK: - Tests

    // MARK: getLegacyConversation

    func testGetLegacyConversationIdentifiers() async throws {
        // given
        let apiVersions: [APIVersion] = [.v0]

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

        // when
        // then
        try await apiSnapshotHelper.verifyRequest(for: apiVersions) { sut in
            let pager = try await sut.getConversationIdentifiers()

            for try await _ in pager {
                // trigger fetching data
            }
        }
    }

    func testGetMLSOneToOneConversationRequest() async throws {
        // Given

        let apiVersions = APIVersion.v5.andNextVersions

        // Then

        try await apiSnapshotHelper.verifyRequest(for: apiVersions) { sut in
            // When
            _ = try await sut.getMLSOneToOneConversation(
                userID: Scaffolding.userID,
                in: Scaffolding.domain
            )
        }
    }

    func testGetLegacyConversationIdentifiers_givenV0AndSuccessResponse200_thenVerifyRequests() async throws {
        // given
        let httpClient = MockHTTPResponsesClient()
        httpClient.httpResponses = [
            try HTTPResponse.mockJSONResource(code: .ok, name: "testGetLegacyConversationIdentifiers_givenV0AndSuccessResponse200")
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
            try HTTPResponse.mockJSONResource(code: .ok, name: "testGetLegacyConversationIdentifiers_givenV0AndSuccessResponse200")
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
            try HTTPResponse.mockError(code: .serviceUnavailable, label: "service unavailable")
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
            try HTTPResponse.mockJSONResource(code: .ok, name: "testGetConversationIdentifiers_givenV1AndSuccessResponse200")
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
            try HTTPResponse.mockJSONResource(code: .ok, name: "testGetConversationIdentifiers_givenV1AndSuccessResponse200")
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
            try HTTPResponse.mockError(code: .serviceUnavailable, label: "service unavailable")
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

    func testGetConversations_givenAllAPIVersions_thenVerifyRequests() async throws {
        // given
        let apiVersions = APIVersion.allCases

        let qualifiedID = QualifiedID(
            uuid: try XCTUnwrap(UUID(uuidString: "213248a1-5499-418f-8173-5010d1c1e506")),
            domain: "wire.com"
        )

        // when
        // then
        try await apiSnapshotHelper.verifyRequest(for: apiVersions) { sut in
            _ = try await sut.getConversations(for: [qualifiedID])
        }
    }

    func testGetConversations_givenV0AndSuccessResponse200_thenVerifyResponse() async throws {
        // given
        let httpClient = MockHTTPResponsesClient()
        httpClient.httpResponses = [
            try HTTPResponse.mockJSONResource(
                code: .ok,
                name: "testGetConversations_givenV0AndSuccessResponse200"
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
            try HTTPResponse.mockError(code: .badRequest, label: "invalid body")
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
            try HTTPResponse.mockError(code: .serviceUnavailable, label: "service unavailable")
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

    func testGetConversations_givenV2AndSuccessResponse200_thenVerifyResponse() async throws {
        // given
        let httpClient = MockHTTPResponsesClient()
        httpClient.httpResponses = [
            try HTTPResponse.mockJSONResource(
                code: .ok,
                name: "testGetConversations_givenV2AndSuccessResponse200"
            )
        ]

        let api = ConversationsAPIV2(httpClient: httpClient)

        // when
        // then
        let list = try await api.getConversations(for: [])
        XCTAssertEqual(list.found.count, 1)
        XCTAssertEqual(list.notFound.count, 1)
        XCTAssertEqual(list.failed.count, 1)
    }

    func testGetConversations_givenV2AndSuccessResponse400() async throws {
        // given
        let httpClient = MockHTTPResponsesClient()
        httpClient.httpResponses = [
            try HTTPResponse.mockError(code: .badRequest, label: "invalid body")
        ]

        let api = ConversationsAPIV2(httpClient: httpClient)

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

    func testGetConversations_givenV2AndSuccessResponse503() async throws {
        // given
        let httpClient = MockHTTPResponsesClient()
        httpClient.httpResponses = [
            try HTTPResponse.mockError(code: .serviceUnavailable, label: "service unavailable")
        ]

        let api = ConversationsAPIV2(httpClient: httpClient)

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

    func testGetConversations_givenV3AndSuccessResponse200_thenVerifyResponse() async throws {
        // given
        let httpClient = MockHTTPResponsesClient()
        httpClient.httpResponses = [
            try HTTPResponse.mockJSONResource(
                code: .ok,
                name: "testGetConversations_givenV3AndSuccessResponse200"
            )
        ]

        let api = ConversationsAPIV3(httpClient: httpClient)

        // when
        // then
        let list = try await api.getConversations(for: [])
        XCTAssertEqual(list.found.count, 1)
        XCTAssertEqual(list.notFound.count, 1)
        XCTAssertEqual(list.failed.count, 1)

        let conversation = try XCTUnwrap(list.found.first)
        XCTAssertEqual(conversation.accessRoles, [.teamMember])
        XCTAssertNil(conversation.legacyAccessRole)
    }

    func testGetConversations_givenV3AndSuccessResponse400() async throws {
        // given
        let httpClient = MockHTTPResponsesClient()
        httpClient.httpResponses = [
            try HTTPResponse.mockError(code: .badRequest, label: "invalid body")
        ]

        let api = ConversationsAPIV3(httpClient: httpClient)

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

    func testGetConversations_givenV3AndSuccessResponse503() async throws {
        // given
        let httpClient = MockHTTPResponsesClient()
        httpClient.httpResponses = [
            try HTTPResponse.mockError(code: .serviceUnavailable, label: "service unavailable")
        ]

        let api = ConversationsAPIV3(httpClient: httpClient)

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

    func testGetConversations_givenV5AndSuccessResponse200_thenVerifyResponse() async throws {
        // given
        let httpClient = MockHTTPResponsesClient()
        httpClient.httpResponses = [
            try HTTPResponse.mockJSONResource(
                code: .ok,
                name: "testGetConversations_givenV5AndSuccessResponse200"
            )
        ]

        let api = ConversationsAPIV5(httpClient: httpClient)

        // when
        // then
        let list = try await api.getConversations(for: [])
        XCTAssertEqual(list.found.count, 1)
        XCTAssertEqual(list.notFound.count, 1)
        XCTAssertEqual(list.failed.count, 1)

        let conversation = try XCTUnwrap(list.found.first)
        XCTAssertEqual(conversation.epochTimestamp, Date(timeIntervalSince1970: 1_620_816_722))
        XCTAssertEqual(conversation.cipherSuite, .MLS_128_DHKEMP256_AES128GCM_SHA256_P256)
    }

    func testGetConversations_givenV5AndSuccessResponse503() async throws {
        // given
        let httpClient = MockHTTPResponsesClient()
        httpClient.httpResponses = [
            try HTTPResponse.mockError(code: .serviceUnavailable, label: "service unavailable")
        ]

        let api = ConversationsAPIV5(httpClient: httpClient)

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

    func testGetMLSOneToOneConversation_Success_Response_V5_And_Next_Versions() async throws {
        // Given

        let httpClient = try HTTPClientMock(
            code: .ok,
            payloadResourceName: "testGetMLSOneOnOneConversationV5SuccessResponse200"
        )

        let supportedVersions = APIVersion.v5.andNextVersions

        let suts = supportedVersions.map { $0.buildAPI(client: httpClient) }

        // When

        try await withThrowingTaskGroup(of: Conversation.self) { taskGroup in
            for sut in suts {
                taskGroup.addTask {
                    try await sut.getMLSOneToOneConversation(
                        userID: Scaffolding.userID,
                        in: Scaffolding.domain
                    )
                }
            }

            for try await value in taskGroup {
                // Then
                XCTAssertEqual(value.id, Scaffolding.mlsConversationID)
            }
        }
    }

    func testGetMLSOneToOneConversation_UnsupportedVersionError_V0_to_V4() async throws {
        // Given
        let httpClient = HTTPClientMock(
            code: .ok,
            payload: nil
        )

        let unsupportedVersions: [APIVersion] = [.v0, .v1, .v2, .v3, .v4]
        let suts = unsupportedVersions.map { $0.buildAPI(client: httpClient) }

        try await withThrowingTaskGroup(of: Void.self) { taskGroup in
            for sut in suts {
                taskGroup.addTask {
                    // Then
                    await self.XCTAssertThrowsError(ConversationsAPIError.unsupportedEndpointForAPIVersion) {
                        // When
                        try await sut.getMLSOneToOneConversation(
                            userID: Scaffolding.userID,
                            in: Scaffolding.domain
                        )
                    }
                }

                try await taskGroup.waitForAll()
            }
        }
    }

    func testGetMLSOneToOneConversation_Failure_Response_MLS_Not_Enabled() async throws {
        // Given

        let httpClient = try HTTPClientMock(
            code: .badRequest,
            errorLabel: "mls-not-enabled"
        )

        let sut = APIVersion.v5.buildAPI(client: httpClient)

        // Then

        await XCTAssertThrowsError(ConversationsAPIError.mlsNotEnabled) {
            // When
            try await sut.getMLSOneToOneConversation(
                userID: Scaffolding.userID,
                in: Scaffolding.domain
            )
        }
    }

    func testGetMLSOneToOneConversation_Failure_Response_Not_Connected() async throws {
        // Given

        let httpClient = try HTTPClientMock(
            code: .forbidden,
            errorLabel: "not-connected"
        )

        let sut = APIVersion.v5.buildAPI(client: httpClient)

        // Then

        await XCTAssertThrowsError(ConversationsAPIError.usersNotConnected) {
            // When
            try await sut.getMLSOneToOneConversation(
                userID: Scaffolding.userID,
                in: Scaffolding.domain
            )
        }
    }

    private enum Scaffolding {
        static let userID = "99db9768-04e3-4b5d-9268-831b6a25c4ab"
        static let domain = "domain.com"
        static let mlsConversationID = UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!
    }

}

private extension APIVersion {
    func buildAPI(client: any HTTPClient) -> any ConversationsAPI {
        let builder = ConversationsAPIBuilder(httpClient: client)
        return builder.makeAPI(for: self)
    }
}
