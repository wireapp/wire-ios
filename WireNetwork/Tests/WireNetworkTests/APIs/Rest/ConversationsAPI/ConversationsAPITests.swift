//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

@testable import WireNetwork
@testable import WireNetworkSupport

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

    // MARK: addChannelPermission

    func testAddChannelAdminsPermission() async throws {
        // given
        let apiVersions: [APIVersion] = [.v8]

        // when
        // then
        try await apiSnapshotHelper.verifyRequest(for: apiVersions) { sut in
            try await sut.addChannelPermission(
                conversationID: Scaffolding.conversationID.uuidString,
                conversationDomain: Scaffolding.domain,
                permission: .admins
            )
        }
    }

    func testAddChannelEveryonePermission() async throws {
        // given
        let apiVersions: [APIVersion] = [.v8]

        // when
        // then
        try await apiSnapshotHelper.verifyRequest(for: apiVersions) { sut in
            try await sut.addChannelPermission(
                conversationID: Scaffolding.conversationID.uuidString,
                conversationDomain: Scaffolding.domain,
                permission: .everyone
            )
        }
    }

    // MARK: updateConversationAccess

    func testSomething() async throws {
        fatalError()
    }

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

        // then

        try await apiSnapshotHelper.verifyRequest(for: [.v0], apiService: apiService) { api in
            let pager = try await api.getLegacyConversationIdentifiers()

            for try await _ in pager {
                // trigger fetching date
            }
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
        try await apiSnapshotHelper.verifyRequest(for: [.v1], apiService: apiService) { api in
            let pager = try await api.getConversationIdentifiers()

            for try await _ in pager {
                // trigger fetching date
            }
        }
    }

    func testGetConversationIdentifiers_givenV1AndSuccessResponse200_thenVerifyResponse() async throws {
        // given
        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "testGetConversationIdentifiers_givenV1AndSuccessResponse200")
        ])

        let expectedIDs: [QualifiedID] = [
            QualifiedID(
                id: try XCTUnwrap(UUID(uuidString: "14c3f0ff-1a46-4e66-8845-ae084f09c483")),
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
            id: try XCTUnwrap(UUID(uuidString: "213248a1-5499-418f-8173-5010d1c1e506")),
            domain: "wire.com"
        )

        // when
        // then
        try await apiSnapshotHelper.verifyRequest(for: apiVersions) { sut in
            _ = try await sut.getConversations(for: [qualifiedID])
        }
    }

    func testGetConversations_givenV0_thenItValidatesArguments() async throws {
        // given
        let sut = ConversationsAPIV0(apiService: MockAPIServiceProtocol())

        // when
        await XCTAssertThrowsErrorAsync {
            _ = try await sut.getConversations(for: [])
        } errorHandler: { error in
            switch error {
            case ConversationsAPIError.illegalArgument:
                break
            default:
                XCTFail("unexpected error")
            }
        }
    }

    func testGetConversations_givenV0AndSuccessResponse200_thenVerifyResponse() async throws {
        // given
        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "testGetConversations_givenV0AndSuccessResponse200")
        ])

        let api = ConversationsAPIV0(apiService: apiService)
        let ids = [
            QualifiedID(
                id: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!,
                domain: "example.com"
            )
        ]

        // when
        let list = try await api.getConversations(for: ids)

        // then
        XCTAssertEqual(list.found.count, 1)
        XCTAssertEqual(list.notFound.count, 1)
        XCTAssertEqual(list.failed.count, 1)
    }

    func testGetConversations_givenV0AndSuccessResponse400() async throws {
        // given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .badRequest
        )

        let api = ConversationsAPIV0(apiService: apiService)
        let ids = [
            QualifiedID(
                id: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!,
                domain: "example.com"
            )
        ]

        do {
            // when
            _ = try await api.getConversations(for: ids)
        } catch ConversationsAPIError.invalidBody {
            // then
            XCTAssertTrue(true)
        } catch {
            XCTFail("expected error 'ConversationsAPIError.invalidBody'")
        }
    }

    func testGetConversations_givenV0AndSuccessResponse503() async throws {
        // given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .serviceUnavailable,
            label: "service unavailable"
        )

        let api = ConversationsAPIV0(apiService: apiService)
        let ids = [
            QualifiedID(
                id: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!,
                domain: "example.com"
            )
        ]

        do {
            // when
            _ = try await api.getConversations(for: ids)
        } catch let error as FailureResponse {
            // then
            XCTAssertEqual(error.code, 503)
            XCTAssertEqual(error.label, "service unavailable")
        } catch {
            XCTFail("expected error 'FailureResponse', got \(String(describing: error))")
        }
    }

    func testGetConversations_givenV2AndSuccessResponse200_thenVerifyResponse() async throws {
        // given
        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "testGetConversations_givenV2AndSuccessResponse200")
        ])

        let api = ConversationsAPIV2(apiService: apiService)
        let ids = [
            QualifiedID(
                id: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!,
                domain: "example.com"
            )
        ]

        // when
        let list = try await api.getConversations(for: ids)

        // then
        XCTAssertEqual(list.found.count, 1)
        XCTAssertEqual(list.notFound.count, 1)
        XCTAssertEqual(list.failed.count, 1)
    }

    func testGetConversations_givenV2AndSuccessResponse400() async throws {
        // given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .badRequest
        )

        let api = ConversationsAPIV2(apiService: apiService)
        let ids = [
            QualifiedID(
                id: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!,
                domain: "example.com"
            )
        ]

        do {
            // when
            _ = try await api.getConversations(for: ids)
        } catch ConversationsAPIError.invalidBody {
            // then
            XCTAssertTrue(true)
        } catch {
            XCTFail("expected error 'ConversationsAPIError.invalidBody'")
        }
    }

    func testGetConversations_givenV2AndSuccessResponse503() async throws {
        // given

        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .serviceUnavailable,
            label: "service unavailable"
        )

        let api = ConversationsAPIV2(apiService: apiService)
        let ids = [
            QualifiedID(
                id: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!,
                domain: "example.com"
            )
        ]

        do {
            // when
            _ = try await api.getConversations(for: ids)
        } catch let error as FailureResponse {
            // then
            XCTAssertEqual(error.code, 503)
            XCTAssertEqual(error.label, "service unavailable")
        } catch {
            XCTFail("expected error 'FailureResponse', got \(String(describing: error))")
        }
    }

    func testGetConversations_givenV3AndSuccessResponse200_thenVerifyResponse() async throws {
        // given
        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "testGetConversations_givenV3AndSuccessResponse200")
        ])

        let api = ConversationsAPIV3(apiService: apiService)
        let ids = [
            QualifiedID(
                id: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!,
                domain: "example.com"
            )
        ]

        // when
        let list = try await api.getConversations(for: ids)

        // then
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
            statusCode: .badRequest
        )

        let api = ConversationsAPIV3(apiService: apiService)
        let ids = [
            QualifiedID(
                id: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!,
                domain: "example.com"
            )
        ]

        do {
            // when
            _ = try await api.getConversations(for: ids)
        } catch ConversationsAPIError.invalidBody {
            // then
            XCTAssertTrue(true)
        } catch {
            XCTFail("expected error 'ConversationsAPIError.invalidBody'")
        }
    }

    func testGetConversations_givenV3AndSuccessResponse503() async throws {
        // given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .serviceUnavailable,
            label: "service unavailable"
        )

        let api = ConversationsAPIV3(apiService: apiService)
        let ids = [
            QualifiedID(
                id: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!,
                domain: "example.com"
            )
        ]

        do {
            // when
            _ = try await api.getConversations(for: ids)
        } catch let error as FailureResponse {
            // then
            XCTAssertEqual(error.code, 503)
            XCTAssertEqual(error.label, "service unavailable")
        } catch {
            XCTFail("expected error 'FailureResponse', got \(String(describing: error))")
        }
    }

    func testGetConversations_givenV5AndSuccessResponse200_thenVerifyResponse() async throws {
        // given
        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "testGetConversations_givenV5AndSuccessResponse200")
        ])

        let api = ConversationsAPIV5(apiService: apiService)
        let ids = [
            QualifiedID(
                id: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!,
                domain: "example.com"
            )
        ]

        // when
        let list = try await api.getConversations(for: ids)

        // then
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
        let ids = [
            QualifiedID(
                id: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!,
                domain: "example.com"
            )
        ]

        do {
            // when
            _ = try await api.getConversations(for: ids)
        } catch let error as FailureResponse {
            // then
            XCTAssertEqual(error.code, 503)
            XCTAssertEqual(error.label, "service unavailable")
        } catch {
            XCTFail("expected error 'FailureResponse', got \(String(describing: error))")
        }
    }

    func testGetConversations_givenV8AndSuccessResponse200_thenVerifyResponse() async throws {
        // given
        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "testGetConversations_givenV8AndSuccessResponse200")
        ])

        let api = ConversationsAPIV8(apiService: apiService)
        let ids = [
            QualifiedID(
                id: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!,
                domain: "example.com"
            )
        ]

        // when
        let list = try await api.getConversations(for: ids)

        // then
        XCTAssertEqual(list.found.count, 1)
        XCTAssertEqual(list.notFound.count, 1)
        XCTAssertEqual(list.failed.count, 1)

        let conversation = try XCTUnwrap(list.found.first)
        XCTAssertEqual(conversation.epochTimestamp, Date(timeIntervalSince1970: 1_620_816_722))
        XCTAssertEqual(conversation.cipherSuite, .MLS_128_DHKEMP256_AES128GCM_SHA256_P256)
        XCTAssertEqual(conversation.addPermission, .everyone) // Can be decoded in API >= v8
    }

    // MARK: - GetMLSOneToOneConversation

    func testGetMLSOneToOneConversation_Success_Response_V10_AndNext_Versions() async throws {
        // Given

        let supportedVersions = APIVersion.v10.andNextVersions

        let mocks: [MockAPIServiceProtocol.Response] = Array(
            repeating: (.ok, "testGetMLSOneOnOneConversationV10SuccessResponse200"),
            count: supportedVersions.count
        )

        let apiService = MockAPIServiceProtocol.withResponses(mocks)

        let suts = supportedVersions.map { $0.buildAPI(apiService: apiService) }

        // When

        for sut in suts {
            let (mlsConversation, publicKeys) = try await sut.getMLSOneToOneConversation(
                userID: Scaffolding.userID,
                in: Scaffolding.domain
            )

            XCTAssertEqual(mlsConversation.id, Scaffolding.mlsConversationID)
            XCTAssertEqual(publicKeys, Scaffolding.publicKeys)
        }
    }

    func testGetMLSOneToOneConversation_Success_Response_V8_V9() async throws {
        // Given

        let supportedVersions = [APIVersion.v8, APIVersion.v9]

        let mocks: [MockAPIServiceProtocol.Response] = Array(
            repeating: (.ok, "testGetMLSOneOnOneConversationV8SuccessResponse200"),
            count: supportedVersions.count
        )

        let apiService = MockAPIServiceProtocol.withResponses(mocks)

        let suts = supportedVersions.map { $0.buildAPI(apiService: apiService) }

        // When

        for sut in suts {
            let (mlsConversation, publicKeys) = try await sut.getMLSOneToOneConversation(
                userID: Scaffolding.userID,
                in: Scaffolding.domain
            )

            XCTAssertEqual(mlsConversation.id, Scaffolding.mlsConversationID)
            XCTAssertEqual(publicKeys, Scaffolding.publicKeys)
        }
    }

    func testGetMLSOneToOneConversation_Success_Response_V6_V7() async throws {
        // Given

        let supportedVersions = [APIVersion.v6, APIVersion.v7]

        let mocks: [MockAPIServiceProtocol.Response] = Array(
            repeating: (.ok, "testGetMLSOneOnOneConversationV6SuccessResponse200"),
            count: supportedVersions.count
        )

        let apiService = MockAPIServiceProtocol.withResponses(mocks)

        let suts = supportedVersions.map { $0.buildAPI(apiService: apiService) }

        // When

        for sut in suts {
            let (mlsConversation, publicKeys) = try await sut.getMLSOneToOneConversation(
                userID: Scaffolding.userID,
                in: Scaffolding.domain
            )

            XCTAssertEqual(mlsConversation.id, Scaffolding.mlsConversationID)
            XCTAssertEqual(publicKeys, Scaffolding.publicKeys)
        }
    }

    func testGetMLSOneToOneConversation_Success_Response_V5() async throws {
        // Given

        let supportedVersions = [APIVersion.v5]

        let mocks: [MockAPIServiceProtocol.Response] = Array(
            repeating: (.ok, "testGetMLSOneOnOneConversationV5SuccessResponse200"),
            count: supportedVersions.count
        )

        let apiService = MockAPIServiceProtocol.withResponses(mocks)

        let suts = supportedVersions.map { $0.buildAPI(apiService: apiService) }

        // When

        for sut in suts {
            let (mlsConversation, publicKeys) = try await sut.getMLSOneToOneConversation(
                userID: Scaffolding.userID,
                in: Scaffolding.domain
            )

            XCTAssertEqual(mlsConversation.id, Scaffolding.mlsConversationID)
            XCTAssertNil(publicKeys)
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

    // MARK: - createGroupConversation

    func testCreateGroupConversation_givenV0_To_V2_AndSuccessResponse200_thenVerifyResponse() async throws {
        // given

        let supportedVersions = [APIVersion.v0, .v1, .v2]
        let mocks: [MockAPIServiceProtocol.Response] = Array(
            repeating: (.ok, "testCreateGroupConversation_givenV0AndSuccessResponse200"),
            count: supportedVersions.count
        )

        let apiService = MockAPIServiceProtocol.withResponses(mocks)

        let suts = supportedVersions.map { $0.buildAPI(apiService: apiService) }

        // when
        // then

        XCTAssertEqual(suts.count, supportedVersions.count)

        for sut in suts {
            let conversation = try await sut.createGroupConversation(
                parameters: Scaffolding.createGroupConversationParameters
            )

            XCTAssertEqual(conversation.access, [.private])
            XCTAssertEqual(conversation.messageProtocol, .proteus)
            XCTAssertEqual(conversation.accessRoles, [.teamMember])
        }
    }

    func testCreateGroupConversation_givenV3_To_V4_AndSuccessResponse200_thenVerifyResponse() async throws {
        // given

        let supportedVersions = [APIVersion.v3, .v4]
        let mocks: [MockAPIServiceProtocol.Response] = Array(
            repeating: (.ok, "testCreateGroupConversation_givenV3AndSuccessResponse200"),
            count: supportedVersions.count
        )

        let apiService = MockAPIServiceProtocol.withResponses(mocks)

        let suts = supportedVersions.map { $0.buildAPI(apiService: apiService) }

        // when
        // then

        XCTAssertEqual(suts.count, supportedVersions.count)

        for sut in suts {
            let conversation = try await sut.createGroupConversation(
                parameters: Scaffolding.createGroupConversationParameters
            )

            XCTAssertEqual(conversation.access, [.private])
            XCTAssertEqual(conversation.messageProtocol, .proteus)
            XCTAssertEqual(conversation.accessRoles, [.teamMember])
        }
    }

    func testCreateGroupConversation_givenV5_To_V7_AndSuccessResponse200_thenVerifyResponse() async throws {
        // given

        let supportedVersions = [APIVersion.v5, .v7]
        let mocks: [MockAPIServiceProtocol.Response] = Array(
            repeating: (.ok, "testCreateGroupConversation_givenV5AndSuccessResponse200"),
            count: supportedVersions.count
        )

        let apiService = MockAPIServiceProtocol.withResponses(mocks)

        let suts = supportedVersions.map { $0.buildAPI(apiService: apiService) }

        // when
        // then

        XCTAssertEqual(suts.count, supportedVersions.count)

        for sut in suts {
            let conversation = try await sut.createGroupConversation(
                parameters: Scaffolding.createGroupConversationParameters
            )

            XCTAssertEqual(conversation.access, [.private])
            XCTAssertEqual(conversation.messageProtocol, .proteus)
            XCTAssertEqual(conversation.accessRoles, [.teamMember])
        }
    }

    func testCreateGroupConversation_givenV8_And_V9_AndSuccessResponse200_thenVerifyResponse() async throws {
        // given

        let supportedVersions = [APIVersion.v8, APIVersion.v9]
        let mocks: [MockAPIServiceProtocol.Response] = Array(
            repeating: (.ok, "testCreateGroupConversation_givenV8AndSuccessResponse200"),
            count: supportedVersions.count
        )

        let apiService = MockAPIServiceProtocol.withResponses(mocks)

        let suts = supportedVersions.map { $0.buildAPI(apiService: apiService) }

        // when
        // then

        XCTAssertEqual(suts.count, supportedVersions.count)

        for sut in suts {
            let conversation = try await sut.createGroupConversation(
                parameters: Scaffolding.createGroupConversationParameters
            )

            XCTAssertEqual(conversation.access, [.private])
            XCTAssertEqual(conversation.messageProtocol, .proteus)
            XCTAssertEqual(conversation.accessRoles, [.teamMember])
        }
    }

    func testCreateGroupConversation_givenV10_AndSuccessResponse201_thenVerifyResponse() async throws {
        // given

        let supportedVersions = APIVersion.v10.andNextVersions
        let mocks: [MockAPIServiceProtocol.Response] = Array(
            repeating: (.created, "testCreateGroupConversation_givenV10AndSuccessResponse201"),
            count: supportedVersions.count
        )

        let apiService = MockAPIServiceProtocol.withResponses(mocks)

        let suts = supportedVersions.map { $0.buildAPI(apiService: apiService) }

        // when
        // then

        XCTAssertEqual(suts.count, supportedVersions.count)

        for sut in suts {
            let conversation = try await sut.createGroupConversation(
                parameters: Scaffolding.createGroupConversationParameters
            )

            XCTAssertEqual(
                conversation.id?.uuidString,
                "99DB9768-04E3-4B5D-9268-831B6A25C4AB"
            )
            XCTAssertNotNil(conversation.members?.selfMember)
        }
    }

    func testCreateGroupConversation_givenV10_AndNoSelfMember_AndSuccessResponse201_thenVerifyResponse() async throws {
        // given

        let supportedVersions = APIVersion.v10.andNextVersions

        let mocks: [MockAPIServiceProtocol.Response] = Array(
            repeating: (.created, "testCreateGroupConversation_givenV10_EmptySelfMember_SuccessResponse201"),
            count: supportedVersions.count
        )

        let apiService = MockAPIServiceProtocol.withResponses(mocks)

        let suts = supportedVersions.map { $0.buildAPI(apiService: apiService) }

        // when
        // then

        XCTAssertEqual(suts.count, supportedVersions.count)

        for sut in suts {
            let conversation = try await sut.createGroupConversation(
                parameters: Scaffolding.createGroupConversationParameters
            )

            XCTAssertEqual(
                conversation.id?.uuidString,
                "99DB9768-04E3-4B5D-9268-831B6A25C4AB"
            )
            XCTAssertNil(conversation.members?.selfMember)
            XCTAssertNotNil(conversation.members)
        }
    }

    func testCreateGroupConversation_givenV0_To_V2_AndSuccessResponse201_thenVerifyResponse() async throws {
        // given

        let supportedVersions = [APIVersion.v0, .v1, .v2]
        let mocks: [MockAPIServiceProtocol.Response] = Array(
            repeating: (.created, "testCreateGroupConversation_givenV0AndSuccessResponse201"),
            count: supportedVersions.count
        )

        let apiService = MockAPIServiceProtocol.withResponses(mocks)

        let suts = supportedVersions.map { $0.buildAPI(apiService: apiService) }

        // when
        // then

        XCTAssertEqual(suts.count, supportedVersions.count)

        for sut in suts {
            let conversation = try await sut.createGroupConversation(
                parameters: Scaffolding.createGroupConversationParameters
            )

            XCTAssertEqual(conversation.access, [.private])
            XCTAssertEqual(conversation.messageProtocol, .proteus)
            XCTAssertEqual(conversation.accessRoles, [.teamMember])
        }
    }

    func testCreateGroupConversation_givenV3_To_V4_AndSuccessResponse201_thenVerifyResponse() async throws {
        // given

        let supportedVersions = [APIVersion.v3, .v4]
        let mocks: [MockAPIServiceProtocol.Response] = Array(
            repeating: (.created, "testCreateGroupConversation_givenV3AndSuccessResponse201"),
            count: supportedVersions.count
        )

        let apiService = MockAPIServiceProtocol.withResponses(mocks)

        let suts = supportedVersions.map { $0.buildAPI(apiService: apiService) }

        // when
        // then

        XCTAssertEqual(suts.count, supportedVersions.count)

        for sut in suts {
            let conversation = try await sut.createGroupConversation(
                parameters: Scaffolding.createGroupConversationParameters
            )

            XCTAssertEqual(conversation.access, [.private])
            XCTAssertEqual(conversation.messageProtocol, .proteus)
            XCTAssertEqual(conversation.accessRoles, [.teamMember])
        }
    }

    func testCreateGroupConversation_givenV5_To_V7_AndSuccessResponse201_thenVerifyResponse() async throws {
        // given

        let supportedVersions = [APIVersion.v5, .v7]
        let mocks: [MockAPIServiceProtocol.Response] = Array(
            repeating: (.created, "testCreateGroupConversation_givenV5AndSuccessResponse201"),
            count: supportedVersions.count
        )

        let apiService = MockAPIServiceProtocol.withResponses(mocks)

        let suts = supportedVersions.map { $0.buildAPI(apiService: apiService) }

        // when
        // then

        XCTAssertEqual(suts.count, supportedVersions.count)

        for sut in suts {
            let conversation = try await sut.createGroupConversation(
                parameters: Scaffolding.createGroupConversationParameters
            )

            XCTAssertEqual(conversation.access, [.private])
            XCTAssertEqual(conversation.messageProtocol, .proteus)
            XCTAssertEqual(conversation.accessRoles, [.teamMember])
        }
    }

    func testCreateGroupConversation_givenV8_And_Next_Versions_AndSuccessResponse201_thenVerifyResponse() async throws {
        // given

        let supportedVersions = APIVersion.v8.andNextVersions
        let mocks: [MockAPIServiceProtocol.Response] = Array(
            repeating: (.created, "testCreateGroupConversation_givenV8AndSuccessResponse201"),
            count: supportedVersions.count
        )

        let apiService = MockAPIServiceProtocol.withResponses(mocks)

        let suts = supportedVersions.map { $0.buildAPI(apiService: apiService) }

        // when
        // then

        XCTAssertEqual(suts.count, supportedVersions.count)

        for sut in suts {
            let conversation = try await sut.createGroupConversation(
                parameters: Scaffolding.createGroupConversationParameters
            )

            XCTAssertEqual(conversation.access, [.private])
            XCTAssertEqual(conversation.messageProtocol, .proteus)
            XCTAssertEqual(conversation.accessRoles, [.teamMember])
        }
    }

    func testCreateGroupConversation_givenV0_And_Next_Versions_AndFailureResponse_Non_Empty_Member_List() async throws {

        // given
        let supportedVersions = APIVersion.v0.andNextVersions
        let apiService = MockAPIServiceProtocol.withError(statusCode: .badRequest, label: "non-empty-member-list")
        let suts = supportedVersions.map { $0.buildAPI(apiService: apiService) }

        // when
        // then

        XCTAssertEqual(suts.count, supportedVersions.count)

        for sut in suts {
            await XCTAssertThrowsErrorAsync(ConversationsAPIError.nonEmptyMemberList) {
                _ = try await sut.createGroupConversation(
                    parameters: Scaffolding.createGroupConversationParameters
                )
            }
        }
    }

    func testCreateGroupConversation_givenV0_And_Next_Versions_AndFailureResponse_Invalid_Body() async throws {

        // given
        let supportedVersions = APIVersion.v0.andNextVersions
        let apiService = MockAPIServiceProtocol.withError(statusCode: .badRequest, label: "")
        let suts = supportedVersions.map { $0.buildAPI(apiService: apiService) }

        // when
        // then

        XCTAssertEqual(suts.count, supportedVersions.count)

        for sut in suts {
            await XCTAssertThrowsErrorAsync(ConversationsAPIError.invalidBody) {
                _ = try await sut.createGroupConversation(
                    parameters: Scaffolding.createGroupConversationParameters
                )
            }
        }
    }

    func testCreateGroupConversation_givenV0_And_Next_Versions_AndFailureResponse_Missing_Legalhold_Consent(
    ) async throws {

        // given
        let supportedVersions = APIVersion.v0.andNextVersions
        let apiService = MockAPIServiceProtocol.withError(statusCode: .forbidden, label: "missing-legalhold-consent")
        let suts = supportedVersions.map { $0.buildAPI(apiService: apiService) }

        // when
        // then

        XCTAssertEqual(suts.count, supportedVersions.count)

        for sut in suts {
            await XCTAssertThrowsErrorAsync(ConversationsAPIError.missingLegalHoldConsent) {
                _ = try await sut.createGroupConversation(
                    parameters: Scaffolding.createGroupConversationParameters
                )
            }
        }
    }

    func testCreateGroupConversation_givenV0_And_Next_Versions_AndFailureResponse_Operation_Denied() async throws {

        // given
        let supportedVersions = APIVersion.v0.andNextVersions
        let apiService = MockAPIServiceProtocol.withError(statusCode: .forbidden, label: "operation-denied")
        let suts = supportedVersions.map { $0.buildAPI(apiService: apiService) }

        // when
        // then

        XCTAssertEqual(suts.count, supportedVersions.count)

        for sut in suts {
            await XCTAssertThrowsErrorAsync(ConversationsAPIError.operationDenied) {
                _ = try await sut.createGroupConversation(
                    parameters: Scaffolding.createGroupConversationParameters
                )
            }
        }
    }

    func testCreateGroupConversation_givenV0_And_Next_Versions_AndFailureResponse_No_Team_Member() async throws {

        // given
        let supportedVersions = APIVersion.v0.andNextVersions
        let apiService = MockAPIServiceProtocol.withError(statusCode: .forbidden, label: "no-team-member")
        let suts = supportedVersions.map { $0.buildAPI(apiService: apiService) }

        // when
        // then

        XCTAssertEqual(suts.count, supportedVersions.count)

        for sut in suts {
            await XCTAssertThrowsErrorAsync(ConversationsAPIError.noTeamMember) {
                _ = try await sut.createGroupConversation(
                    parameters: Scaffolding.createGroupConversationParameters
                )
            }
        }
    }

    func testCreateGroupConversation_givenV0_And_Next_Versions_AndFailureResponse_Not_Connected() async throws {

        // given
        let supportedVersions = APIVersion.v0.andNextVersions
        let apiService = MockAPIServiceProtocol.withError(statusCode: .forbidden, label: "not-connected")
        let suts = supportedVersions.map { $0.buildAPI(apiService: apiService) }

        // when
        // then

        XCTAssertEqual(suts.count, supportedVersions.count)

        for sut in suts {
            await XCTAssertThrowsErrorAsync(ConversationsAPIError.notConnected) {
                _ = try await sut.createGroupConversation(
                    parameters: Scaffolding.createGroupConversationParameters
                )
            }
        }
    }

    func testCreateGroupConversation_givenV0_And_Next_Versions_AndFailureResponse_Access_Denied() async throws {

        // given
        let supportedVersions = APIVersion.v0.andNextVersions
        let apiService = MockAPIServiceProtocol.withError(statusCode: .forbidden, label: "access-denied")
        let suts = supportedVersions.map { $0.buildAPI(apiService: apiService) }

        // when
        // then

        XCTAssertEqual(suts.count, supportedVersions.count)

        for sut in suts {
            await XCTAssertThrowsErrorAsync(ConversationsAPIError.accessDenied) {
                _ = try await sut.createGroupConversation(
                    parameters: Scaffolding.createGroupConversationParameters
                )
            }
        }
    }

    func testCreateGroupConversation_givenV3_And_Next_Versions_AndFailureResponse_MLS_Not_Enabled() async throws {

        // given
        let supportedVersions = APIVersion.v3.andNextVersions
        let apiService = MockAPIServiceProtocol.withError(statusCode: .badRequest, label: "mls-not-enabled")
        let suts = supportedVersions.map { $0.buildAPI(apiService: apiService) }

        // when
        // then

        XCTAssertEqual(suts.count, supportedVersions.count)

        for sut in suts {
            await XCTAssertThrowsErrorAsync(ConversationsAPIError.mlsNotEnabled) {
                _ = try await sut.createGroupConversation(
                    parameters: Scaffolding.createGroupConversationParameters
                )
            }
        }
    }

    func testCreateGroupConversation_givenV4_And_Next_Versions_AndFailureResponse_Non_Federating_Backend() async throws {

        // given
        let supportedVersions = APIVersion.v4.andNextVersions
        let mocks: [MockAPIServiceProtocol.Response] = Array(
            repeating: (.conflict, "testCreateGroupConversation_givenV4AndFailureResponse409"),
            count: supportedVersions.count
        )

        let apiService = MockAPIServiceProtocol.withResponses(mocks)

        let suts = supportedVersions.map { $0.buildAPI(apiService: apiService) }

        // when
        // then

        XCTAssertEqual(suts.count, supportedVersions.count)

        for sut in suts {
            await XCTAssertThrowsErrorAsync(ConversationsAPIError.nonFederatingBackends(["string"])) {
                _ = try await sut.createGroupConversation(
                    parameters: Scaffolding.createGroupConversationParameters
                )
            }
        }
    }

    func testCreateGroupConversation_givenV4_And_Next_Versions_AndFailureResponse_Unreachable_Backends() async throws {

        // given
        let supportedVersions = APIVersion.v4.andNextVersions
        let apiService = MockAPIServiceProtocol.withError(statusCode: .unreachable, label: "")
        let suts = supportedVersions.map { $0.buildAPI(apiService: apiService) }

        // when
        // then

        XCTAssertEqual(suts.count, supportedVersions.count)

        for sut in suts {
            await XCTAssertThrowsErrorAsync(ConversationsAPIError.unreachableBackends) {
                _ = try await sut.createGroupConversation(
                    parameters: Scaffolding.createGroupConversationParameters
                )
            }
        }
    }

    func testCreateGroupConversation_givenV0_To_V7_Unsupported_Channel_Creation() async throws {

        // given
        let unsupportedVersions = APIVersion.allCasesUpTo(.v8)
        let apiService = MockAPIServiceProtocol.withError(statusCode: .unreachable, label: "")
        let suts = unsupportedVersions.map { $0.buildAPI(apiService: apiService) }

        // when
        // then

        XCTAssertEqual(suts.count, unsupportedVersions.count)

        for sut in suts {
            await XCTAssertThrowsErrorAsync(ConversationsAPIError.unsupportedChannelCreationForAPIEndpoint) {
                _ = try await sut.createGroupConversation(
                    parameters: Scaffolding.createChannelParameters
                )
            }
        }
    }

    func testCreateGroupConversation_givenV8_And_Channel_Creation_AndSuccessResponse201_thenVerifyRespons(
    ) async throws {

        // given
        let supportedVersions = APIVersion.v8.andNextVersions
        let mocks: [MockAPIServiceProtocol.Response] = Array(
            repeating: (.created, "testCreateGroupConversation_givenV8AndSuccessResponse201"),
            count: supportedVersions.count
        )

        let apiService = MockAPIServiceProtocol.withResponses(mocks)

        let suts = supportedVersions.map { $0.buildAPI(apiService: apiService) }

        // when
        // then

        XCTAssertEqual(suts.count, supportedVersions.count)

        for sut in suts {
            let conversation = try await sut.createGroupConversation(
                parameters: Scaffolding.createChannelParameters
            )

            XCTAssertEqual(conversation.access, [.private])
            XCTAssertEqual(conversation.messageProtocol, .proteus)
            XCTAssertEqual(conversation.accessRoles, [.teamMember])
        }
    }

    func testAddChannelPermission_givenV8_AndSuccessResponse200_thenVerifyResponse() async throws {
        // given
        let supportedVersions = APIVersion.v8.andNextVersions
        let mocks: [MockAPIServiceProtocol.Response] = Array(
            repeating: (.ok, "testAddChannelPermission_givenV8AndSuccessResponse200"),
            count: supportedVersions.count
        )

        let apiService = MockAPIServiceProtocol.withResponses(mocks)

        let suts = supportedVersions.map { $0.buildAPI(apiService: apiService) }

        // when
        // then

        XCTAssertEqual(suts.count, supportedVersions.count)

        for sut in suts {
            let permission = try await sut.addChannelPermission(
                conversationID: Scaffolding.conversationID.uuidString,
                conversationDomain: Scaffolding.domain,
                permission: .admins
            )

            XCTAssertEqual(permission, .admins)
        }
    }

    func testAddChannelPermission_givenV0_To_V7_AndFailure_Unsupported_Endpoint_For_API_Version() async throws {

        // given
        let unsupportedVersions = APIVersion.allCasesUpTo(.v8)
        let apiService = MockAPIServiceProtocol.withError(statusCode: .unreachable, label: "")
        let suts = unsupportedVersions.map { $0.buildAPI(apiService: apiService) }

        // when
        // then

        XCTAssertEqual(suts.count, unsupportedVersions.count)

        for sut in suts {
            await XCTAssertThrowsErrorAsync(ConversationsAPIError.unsupportedEndpointForAPIVersion) {
                try await sut.addChannelPermission(
                    conversationID: Scaffolding.conversationID.uuidString,
                    conversationDomain: Scaffolding.domain,
                    permission: .admins
                )
            }
        }
    }

    func testAddChannelPermission_givenV8_And_Next_Versions_AndFailureResponse_No_Team_Found() async throws {
        // given
        let supportedVersions = APIVersion.v8.andNextVersions
        let apiService = MockAPIServiceProtocol.withError(statusCode: .notFound, label: "no-team")
        let suts = supportedVersions.map { $0.buildAPI(apiService: apiService) }

        // when
        // then

        XCTAssertEqual(suts.count, supportedVersions.count)

        for sut in suts {
            await XCTAssertThrowsErrorAsync(ConversationsAPIError.teamNotFound) {
                try await sut.addChannelPermission(
                    conversationID: Scaffolding.conversationID.uuidString,
                    conversationDomain: Scaffolding.domain,
                    permission: .admins
                )
            }
        }
    }

    func testAddChannelPermission_givenV8_And_Next_Versions_AndFailureResponse_No_Conversation_Found() async throws {
        // given
        let supportedVersions = APIVersion.v8.andNextVersions
        let apiService = MockAPIServiceProtocol.withError(statusCode: .notFound, label: "no-conversation")
        let suts = supportedVersions.map { $0.buildAPI(apiService: apiService) }

        // when
        // then

        XCTAssertEqual(suts.count, supportedVersions.count)

        for sut in suts {
            await XCTAssertThrowsErrorAsync(ConversationsAPIError.conversationNotFound) {
                try await sut.addChannelPermission(
                    conversationID: Scaffolding.conversationID.uuidString,
                    conversationDomain: Scaffolding.domain,
                    permission: .admins
                )
            }
        }
    }

    func testAddChannelPermission_givenV8_And_Next_Versions_AndFailureResponse_Insufficient_Authorization(
    ) async throws {
        // given
        let supportedVersions = APIVersion.v8.andNextVersions
        let apiService = MockAPIServiceProtocol.withError(statusCode: .forbidden, label: "action-denied")
        let suts = supportedVersions.map { $0.buildAPI(apiService: apiService) }

        // when
        // then

        XCTAssertEqual(suts.count, supportedVersions.count)

        for sut in suts {
            await XCTAssertThrowsErrorAsync(ConversationsAPIError.insufficienAuthorization) {
                try await sut.addChannelPermission(
                    conversationID: Scaffolding.conversationID.uuidString,
                    conversationDomain: Scaffolding.domain,
                    permission: .admins
                )
            }
        }
    }

    func testAddChannelPermission_givenV8_And_Next_Versions_AndFailureResponse_Invalid_Operation() async throws {
        // given
        let supportedVersions = APIVersion.v8.andNextVersions
        let apiService = MockAPIServiceProtocol.withError(statusCode: .forbidden, label: "invalid-op")
        let suts = supportedVersions.map { $0.buildAPI(apiService: apiService) }

        // when
        // then

        XCTAssertEqual(suts.count, supportedVersions.count)

        for sut in suts {
            await XCTAssertThrowsErrorAsync(ConversationsAPIError.invalidOperation) {
                try await sut.addChannelPermission(
                    conversationID: Scaffolding.conversationID.uuidString,
                    conversationDomain: Scaffolding.domain,
                    permission: .admins
                )
            }
        }
    }

    func testAddChannelPermission_givenV8_And_Next_Versions_AndFailureResponse_Invalid_Body() async throws {
        // given
        let supportedVersions = APIVersion.v8.andNextVersions
        let apiService = MockAPIServiceProtocol.withError(statusCode: .badRequest, label: "")
        let suts = supportedVersions.map { $0.buildAPI(apiService: apiService) }

        // when
        // then

        XCTAssertEqual(suts.count, supportedVersions.count)

        for sut in suts {
            await XCTAssertThrowsErrorAsync(ConversationsAPIError.invalidBody) {
                try await sut.addChannelPermission(
                    conversationID: Scaffolding.conversationID.uuidString,
                    conversationDomain: Scaffolding.domain,
                    permission: .admins
                )
            }
        }
    }

    func testAddChannelPermission_givenV8_And_Next_Versions_AndFailureResponse_Conversation_Access_Denied(
    ) async throws {
        // given
        let supportedVersions = APIVersion.v8.andNextVersions
        let apiService = MockAPIServiceProtocol.withError(statusCode: .forbidden, label: "access-denied")
        let suts = supportedVersions.map { $0.buildAPI(apiService: apiService) }

        // when
        // then

        XCTAssertEqual(suts.count, supportedVersions.count)

        for sut in suts {
            await XCTAssertThrowsErrorAsync(ConversationsAPIError.accessDenied) {
                try await sut.addChannelPermission(
                    conversationID: Scaffolding.conversationID.uuidString,
                    conversationDomain: Scaffolding.domain,
                    permission: .admins
                )
            }
        }
    }

    func testAddChannelPermission_givenV8_And_Next_Versions_AndFailureResponse_Access_Denied() async throws {
        // given
        let supportedVersions = APIVersion.v8.andNextVersions
        let apiService = MockAPIServiceProtocol.withError(statusCode: .forbidden, label: "access-denied")
        let suts = supportedVersions.map { $0.buildAPI(apiService: apiService) }

        // when
        // then

        XCTAssertEqual(suts.count, supportedVersions.count)

        for sut in suts {
            await XCTAssertThrowsErrorAsync(ConversationsAPIError.accessDenied) {
                try await sut.addChannelPermission(
                    conversationID: Scaffolding.conversationID.uuidString,
                    conversationDomain: Scaffolding.domain,
                    permission: .admins
                )
            }
        }
    }

    func testAddChannelPermission_givenV8_And_Next_Versions_AndFailureResponse_Not_A_Team_Member() async throws {
        // given
        let supportedVersions = APIVersion.v8.andNextVersions
        let apiService = MockAPIServiceProtocol.withError(statusCode: .forbidden, label: "no-team-member")
        let suts = supportedVersions.map { $0.buildAPI(apiService: apiService) }

        // when
        // then

        XCTAssertEqual(suts.count, supportedVersions.count)

        for sut in suts {
            await XCTAssertThrowsErrorAsync(ConversationsAPIError.noTeamMember) {
                try await sut.addChannelPermission(
                    conversationID: Scaffolding.conversationID.uuidString,
                    conversationDomain: Scaffolding.domain,
                    permission: .admins
                )
            }
        }
    }

    func testAddChannelPermission_givenV8_And_Next_Versions_AndFailureResponse_Not_Connected() async throws {
        // given
        let supportedVersions = APIVersion.v8.andNextVersions
        let apiService = MockAPIServiceProtocol.withError(statusCode: .forbidden, label: "not-connected")
        let suts = supportedVersions.map { $0.buildAPI(apiService: apiService) }

        // when
        // then

        XCTAssertEqual(suts.count, supportedVersions.count)

        for sut in suts {
            await XCTAssertThrowsErrorAsync(ConversationsAPIError.usersNotConnected) {
                try await sut.addChannelPermission(
                    conversationID: Scaffolding.conversationID.uuidString,
                    conversationDomain: Scaffolding.domain,
                    permission: .admins
                )
            }
        }
    }

    func testAddChannelPermission_givenV8_And_Next_Versions_AndFailureResponse_Operation_Denied() async throws {
        // given
        let supportedVersions = APIVersion.v8.andNextVersions
        let apiService = MockAPIServiceProtocol.withError(statusCode: .forbidden, label: "operation-denied")
        let suts = supportedVersions.map { $0.buildAPI(apiService: apiService) }

        // when
        // then

        XCTAssertEqual(suts.count, supportedVersions.count)

        for sut in suts {
            await XCTAssertThrowsErrorAsync(ConversationsAPIError.insufficientPermissions) {
                try await sut.addChannelPermission(
                    conversationID: Scaffolding.conversationID.uuidString,
                    conversationDomain: Scaffolding.domain,
                    permission: .admins
                )
            }
        }
    }

    func testAddChannelPermission_givenV8_And_Next_Versions_AndFailureResponse_Unreachable_Backends() async throws {
        // given
        let supportedVersions = APIVersion.v8.andNextVersions
        let apiService = MockAPIServiceProtocol.withError(statusCode: .unreachable, label: "")
        let suts = supportedVersions.map { $0.buildAPI(apiService: apiService) }

        // when
        // then

        XCTAssertEqual(suts.count, supportedVersions.count)

        for sut in suts {
            await XCTAssertThrowsErrorAsync(ConversationsAPIError.unreachableBackends) {
                try await sut.addChannelPermission(
                    conversationID: Scaffolding.conversationID.uuidString,
                    conversationDomain: Scaffolding.domain,
                    permission: .admins
                )
            }
        }
    }

    func testAddChannelPermission_givenV8_And_Next_Versions_AndFailureResponse_Non_Federating_Backends() async throws {

        // given
        let supportedVersions = APIVersion.v8.andNextVersions
        let mocks: [MockAPIServiceProtocol.Response] = Array(
            repeating: (.conflict, "testAddChannelPermission_givenV8AndFailureResponse409"),
            count: supportedVersions.count
        )

        let apiService = MockAPIServiceProtocol.withResponses(mocks)

        let suts = supportedVersions.map { $0.buildAPI(apiService: apiService) }

        // when
        // then

        XCTAssertEqual(suts.count, supportedVersions.count)

        for sut in suts {
            await XCTAssertThrowsErrorAsync(ConversationsAPIError.nonFederatingBackends(["string"])) {
                try await sut.addChannelPermission(
                    conversationID: Scaffolding.conversationID.uuidString,
                    conversationDomain: Scaffolding.domain,
                    permission: .admins
                )
            }
        }
    }

    private enum Scaffolding {
        static let userID = "99db9768-04e3-4b5d-9268-831b6a25c4ab"
        static let domain = "domain.com"
        static let mlsConversationID = UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!
        static let publicKeys = MLSPublicKeys(ed25519: "string", p256: "string", p384: "string", p521: "string")
        static let conversationID = UUID.mockID1
        static let guestLinkV0 = "https://exampleV0.com"
        static let guestLinkV4 = "https://exampleV4.com"
        static let createGroupConversationParameters = CreateGroupConversationParameters(
            groupType: .group,
            messageProtocol: .mls,
            creatorClientID: UUID.mockID1.uuidString,
            qualifiedUserIDs: [.mockID1],
            unqualifiedUserIDs: [.mockID2],
            name: "test",
            accessMode: [.code, .invite],
            accessRoles: [.teamMember],
            legacyAccessRole: .teamMember,
            teamID: .mockID1,
            isReadReceiptsEnabled: true,
            skipCreator: false
        )

        static let createChannelParameters = CreateGroupConversationParameters(
            groupType: .channel,
            messageProtocol: .mls,
            creatorClientID: UUID.mockID1.uuidString,
            qualifiedUserIDs: [.mockID1],
            unqualifiedUserIDs: [.mockID2],
            name: "test",
            accessMode: [.code, .invite],
            accessRoles: [.teamMember],
            legacyAccessRole: .teamMember,
            teamID: .mockID1,
            isReadReceiptsEnabled: true
        )
    }

}

extension ConversationsAPIError: Equatable {
    public static func == (lhs: ConversationsAPIError, rhs: ConversationsAPIError) -> Bool {
        switch (lhs, rhs) {
        case (.notImplemented, .notImplemented):
            true
        case (.invalidBody, .invalidBody):
            true
        case (.unsupportedEndpointForAPIVersion, .unsupportedEndpointForAPIVersion):
            true
        case (.mlsNotEnabled, .mlsNotEnabled):
            true
        case (.usersNotConnected, .usersNotConnected):
            true
        case (.userAndDomainShouldNotBeEmpty, .userAndDomainShouldNotBeEmpty):
            true
        case (.accessDenied, .accessDenied):
            true
        case (.conversationNotFound, .conversationNotFound):
            true
        case (.conversationCodeNotFound, .conversationCodeNotFound):
            true
        case (.guestLinksDisabled, .guestLinksDisabled):
            true
        case (.invalidConversationID, .invalidConversationID):
            true
        case (.nonEmptyMemberList, .nonEmptyMemberList):
            true
        case (.missingLegalHoldConsent, .missingLegalHoldConsent):
            true
        case (.operationDenied, .operationDenied):
            true
        case (.noTeamMember, .noTeamMember):
            true
        case (.notConnected, .notConnected):
            true
        case (.unsupportedChannelCreationForAPIEndpoint, .unsupportedChannelCreationForAPIEndpoint):
            true
        case (.nonFederatingBackends, .nonFederatingBackends):
            true
        case (.unreachableBackends, .unreachableBackends):
            true
        case (.insufficienAuthorization, .insufficienAuthorization):
            true
        case (.insufficientPermissions, .insufficientPermissions):
            true
        case (.invalidOperation, .invalidOperation):
            true
        case (.teamNotFound, .teamNotFound):
            true
        default: false
        }
    }

}

private extension APIVersion {
    func buildAPI(apiService: any APIServiceProtocol) -> any ConversationsAPI {
        let builder = ConversationsAPIBuilder(apiService: apiService)
        return builder.makeAPI(for: self)
    }
}
