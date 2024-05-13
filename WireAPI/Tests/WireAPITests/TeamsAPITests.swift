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
import XCTest
import SnapshotTesting


final class TeamsAPITests: XCTestCase {

    // MARK: - Request generation

    func testGetTeamRequest() async throws {
        try await RequestSnapshotHelper().verifyRequestForAllAPIVersions { sut in
            _ = try await sut.getTeam(for: .mockID1)
        }
    }

    func testGetTeamRolesRequest() async throws {
        try await RequestSnapshotHelper().verifyRequestForAllAPIVersions { sut in
            _ = try await sut.getTeamRoles(for: .mockID1)
        }
    }

    func testGetTeamMembersRequest() async throws {
        try await RequestSnapshotHelper().verifyRequestForAllAPIVersions { sut in
            _ = try await sut.getTeamMembers(for: .mockID1, maxResults: 2000)
        }
    }

    func testGetLegalholdStatusRequest() async throws {
        try await RequestSnapshotHelper().verifyRequestForAllAPIVersions { sut in
            _ = try await sut.getLegalholdStatus(for: .mockID1, userID: .mockID2)
        }
    }

    // MARK: - Response handling

    // MARK: - V0

    func testGetTeamForID_SuccessResponse_200_V0() async throws {
        // Given
        let teamID = Team.ID()
        let creatorID = UUID()
        let httpClient = try HTTPClientMock(
            code: 200,
            jsonResponse: """
            {
                "id": "\(teamID.transportString())",
                "name": "teamName",
                "creator": "\(creatorID.transportString())",
                "icon": "iconID",
                "icon_key": "iconKey"
            }
            """
        )

        let sut = TeamsAPIV0(httpClient: httpClient)

        // When
        let result = try await sut.getTeam(for: teamID)

        // Then
        XCTAssertEqual(
            result,
            Team(
                id: teamID,
                name: "teamName",
                creatorID: creatorID,
                logoID: "iconID",
                logoKey: "iconKey",
                splashScreenID: nil
            )
        )
    }

    func testGetTeamForID_FailureResponse_InvalidID_V0() async throws {
        // Given
        let httpClient = try HTTPClientMock(code: 404, errorLabel: "")
        let sut = TeamsAPIV0(httpClient: httpClient)

        // Then
        await assertAPIError(TeamsAPIError.invalidTeamID) {
            // When
            _ = try await sut.getTeam(for: Team.ID())
        }
    }

    func testGetTeamForID_FailureResponse_TeamNotFound_V0() async throws {
        // Given
        let httpClient = try HTTPClientMock(code: 404, errorLabel: "no-team")
        let sut = TeamsAPIV0(httpClient: httpClient)

        // Then
        await assertAPIError(TeamsAPIError.teamNotFound) {
            // When
            _ = try await sut.getTeam(for: Team.ID())
        }
    }

