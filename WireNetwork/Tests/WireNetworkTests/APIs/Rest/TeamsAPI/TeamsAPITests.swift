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

import XCTest

@testable import WireNetwork
@testable import WireNetworkSupport

final class TeamsAPITests: XCTestCase {

    private var apiSnapshotHelper: APIServiceSnapshotHelper<any TeamsAPI>!

    // MARK: - Setup

    override func setUp() {
        apiSnapshotHelper = APIServiceSnapshotHelper { apiService, apiVersion in
            let builder = TeamsAPIBuilder(apiService: apiService)
            return builder.makeAPI(for: apiVersion)
        }
    }

    override func tearDown() {
        apiSnapshotHelper = nil
    }

    // MARK: - Request generation

    func testGetTeamRequest() async throws {
        try await apiSnapshotHelper.verifyRequestForAllAPIVersions { sut in
            _ = try await sut.getTeam(for: .mockID1)
        }
    }

    func testGetTeamRolesRequest() async throws {
        try await apiSnapshotHelper.verifyRequestForAllAPIVersions { sut in
            _ = try await sut.getTeamRoles(for: .mockID1)
        }
    }

    func testGetTeamMembersRequest() async throws {
        try await apiSnapshotHelper.verifyRequestForAllAPIVersions { sut in
            _ = try await sut.getTeamMembers(for: .mockID1, maxResults: 2000)
        }
    }

    func testGetLegalholdInfoRequest() async throws {
        try await apiSnapshotHelper.verifyRequestForAllAPIVersions { sut in
            _ = try await sut.getLegalholdInfo(for: .mockID1, userID: .mockID2)
        }
    }

    // MARK: - Response handling

    // MARK: - V0

