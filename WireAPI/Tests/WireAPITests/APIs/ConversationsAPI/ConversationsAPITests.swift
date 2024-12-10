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

import WireTestingPackage
import XCTest
@testable import WireAPI
@testable import WireAPISupport

final class ConversationsAPITests: XCTestCase {

    private var apiSnapshotHelper: APIServiceSnapshotHelper<any ConversationsAPI>!

    // MARK: - Setup

    override func setUp() {
        apiSnapshotHelper = APIServiceSnapshotHelper<any ConversationsAPI> { apiService, apiVersion in
            ConversationsAPIBuilder(apiService: apiService)
                .makeAPI(for: apiVersion)

        }
    }

    override func tearDown() {
        apiSnapshotHelper = nil
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

    func testGetLegacyConversationIdentifiers_givenV0AndSuccessResponse200_thenVerifyRequests() async throws {
        // given

        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "testGetLegacyConversationIdentifiers_givenV0AndSuccessResponse200")
        ])

        // when
        let api = ConversationsAPIV0(apiService: apiService)
        let pager = try await api.getLegacyConversationIdentifiers()

        for try await _ in pager {
            // trigger fetching date
        }

        // then

        try await apiSnapshotHelper.verifyRequest(for: [.v0], apiService: apiService) { api in
            _ = try await api.getLegacyConversationIdentifiers()
        }
    }

    func testGetLegacyConversationIdentifiers_givenV0AndSuccessResponse200_thenVerifyResponse() async throws {
        // given
        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "testGetLegacyConversationIdentifiers_givenV0AndSuccessResponse200")
        ])

        let expectedIDs: [UUID] = [
            try XCTUnwrap(UUID(uuidString: "14c3f0ff-1a46-4e66-8845-ae084f09c483"))
        ]

        let api = ConversationsAPIV0(apiService: apiService)

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

        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .serviceUnavailable,
            label: "service unavailable"
        )

        let api = ConversationsAPIV0(apiService: apiService)

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
        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "testGetConversationIdentifiers_givenV1AndSuccessResponse200")
        ])

        // when
        let api = ConversationsAPIV1(apiService: apiService)
        let pager = try await api.getConversationIdentifiers()

        for try await _ in pager {
            // trigger fetching date
        }

        try await apiSnapshotHelper.verifyRequest(for: [.v1], apiService: apiService) { api in
            _ = try await api.getConversationIdentifiers()
        }
    }

    func testGetConversationIdentifiers_givenV1AndSuccessResponse200_thenVerifyResponse() async throws {
        // given
        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "testGetConversationIdentifiers_givenV1AndSuccessResponse200")
        ])

        let expectedIDs: [QualifiedID] = [
            QualifiedID(
                uuid: try XCTUnwrap(UUID(uuidString: "14c3f0ff-1a46-4e66-8845-ae084f09c483")),
                domain: "staging.zinfra.io"
            )
        ]

        let api = ConversationsAPIV1(apiService: apiService)

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
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .serviceUnavailable,
            label: "service unavailable"
        )

        let api = ConversationsAPIV1(apiService: apiService)

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

        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "testGetConversations_givenV0AndSuccessResponse200")
        ])

        let api = ConversationsAPIV0(apiService: apiService)

        // when
        // then
        let list = try await api.getConversations(for: [])
        XCTAssertEqual(list.found.count, 1)
        XCTAssertEqual(list.notFound.count, 1)
        XCTAssertEqual(list.failed.count, 1)
    }

    func testGetConversations_givenV0AndSuccessResponse400() async throws {
        // given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .badRequest,
            label: "invalid body"
        )

        let api = ConversationsAPIV0(apiService: apiService)

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
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .serviceUnavailable,
            label: "service unavailable"
        )

        let api = ConversationsAPIV0(apiService: apiService)

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

        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "testGetConversations_givenV2AndSuccessResponse200")
        ])

        let api = ConversationsAPIV2(apiService: apiService)

        // when
        // then
        let list = try await api.getConversations(for: [])
        XCTAssertEqual(list.found.count, 1)
        XCTAssertEqual(list.notFound.count, 1)
        XCTAssertEqual(list.failed.count, 1)
    }

    func testGetConversations_givenV2AndSuccessResponse400() async throws {
        // given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .badRequest,
            label: "invalid body"
        )

        let api = ConversationsAPIV2(apiService: apiService)

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

        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .serviceUnavailable,
            label: "service unavailable"
        )

        let api = ConversationsAPIV2(apiService: apiService)

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

        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "testGetConversations_givenV3AndSuccessResponse200")
        ])

        let api = ConversationsAPIV3(apiService: apiService)

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
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .badRequest,
            label: "invalid body"
        )

        let api = ConversationsAPIV3(apiService: apiService)

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
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .serviceUnavailable,
            label: "service unavailable"
        )

        let api = ConversationsAPIV3(apiService: apiService)

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

        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "testGetConversations_givenV5AndSuccessResponse200")
        ])

        let api = ConversationsAPIV5(apiService: apiService)

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
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .serviceUnavailable,
            label: "service unavailable"
        )

        let api = ConversationsAPIV5(apiService: apiService)

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

        let supportedVersions = APIVersion.v5.andNextVersions

        let mocks: [MockAPIServiceProtocol.Response] = Array(
            repeating: (.ok, "testGetMLSOneOnOneConversationV5SuccessResponse200"),
            count: supportedVersions.count
        )

        let apiService = MockAPIServiceProtocol.withResponses(mocks)

        let suts = supportedVersions.map { $0.buildAPI(apiService: apiService) }

        // When

        for sut in suts {
            let mlsConversation = try await sut.getMLSOneToOneConversation(
                userID: Scaffolding.userID,
                in: Scaffolding.domain
            )

            XCTAssertEqual(mlsConversation.id, Scaffolding.mlsConversationID)
        }
    }

    func testGetMLSOneToOneConversation_UnsupportedVersionError_V0_to_V4() async throws {
        // Given

        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "")
        ])

        let unsupportedVersions: [APIVersion] = [.v0, .v1, .v2, .v3, .v4]
        let suts = unsupportedVersions.map { $0.buildAPI(apiService: apiService) }

        try await withThrowingTaskGroup(of: Void.self) { taskGroup in
            for sut in suts {
                taskGroup.addTask {
                    // Then
                    await self.XCTAssertThrowsErrorAsync(ConversationsAPIError.unsupportedEndpointForAPIVersion) {
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

        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .badRequest,
            label: "mls-not-enabled"
        )

        let sut = APIVersion.v5.buildAPI(apiService: apiService)

        // Then

        await XCTAssertThrowsErrorAsync(ConversationsAPIError.mlsNotEnabled) {
            // When
            try await sut.getMLSOneToOneConversation(
                userID: Scaffolding.userID,
                in: Scaffolding.domain
            )
        }
    }

    func testGetMLSOneToOneConversation_Failure_Response_Not_Connected() async throws {
        // Given

        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .forbidden,
            label: "not-connected"
        )

        let sut = APIVersion.v5.buildAPI(apiService: apiService)

        // Then

        await XCTAssertThrowsErrorAsync(ConversationsAPIError.usersNotConnected) {
            // When
            try await sut.getMLSOneToOneConversation(
                userID: Scaffolding.userID,
                in: Scaffolding.domain
            )
        }
    }

    func testGetMLSOneToOneConversation_Failure_UserID_And_Domain_Empty() async throws {
        // Given

        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "testGetMLSOneOnOneConversationV5SuccessResponse200")
        ])

        let sut = APIVersion.v5.buildAPI(apiService: apiService)

        // Then

        await XCTAssertThrowsErrorAsync(ConversationsAPIError.userAndDomainShouldNotBeEmpty) {
            // When
            try await sut.getMLSOneToOneConversation(
                userID: "",
                in: ""
            )
        }
    }

    func testGetConversationGuestLink() async throws {
        // Given

        let apiVersions = APIVersion.allCases
        let conversationID = Scaffolding.conversationID.uuidString

        // Then

        try await apiSnapshotHelper.verifyRequest(for: apiVersions) { sut in
            // When
            _ = try await sut.getConversationGuestLink(
                conversationID: conversationID
            )
        }
    }

    func testGetConversationGuestLink_Success_Response_V0_To_V3() async throws {

        let supportedVersions: [APIVersion] = [.v0, .v1, .v2, .v3]

        let mocks: [MockAPIServiceProtocol.Response] = Array(
            repeating: (.ok, "testGetConversationGuestLinkV0SuccessResponse200"),
            count: supportedVersions.count
        )

        let apiService = MockAPIServiceProtocol.withResponses(mocks)

        let conversationID = Scaffolding.conversationID.uuidString
        let suts = supportedVersions.map { $0.buildAPI(apiService: apiService) }

        // When

        for sut in suts {
            let uri = try await sut.getConversationGuestLink(conversationID: conversationID)

            XCTAssertEqual(uri, Scaffolding.guestLinkV0)
        }

    }

    func testGetConversationGuestLink_Success_Response_V4_And_Next_Versions() async throws {

        let supportedVersions = APIVersion.v4.andNextVersions

        let mocks: [MockAPIServiceProtocol.Response] = Array(
            repeating: (.ok, "testGetConversationGuestLinkV4SuccessResponse200"),
            count: supportedVersions.count
        )

        let apiService = MockAPIServiceProtocol.withResponses(mocks)

        let conversationID = Scaffolding.conversationID.uuidString
        let suts = supportedVersions.map { $0.buildAPI(apiService: apiService) }

        // When

        for sut in suts {
            let uri = try await sut.getConversationGuestLink(conversationID: conversationID)

            XCTAssertEqual(uri, Scaffolding.guestLinkV4)
        }

    }

    func testGetConversationGuestLinkV0_Failure_Access_Denied() async throws {
        // Given

        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .forbidden,
            label: "access-denied"
        )

        let conversationID = Scaffolding.conversationID.uuidString

        let sut = APIVersion.v0.buildAPI(apiService: apiService)

        // Then

        await XCTAssertThrowsErrorAsync(ConversationsAPIError.accessDenied) {
            // When
            try await sut.getConversationGuestLink(conversationID: conversationID)
        }
    }

    func testGetConversationGuestLinkV0_Failure_Invalid_Conversation_ID() async throws {
        // Given

        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .notFound,
            label: "cnv"
        )

        let conversationID = Scaffolding.conversationID.uuidString

        let sut = APIVersion.v0.buildAPI(apiService: apiService)

        // Then

        await XCTAssertThrowsErrorAsync(ConversationsAPIError.invalidConversationID) {
            // When
            try await sut.getConversationGuestLink(conversationID: conversationID)
        }
    }

    func testGetConversationGuestLinkV0_Failure_No_Conversation_Found() async throws {
        // Given

        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .notFound,
            label: "no-conversation"
        )

        let conversationID = Scaffolding.conversationID.uuidString

        let sut = APIVersion.v0.buildAPI(apiService: apiService)

        // Then

        await XCTAssertThrowsErrorAsync(ConversationsAPIError.conversationNotFound) {
            // When
            try await sut.getConversationGuestLink(conversationID: conversationID)
        }
    }

    func testGetConversationGuestLinkV0_Failure_No_Conversation_Code_Found() async throws {
        // Given

        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .notFound,
            label: "no-conversation-code"
        )

        let conversationID = Scaffolding.conversationID.uuidString

        let sut = APIVersion.v0.buildAPI(apiService: apiService)

        // Then

        await XCTAssertThrowsErrorAsync(ConversationsAPIError.conversationCodeNotFound) {
            // When
            try await sut.getConversationGuestLink(conversationID: conversationID)
        }
    }

    func testGetConversationGuestLinkV0_Failure_Guest_Links_Disabled() async throws {
        // Given

        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .conflict,
            label: "guest-links-disabled"
        )

        let conversationID = Scaffolding.conversationID.uuidString

        let sut = APIVersion.v0.buildAPI(apiService: apiService)

        // Then

        await XCTAssertThrowsErrorAsync(ConversationsAPIError.guestLinksDisabled) {
            // When
            try await sut.getConversationGuestLink(conversationID: conversationID)
        }
    }

    func testGetConversationGuestLinkV4_Invalid_Conversation_ID() async throws {
        // Given

        // Dedicated error code in V4
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .badRequest,
            label: "cnv"
        )

        let conversationID = Scaffolding.conversationID.uuidString

        let sut = APIVersion.v4.buildAPI(apiService: apiService)

        // Then

        await XCTAssertThrowsErrorAsync(ConversationsAPIError.invalidConversationID) {
            // When
            try await sut.getConversationGuestLink(conversationID: conversationID)
        }
    }

    private enum Scaffolding {
        static let userID = "99db9768-04e3-4b5d-9268-831b6a25c4ab"
        static let domain = "domain.com"
        static let mlsConversationID = UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!
        static let conversationID = UUID.mockID1
        static let guestLinkV0 = "https://exampleV0.com"
        static let guestLinkV4 = "https://exampleV4.com"
    }

}

private extension APIVersion {
    func buildAPI(apiService: any APIServiceProtocol) -> any ConversationsAPI {
        let builder = ConversationsAPIBuilder(apiService: apiService)
        return builder.makeAPI(for: self)
    }
}