    func testGetTeamRolesForID_SuccessResponse_200_V0() async throws {
        // Given
        let httpClient = try HTTPClientMock(
            code: 200,
            jsonResponse: """
            {
                "conversation_roles": [
                    {
                        "conversation_role": "admin",
                        "actions": [
                            "add_conversation_member",
                            "remove_conversation_member"
                        ]
                    }
                ]
            }
            """
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
        let httpClient = try HTTPClientMock(code: 403, errorLabel: "no-team-member")
        let sut = TeamsAPIV0(httpClient: httpClient)

        // Then
        await assertAPIError(TeamsAPIError.selfUserIsNotTeamMember) {
            // When
            _ = try await sut.getTeamRoles(for: Team.ID())
        }
    }

    func testGetTeamRolesForID_FailureResponse_TeamNotFound_V0() async throws {
        // Given
        let httpClient = try HTTPClientMock(code: 404, errorLabel: "")
        let sut = TeamsAPIV0(httpClient: httpClient)

        // Then
        await assertAPIError(TeamsAPIError.teamNotFound) {
            // When
            _ = try await sut.getTeamRoles(for: Team.ID())
        }
    }

    func testGetMembers_SuccessResponse_200_V0() async throws {
        // Given
        let userID = UUID()
        let creatorID = UUID()
        let creationDate = Date()
        let httpClient = try HTTPClientMock(
            code: 200,
            jsonResponse: """
            {
                "hasMore": true,
                "members": [
                    {
                        "user": "\(userID.transportString())",
                        "permissions": {
                            "copy": 123,
                            "self": 456
                        },
                        "created_by": "\(creatorID.transportString())",
                        "created_at": "\(ISO8601DateFormatter.default.string(from: creationDate))",
                        "legalhold_status": "pending"
                    }
                ]
            }
            """
        )

        let sut = TeamsAPIV0(httpClient: httpClient)

        // When
        let result = try await sut.getTeamMembers(
            for: Team.ID(),
            maxResults: 2000
        )

        // Then
        XCTAssertEqual(result.count, 1)
        let member = try XCTUnwrap(result.first)
        XCTAssertEqual(member.userID, userID)
        let actualCreationDate = try XCTUnwrap(member.creationDate)
        XCTAssertEqual(actualCreationDate.timeIntervalSince1970, creationDate.timeIntervalSince1970, accuracy: 0.1)
        XCTAssertEqual(member.legalholdStatus, .pending)
        XCTAssertEqual(member.permissions?.copyPermissions, 123)
        XCTAssertEqual(member.permissions?.selfPermissions, 456)
    }

    func testGetTeamMembers_FailureResponse_InvalidQueryParameter_V0() async throws {
        // Given
        let httpClient = try HTTPClientMock(code: 400, errorLabel: "")
        let sut = TeamsAPIV0(httpClient: httpClient)

        // Then
        await assertAPIError(TeamsAPIError.invalidQueryParmeter) {
            // When
            _ = try await sut.getTeamMembers(
                for: Team.ID(),
                maxResults: 2000
            )
        }
    }

    func testGetTeamMembers_FailureResponse_NoTeamMember_V0() async throws {
        // Given
        let httpClient = try HTTPClientMock(code: 403, errorLabel: "no-team-member")
        let sut = TeamsAPIV0(httpClient: httpClient)

        // Then
        await assertAPIError(TeamsAPIError.selfUserIsNotTeamMember) {
            // When
            _ = try await sut.getTeamMembers(
                for: Team.ID(),
                maxResults: 2000
            )
        }
    }

    func testGetTeamMembers_FailureResponse_TeamNotFound_V0() async throws {
        // Given
        let httpClient = try HTTPClientMock(code: 404, errorLabel: "")
        let sut = TeamsAPIV0(httpClient: httpClient)

        // Then
        await assertAPIError(TeamsAPIError.teamNotFound) {
            // When
            _ = try await sut.getTeamMembers(
                for: Team.ID(),
                maxResults: 2000
            )
        }
    }

    func testGetLegalholdStatus_SuccessResponse_200_V0() async throws {
        // Given
        let httpClient = try HTTPClientMock(
            code: 200,
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
        let httpClient = try HTTPClientMock(code: 404, errorLabel: "")
        let sut = TeamsAPIV0(httpClient: httpClient)

        // Then
        await assertAPIError(TeamsAPIError.invalidRequest) {
            // When
            _ = try await sut.getLegalholdStatus(
                for: Team.ID(),
                userID: UUID()
            )
        }
    }

    func testGetLegalholdStatus_FailureResponse_MemberNotFound_V0() async throws {
        // Given
        let httpClient = try HTTPClientMock(code: 404, errorLabel: "no-team-member")
        let sut = TeamsAPIV0(httpClient: httpClient)

        // Then
        await assertAPIError(TeamsAPIError.teamMemberNotFound) {
            // When
            _ = try await sut.getLegalholdStatus(
                for: Team.ID(),
                userID: UUID()
            )
        }
    }

    // MARK: - V2

    func testGetTeamForID_SuccessResponse_200_V2() async throws {
        // Given
        let teamID = Team.ID()
        let creatorID = UUID()
        let httpClient = try HTTPClientMock(
            code: 200,
            jsonResponse: """
            {
                "id": "\(teamID.transportString())",
                "name": "teamName",
                "creator": "\(creatorID.transportString())",
                "icon": "iconID",
                "icon_key": "iconKey",
                "splash_screen": "splashScreen"
            }
            """
        )

        let sut = TeamsAPIV2(httpClient: httpClient)

        // When
        let result = try await sut.getTeam(for: teamID)

        // Then
        XCTAssertEqual(
            result,
            Team(
                id: teamID,
                name: "teamName",
                creatorID: creatorID,
                logoID: "iconID",
                logoKey: "iconKey",
                splashScreenID: "splashScreen"
            )
        )
    }

    // MARK: - V4

    func testGetTeamForID_FailureResponse_InvalidID_V4() async throws {
        // Given
        let httpClient = try HTTPClientMock(code: 400, errorLabel: "")
        let sut = TeamsAPIV4(httpClient: httpClient)

        // Then
        await assertAPIError(TeamsAPIError.invalidTeamID) {
            // When
            _ = try await sut.getTeam(for: Team.ID())
        }
    }

    func testGetTeamRolesForID_FailureResponse_TeamNotFound_V4() async throws {
        // Given
        let httpClient = try HTTPClientMock(code: 400, errorLabel: "")
        let sut = TeamsAPIV4(httpClient: httpClient)

        // Then
        await assertAPIError(TeamsAPIError.teamNotFound) {
            // When
            _ = try await sut.getTeamRoles(for: Team.ID())
        }
    }

    func testGetTeamMembers_FailureResponse_InvalidRequest_V4() async throws {
        // Given
        let httpClient = try HTTPClientMock(code: 400, errorLabel: "")
        let sut = TeamsAPIV4(httpClient: httpClient)

        // Then
        await assertAPIError(TeamsAPIError.invalidRequest) {
            // When
            _ = try await sut.getTeamMembers(
                for: Team.ID(),
                maxResults: 2000
            )
        }
    }

    func testGetLegalholdStatus_FailureResponse_InvalidRequest_V4() async throws {
        // Given
        let httpClient = try HTTPClientMock(code: 400, errorLabel: "")
        let sut = TeamsAPIV4(httpClient: httpClient)

        // Then
        await assertAPIError(TeamsAPIError.invalidRequest) {
            // When
            _ = try await sut.getLegalholdStatus(
                for: Team.ID(),
                userID: UUID()
            )
        }
    }

    // MARK: - V5

    func testGetTeamForID_FailureResponse_InvalidID_V5() async throws {
        // Given
        let httpClient = try HTTPClientMock(code: 404, errorLabel: "")
        let sut = TeamsAPIV5(httpClient: httpClient)

        // Then
        await assertAPIError(TeamsAPIError.invalidTeamID) {
            // When
            _ = try await sut.getTeam(for: Team.ID())
        }
    }

    func testGetLegalholdStatus_FailureResponse_InvalidRequest_V5() async throws {
        // Given
        let httpClient = try HTTPClientMock(code: 404, errorLabel: "")
        let sut = TeamsAPIV5(httpClient: httpClient)

        // Then
        await assertAPIError(TeamsAPIError.invalidRequest) {
            // When
            _ = try await sut.getLegalholdStatus(
                for: Team.ID(),
                userID: UUID()
            )
        }
    }

}
