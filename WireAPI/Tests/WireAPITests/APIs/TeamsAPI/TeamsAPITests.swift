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

import SnapshotTesting
import XCTest

@testable import WireAPI

final class TeamsAPITests: XCTestCase {

    private var apiSnapshotHelper: APISnapshotHelper<any TeamsAPI>!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        apiSnapshotHelper = APISnapshotHelper { httpClient, apiVersion in
            let builder = TeamsAPIBuilder(httpClient: httpClient)
            return builder.makeAPI(for: apiVersion)
        }
    }

    override func tearDown() {
        apiSnapshotHelper = nil
        super.tearDown()
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
            _ = try await sut.getTeamMembers(for: .mockID1, maxResults: 2_000)
        }
    }

    func testGetLegalholdStatusRequest() async throws {
        try await apiSnapshotHelper.verifyRequestForAllAPIVersions { sut in
            _ = try await sut.getLegalholdStatus(for: .mockID1, userID: .mockID2)
        }
    }

    // MARK: - Response handling

    // MARK: - V0

    func testGetTeamForID_SuccessResponse_200_V0() async throws {
        // Given
        let httpClient = try HTTPClientMock(
            code: .ok,
            payloadResourceName: "GetTeamSuccessResponseV0"
        )

        let sut = TeamsAPIV0(httpClient: httpClient)
        let teamID = try XCTUnwrap(Team.ID(uuidString: "213248a1-5499-418f-8173-5010d1c1e506"))

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

    func testGetTeamForID_FailureResponse_InvalidID_V0() async throws {
        // Given
        let httpClient = try HTTPClientMock(code: .notFound, errorLabel: "")
        let sut = TeamsAPIV0(httpClient: httpClient)

        // Then
        await XCTAssertThrowsError(TeamsAPIError.invalidTeamID) {
            // When
            try await sut.getTeam(for: Team.ID())
        }
    }

    func testGetTeamForID_FailureResponse_TeamNotFound_V0() async throws {
        // Given
        let httpClient = try HTTPClientMock(code: .notFound, errorLabel: "no-team")
        let sut = TeamsAPIV0(httpClient: httpClient)

        // Then
        await XCTAssertThrowsError(TeamsAPIError.teamNotFound) {
            // When
            try await sut.getTeam(for: Team.ID())
        }
    }

    func testGetTeamRolesForID_SuccessResponse_200_V0() async throws {
        // Given
        let httpClient = try HTTPClientMock(
            code: .ok,
            payloadResourceName: "GetTeamRolesSuccessResponseV0"
        )

        let sut = TeamsAPIV0(httpClient: httpClient)

        // When
        let result = try await sut.getTeamRoles(for: Team.ID())

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

    func testGetTeamRolesForID_FailureResponse_NoTeamMember_V0() async throws {
        // Given
        let httpClient = try HTTPClientMock(code: .forbidden, errorLabel: "no-team-member")
        let sut = TeamsAPIV0(httpClient: httpClient)

        // Then
        await XCTAssertThrowsError(TeamsAPIError.selfUserIsNotTeamMember) {
            // When
            try await sut.getTeamRoles(for: Team.ID())
        }
    }

    func testGetTeamRolesForID_FailureResponse_TeamNotFound_V0() async throws {
        // Given
        let httpClient = try HTTPClientMock(code: .notFound, errorLabel: "")
        let sut = TeamsAPIV0(httpClient: httpClient)

        // Then
        await XCTAssertThrowsError(TeamsAPIError.teamNotFound) {
            // When
            try await sut.getTeamRoles(for: Team.ID())
        }
    }

    func testGetMembers_SuccessResponse_200_V0() async throws {
        // Given
        let httpClient = try HTTPClientMock(
            code: .ok,
            payloadResourceName: "GetTeamMembersSuccessResponseV0"
        )

        let sut = TeamsAPIV0(httpClient: httpClient)

        // When
        let result = try await sut.getTeamMembers(
            for: Team.ID(),
            maxResults: 2_000
        )

        // Then
        XCTAssertEqual(
            result,
            [
                TeamMember(
                    userID: try XCTUnwrap(UUID(uuidString: "849f56b9-5c9f-4682-ad76-c580b5724464")),
                    creationDate: try XCTUnwrap(ISO8601DateFormatter.fractionalInternetDateTime.date(from: "2024-05-14T08:55:04.779Z")),
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

    func testGetTeamMembers_FailureResponse_InvalidQueryParameter_V0() async throws {
        // Given
        let httpClient = try HTTPClientMock(code: .badRequest, errorLabel: "")
        let sut = TeamsAPIV0(httpClient: httpClient)

        // Then
        await XCTAssertThrowsError(TeamsAPIError.invalidQueryParmeter) {
            // When
            try await sut.getTeamMembers(
                for: Team.ID(),
                maxResults: 2_000
            )
        }
    }

    func testGetTeamMembers_FailureResponse_NoTeamMember_V0() async throws {
        // Given
        let httpClient = try HTTPClientMock(code: .forbidden, errorLabel: "no-team-member")
        let sut = TeamsAPIV0(httpClient: httpClient)

        // Then
        await XCTAssertThrowsError(TeamsAPIError.selfUserIsNotTeamMember) {
            // When
            try await sut.getTeamMembers(
                for: Team.ID(),
                maxResults: 2_000
            )
        }
    }

    func testGetTeamMembers_FailureResponse_TeamNotFound_V0() async throws {
        // Given
        let httpClient = try HTTPClientMock(code: .notFound, errorLabel: "")
        let sut = TeamsAPIV0(httpClient: httpClient)

        // Then
        await XCTAssertThrowsError(TeamsAPIError.teamNotFound) {
            // When
            try await sut.getTeamMembers(
                for: Team.ID(),
                maxResults: 2_000
            )
        }
    }

    func testGetLegalholdStatus_SuccessResponse_200_V0() async throws {
        // Given
        let httpClient = try HTTPClientMock(
            code: .ok,
            jsonResponse: """
            {
                "status": "pending"
            }
            """
        )

        let sut = TeamsAPIV0(httpClient: httpClient)

        // When
        let result = try await sut.getLegalholdStatus(
            for: Team.ID(),
            userID: UUID()
        )

        // Then
        XCTAssertEqual(result, .pending)
    }

    func testGetLegalholdStatus_FailureResponse_InvalidRequest_V0() async throws {
        // Given
        let httpClient = try HTTPClientMock(code: .notFound, errorLabel: "")
        let sut = TeamsAPIV0(httpClient: httpClient)

        // Then
        await XCTAssertThrowsError(TeamsAPIError.invalidRequest) {
            // When
            try await sut.getLegalholdStatus(
                for: Team.ID(),
                userID: UUID()
            )
        }
    }

    func testGetLegalholdStatus_FailureResponse_MemberNotFound_V0() async throws {
        // Given
        let httpClient = try HTTPClientMock(code: .notFound, errorLabel: "no-team-member")
        let sut = TeamsAPIV0(httpClient: httpClient)

        // Then
        await XCTAssertThrowsError(TeamsAPIError.teamMemberNotFound) {
            // When
            try await sut.getLegalholdStatus(
                for: Team.ID(),
                userID: UUID()
            )
        }
    }

    // MARK: - V2

    func testGetTeamForID_SuccessResponse_200_V2() async throws {
        // Given
        let httpClient = try HTTPClientMock(
            code: .ok,
            payloadResourceName: "GetTeamSuccessResponseV2"
        )

        let sut = TeamsAPIV2(httpClient: httpClient)
        let teamID = try XCTUnwrap(Team.ID(uuidString: "213248a1-5499-418f-8173-5010d1c1e506"))

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

    // MARK: - V4

    func testGetTeamForID_FailureResponse_InvalidID_V4() async throws {
        // Given
        let httpClient = try HTTPClientMock(code: .badRequest, errorLabel: "")
        let sut = TeamsAPIV4(httpClient: httpClient)

        // Then
        await XCTAssertThrowsError(TeamsAPIError.invalidTeamID) {
            // When
            try await sut.getTeam(for: Team.ID())
        }
    }

    func testGetTeamRolesForID_FailureResponse_TeamNotFound_V4() async throws {
        // Given
        let httpClient = try HTTPClientMock(code: .badRequest, errorLabel: "")
        let sut = TeamsAPIV4(httpClient: httpClient)

        // Then
        await XCTAssertThrowsError(TeamsAPIError.teamNotFound) {
            // When
            try await sut.getTeamRoles(for: Team.ID())
        }
    }

    func testGetTeamMembers_FailureResponse_InvalidRequest_V4() async throws {
        // Given
        let httpClient = try HTTPClientMock(code: .badRequest, errorLabel: "")
        let sut = TeamsAPIV4(httpClient: httpClient)

        // Then
        await XCTAssertThrowsError(TeamsAPIError.invalidRequest) {
            // When
            try await sut.getTeamMembers(
                for: Team.ID(),
                maxResults: 2_000
            )
        }
    }

    func testGetLegalholdStatus_FailureResponse_InvalidRequest_V4() async throws {
        // Given
        let httpClient = try HTTPClientMock(code: .badRequest, errorLabel: "")
        let sut = TeamsAPIV4(httpClient: httpClient)

        // Then
        await XCTAssertThrowsError(TeamsAPIError.invalidRequest) {
            // When
            try await sut.getLegalholdStatus(
                for: Team.ID(),
                userID: UUID()
            )
        }
    }

    // MARK: - V5

    func testGetTeamForID_FailureResponse_InvalidID_V5() async throws {
        // Given
        let httpClient = try HTTPClientMock(code: .notFound, errorLabel: "")
        let sut = TeamsAPIV5(httpClient: httpClient)

        // Then
        await XCTAssertThrowsError(TeamsAPIError.invalidTeamID) {
            // When
            try await sut.getTeam(for: Team.ID())
        }
    }

    func testGetLegalholdStatus_FailureResponse_InvalidRequest_V5() async throws {
        // Given
        let httpClient = try HTTPClientMock(code: .notFound, errorLabel: "")
        let sut = TeamsAPIV5(httpClient: httpClient)

        // Then
        await XCTAssertThrowsError(TeamsAPIError.invalidRequest) {
            // When
            try await sut.getLegalholdStatus(
                for: Team.ID(),
                userID: UUID()
            )
        }
    }

}