    func testGetTeamForID_SuccessResponse_200_V0_Then_Verify_Request() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "GetTeamSuccessResponseV0")
        ])

        let teamID = try XCTUnwrap(Team.ID(uuidString: "213248a1-5499-418f-8173-5010d1c1e506"))

        // Then
        try await apiSnapshotHelper.verifyRequest(for: [.v0], apiService: apiService) { sut in
            // When
            let result = try await sut.getTeam(for: teamID)

            // Then
            XCTAssertEqual(
                result,
                Team(
                    id: teamID,
                    name: "teamName",
                    creatorID: UUID(uuidString: "302c59b0-037c-4b0f-a3ed-ccdbfb4cfe2c")!,
                    logoID: "iconID",
                    logoKey: "iconKey",
                    splashScreenID: nil
                )
            )
        }
    }

    func testGetTeamForID_FailureResponse_InvalidID_V0() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .notFound,
            label: ""
        )

        let sut = TeamsAPIV0(apiService: apiService)

        // Then
        await XCTAssertThrowsErrorAsync(TeamsAPIError.invalidTeamID) {
            // When
            try await sut.getTeam(for: Team.ID())
        }
    }

    func testGetTeamForID_FailureResponse_TeamNotFound_V0() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .notFound,
            label: "no-team"
        )

        let sut = TeamsAPIV0(apiService: apiService)

        // Then
        await XCTAssertThrowsErrorAsync(TeamsAPIError.teamNotFound) {
            // When
            try await sut.getTeam(for: Team.ID())
        }
    }

    func testGetTeamRolesForID_SuccessResponse_200_V0_Then_Verify_Request() async throws {

        // Given
        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "GetTeamRolesSuccessResponseV0")
        ])

        // Then
        try await apiSnapshotHelper.verifyRequest(for: APIVersion.allCasesUpTo(.v15), apiService: apiService) { sut in
            // When
            let result = try await sut.getTeamRoles(for: .mockID1)

            // Then
            XCTAssertEqual(
                result,
                [
                    ConversationRole(
                        name: "admin",
                        actions: [
                            .addConversationMember,
                            .removeConversationMember
                        ]
                    )
                ]
            )
        }
    }

    func testGetTeamRolesForID_FailureResponse_NoTeamMember_V0() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .forbidden,
            label: "no-team-member"
        )

        let sut = TeamsAPIV0(apiService: apiService)

        // Then
        await XCTAssertThrowsErrorAsync(TeamsAPIError.selfUserIsNotTeamMember) {
            // When
            try await sut.getTeamRoles(for: Team.ID())
        }
    }

    func testGetTeamRolesForID_FailureResponse_TeamNotFound_V0() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .notFound,
            label: ""
        )

        let sut = TeamsAPIV0(apiService: apiService)

        // Then
        await XCTAssertThrowsErrorAsync(TeamsAPIError.teamNotFound) {
            // When
            try await sut.getTeamRoles(for: Team.ID())
        }
    }

    func testGetMembers_SuccessResponse_200_V0_Then_Verify_Request() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "GetTeamMembersSuccessResponseV0")
        ])

        // Then
        try await apiSnapshotHelper.verifyRequest(for: [.v0], apiService: apiService) { sut in
            // When
            let result = try await sut.getTeamMembers(
                for: .mockID1,
                maxResults: 2000
            )

            // Then
            XCTAssertEqual(
                result,
                [
                    TeamMember(
                        userID: try XCTUnwrap(UUID(uuidString: "849f56b9-5c9f-4682-ad76-c580b5724464")),
                        creationDate: try XCTUnwrap(
                            ISO8601DateFormatter.fractionalInternetDateTime
                                .date(from: "2024-05-14T08:55:04.779Z")
                        ),
                        creatorID: try XCTUnwrap(UUID(uuidString: "c57d68c8-1ed4-41c7-b0a8-33026b7381fc")),
                        legalholdStatus: .pending,
                        permissions: TeamMemberPermissions(
                            copyPermissions: 123,
                            selfPermissions: 456
                        )
                    )
                ]
            )
        }
    }

    func testGetTeamMembers_FailureResponse_InvalidQueryParameter_V0() async throws {

        // Given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .badRequest,
            label: ""
        )

        let sut = TeamsAPIV0(apiService: apiService)

        // Then
        await XCTAssertThrowsErrorAsync(TeamsAPIError.invalidQueryParmeter) {
            // When
            try await sut.getTeamMembers(
                for: Team.ID(),
                maxResults: 2000
            )
        }
    }

    func testGetTeamMembers_FailureResponse_NoTeamMember_V0() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .forbidden,
            label: "no-team-member"
        )

        let sut = TeamsAPIV0(apiService: apiService)

        // Then
        await XCTAssertThrowsErrorAsync(TeamsAPIError.selfUserIsNotTeamMember) {
            // When
            try await sut.getTeamMembers(
                for: Team.ID(),
                maxResults: 2000
            )
        }
    }

    func testGetTeamMembers_FailureResponse_TeamNotFound_V0() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .notFound,
            label: ""
        )

        let sut = TeamsAPIV0(apiService: apiService)

        // Then
        await XCTAssertThrowsErrorAsync(TeamsAPIError.teamNotFound) {
            // When
            try await sut.getTeamMembers(
                for: Team.ID(),
                maxResults: 2000
            )
        }
    }

    func testGetLegalholdInfo_SuccessResponse_200_V0_Then_Verify_Request() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "GetLegalHoldInfoSuccessResponseV0")
        ])

        try await apiSnapshotHelper.verifyRequest(for: [.v0], apiService: apiService) { sut in
            // When
            let result = try await sut.getLegalholdInfo(
                for: .mockID1,
                userID: .mockID2
            )

            // Then
            XCTAssertEqual(
                result,
                TeamMemberLegalholdInfo(
                    status: .pending,
                    clientID: "abc123",
                    prekey: .init(id: 12_345, base64EncodedKey: "foo")
                )
            )
        }
    }

    func testGetLegalholdInfo_FailureResponse_InvalidRequest_V0() async throws {
        try await internalTest_GetLegalholdInfo_Failure(
            expectedError: TeamsAPIError.invalidRequest,
            for: .v0,
            code: .notFound,
            errorLabel: ""
        )
    }

    func testGetLegalholdInfo_FailureResponse_MemberNotFound_V0() async throws {
        try await internalTest_GetLegalholdInfo_Failure(
            expectedError: TeamsAPIError.teamMemberNotFound,
            for: .v0,
            code: .notFound,
            errorLabel: "no-team-member"
        )
    }

    // MARK: - V2

    func testGetTeamForID_SuccessResponse_200_V2_Then_Verify_Request() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "GetTeamSuccessResponseV2")
        ])

        let teamID = try XCTUnwrap(Team.ID(uuidString: "213248a1-5499-418f-8173-5010d1c1e506"))

        try await apiSnapshotHelper.verifyRequest(for: APIVersion.v2.andNextVersions, apiService: apiService) { sut in
            // When
            let result = try await sut.getTeam(for: teamID)

            // Then
            XCTAssertEqual(
                result,
                Team(
                    id: teamID,
                    name: "teamName",
                    creatorID: try XCTUnwrap(UUID(uuidString: "302c59b0-037c-4b0f-a3ed-ccdbfb4cfe2c")),
                    logoID: "iconID",
                    logoKey: "iconKey",
                    splashScreenID: "splashScreen"
                )
            )
        }
    }

    func testGetMembersByIDs_SuccessResponse_200_V2_Then_Verify_Request() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "GetTeamMembersByIDsSuccessResponseV0")
        ])

        // Then
        try await apiSnapshotHelper.verifyRequest(for: APIVersion.v2.andNextVersions, apiService: apiService) { sut in
            // When
            let result = try await sut.getTeamMembers(
                for: .mockID1,
                maxResults: 2000
            )

            // Then
            XCTAssertEqual(
                result,
                [
                    TeamMember(
                        userID: try XCTUnwrap(UUID(uuidString: "849f56b9-5c9f-4682-ad76-c580b5724464")),
                        creationDate: try XCTUnwrap(
                            ISO8601DateFormatter.fractionalInternetDateTime
                                .date(from: "2024-05-14T08:55:04.779Z")
                        ),
                        creatorID: try XCTUnwrap(UUID(uuidString: "c57d68c8-1ed4-41c7-b0a8-33026b7381fc")),
                        legalholdStatus: .pending,
                        permissions: TeamMemberPermissions(
                            copyPermissions: 123,
                            selfPermissions: 456
                        )
                    )
                ]
            )
        }
    }

    // MARK: - V4

    func testGetTeamForID_FailureResponse_InvalidID_V4() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .badRequest,
            label: ""
        )

        let sut = TeamsAPIV4(apiService: apiService)

        // Then
        await XCTAssertThrowsErrorAsync(TeamsAPIError.invalidTeamID) {
            // When
            try await sut.getTeam(for: Team.ID())
        }
    }

    func testGetTeamRolesForID_FailureResponse_TeamNotFound_V4() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .badRequest,
            label: ""
        )

        let sut = TeamsAPIV4(apiService: apiService)

        // Then
        await XCTAssertThrowsErrorAsync(TeamsAPIError.teamNotFound) {
            // When
            try await sut.getTeamRoles(for: Team.ID())
        }
    }

    func testGetTeamMembers_FailureResponse_InvalidRequest_V4() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .badRequest,
            label: ""
        )

        let sut = TeamsAPIV4(apiService: apiService)

        // Then
        await XCTAssertThrowsErrorAsync(TeamsAPIError.invalidRequest) {
            // When
            try await sut.getTeamMembers(
                for: Team.ID(),
                maxResults: 2000
            )
        }
    }

    func testGetLegalholdInfo_FailureResponse_InvalidRequest_V4() async throws {
        try await internalTest_GetLegalholdInfo_Failure(
            expectedError: TeamsAPIError.invalidRequest,
            for: .v4,
            code: .badRequest,
            errorLabel: ""
        )
    }

    func testGetWhitelistedBots_givenV0_To_V4_AndFailure_Unsupported_Endpoint_For_API_Version() async throws {

        // Given
        let unsupportedVersions = APIVersion.allCasesUpTo(.v5)
        let apiService = MockAPIServiceProtocol.withError(statusCode: .unreachable, label: "")
        let suts = unsupportedVersions.map { apiVersion in
            TeamsAPIBuilder(apiService: apiService)
                .makeAPI(for: apiVersion)
        }

        // When & Then
        XCTAssertEqual(suts.count, unsupportedVersions.count)
        for sut in suts {
            XCTAssertThrowsError(try sut.getWhitelistedBots(for: Scaffolding.teamID, with: "")) { error in
                guard case TeamsAPIError.unsupportedEndpointForAPIVersion = error else {
                    return XCTFail("unexpected error type: \(error)")
                }
            }
        }

    }

    // MARK: - V5

    func testGetTeamForID_FailureResponse_InvalidID_V5() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .notFound,
            label: ""
        )

        let sut = TeamsAPIV5(apiService: apiService)

        // Then
        await XCTAssertThrowsErrorAsync(TeamsAPIError.invalidTeamID) {
            // When
            try await sut.getTeam(for: Team.ID())
        }
    }

    func testGetLegalholdInfo_FailureResponse_InvalidRequest_V5() async throws {
        try await internalTest_GetLegalholdInfo_Failure(
            expectedError: TeamsAPIError.invalidRequest,
            for: .v5,
            code: .notFound,
            errorLabel: ""
        )
    }

    private func internalTest_GetLegalholdInfo_Failure(
        expectedError: any Error & Equatable,
        for apiVersion: APIVersion,
        code: HTTPStatusCode,
        errorLabel: String,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: code,
            label: errorLabel
        )
        let builder = TeamsAPIBuilder(apiService: apiService)
        let sut = builder.makeAPI(for: apiVersion)

        // Then

        await XCTAssertThrowsErrorAsync(expectedError) {
            // When
            try await sut.getLegalholdInfo(
                for: Team.ID(),
                userID: UUID()
            )
        }
    }

    func testGetWhitelistedBots_givenV5AndAbove_AndSuccessResponse200_thenSucceeds() async throws {

        for apiVersion in APIVersion.v5.andNextVersions {

            // Given
            let apiService = MockAPIServiceProtocol.withResponses([
                (.ok, "GetWhitelistedBotsSuccessResponseV5")
            ])

            // When
            try await apiSnapshotHelper.verifyRequest(for: [apiVersion], apiService: apiService) { sut in
                let pager = try sut.getWhitelistedBots(for: Scaffolding.teamID, with: "")
                let bots = try await pager.reduce(into: []) { $0 += $1 }

                // Then
                let expectedBots = [
                    WhitelistedBotProfile(
                        id: UUID(uuidString: "cc0702a4-e126-48a1-87cd-8325835ac071")!,
                        qualifiedID: .init(
                            id: UUID(uuidString: "cc0702a4-e126-48a1-87cd-8325835ac071")!,
                            domain: "example.com"
                        ),
                        name: "Google Calendar",
                        summary: "Calendar",
                        description: "Google Calendar integration for Wire",
                        provider: UUID(uuidString: "d64af9ae-e0c5-4ce6-b38a-02fd9363b54c")!,
                        handle: "some-handle",
                        teamID: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab"),
                        accentID: 2_147_483_647,
                        assets: [],
                        isDeleted: false
                    ),
                    WhitelistedBotProfile(
                        id: UUID(uuidString: "d554c310-8237-4f85-b3cc-b7ae5ec1e6cd")!,
                        qualifiedID: nil,
                        name: "Secure Alert",
                        summary: "Sends alarms",
                        description: "for Alarms",
                        provider: UUID(uuidString: "d64af9ae-e0c5-4ce6-b38a-02fd9363b54c")!,
                        handle: "",
                        teamID: nil,
                        accentID: nil,
                        assets: [
                            UserAsset(
                                key: "lorem-ipsum",
                                size: .complete,
                                type: .image
                            ),
                            UserAsset(
                                key: "dolor",
                                size: .preview,
                                type: .image
                            )
                        ],
                        isDeleted: false
                    )
                ]
                XCTAssertEqual(bots, expectedBots, "failed for apiVersion \(apiVersion)")
            }
        }

    }

    // MARK: - V15

    func testGetTeamRolesForID_SuccessResponse_200_V15_Then_Verify_Request() async throws {

        // Given
        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "GetTeamRolesSuccessResponseV15")
        ])

        // Then
        try await apiSnapshotHelper.verifyRequest(for: APIVersion.v15.andNextVersions, apiService: apiService) { sut in
            // When
            let result = try await sut.getTeamRoles(for: .mockID1)

            // Then
            XCTAssertEqual(
                result,
                [
                    ConversationRole(
                        name: "admin",
                        actions: [
                            .addConversationMember,
                            .modifyConversationHistory,
                            .removeConversationMember
                        ]
                    )
                ]
            )
        }
    }

    // MARK: -

    private enum Scaffolding {
        static let teamID = UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!
    }

}
