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

final class TeamsAPITests: XCTestCase {

    // MARK: - V0

    func testGetTeamForID_Request_V0() async throws {
        // Given
        let teamID = Team.ID()
        let httpClient = HTTPClientMock()
        let sut = TeamsAPIV0(httpClient: httpClient)

        // When
        _ = try? await sut.getTeam(for: teamID)

        // Then
        XCTAssertEqual(
            httpClient.receivedRequest,
            HTTPRequest(
                path: "/teams/\(teamID.transportString())",
                method: .get
            )
        )
    }

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

    // MARK: - V1

    func testGetTeamForID_Request_V1() async throws {
        // Given
        let teamID = Team.ID()
        let httpClient = HTTPClientMock()
        let sut = TeamsAPIV1(httpClient: httpClient)

        // When
        _ = try? await sut.getTeam(for: teamID)

        // Then
        XCTAssertEqual(
            httpClient.receivedRequest,
            HTTPRequest(
                path: "/v1/teams/\(teamID.transportString())",
                method: .get
            )
        )
    }

    // MARK: - V2

    func testGetTeamForID_Request_V2() async throws {
        // Given
        let teamID = Team.ID()
        let httpClient = HTTPClientMock()
        let sut = TeamsAPIV2(httpClient: httpClient)

        // When
        _ = try? await sut.getTeam(for: teamID)

        // Then
        XCTAssertEqual(
            httpClient.receivedRequest,
            HTTPRequest(
                path: "/v2/teams/\(teamID.transportString())",
                method: .get
            )
        )
    }

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

    // MARK: - V3

    func testGetTeamForID_Request_V3() async throws {
        // Given
        let teamID = Team.ID()
        let httpClient = HTTPClientMock()
        let sut = TeamsAPIV3(httpClient: httpClient)

        // When
        _ = try? await sut.getTeam(for: teamID)

        // Then
        XCTAssertEqual(
            httpClient.receivedRequest,
            HTTPRequest(
                path: "/v3/teams/\(teamID.transportString())",
                method: .get
            )
        )
    }

    // MARK: - V4

    func testGetTeamForID_Request_V4() async throws {
        // Given
        let teamID = Team.ID()
        let httpClient = HTTPClientMock()
        let sut = TeamsAPIV4(httpClient: httpClient)

        // When
        _ = try? await sut.getTeam(for: teamID)

        // Then
        XCTAssertEqual(
            httpClient.receivedRequest,
            HTTPRequest(
                path: "/v4/teams/\(teamID.transportString())",
                method: .get
            )
        )
    }

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

    // MARK: - V5

    func testGetTeamForID_Request_V5() async throws {
        // Given
        let teamID = Team.ID()
        let httpClient = HTTPClientMock()
        let sut = TeamsAPIV5(httpClient: httpClient)

        // When
        _ = try? await sut.getTeam(for: teamID)

        // Then
        XCTAssertEqual(
            httpClient.receivedRequest,
            HTTPRequest(
                path: "/v5/teams/\(teamID.transportString())",
                method: .get
            )
        )
    }

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

    // MARK: - V6

    func testGetTeamForID_Request_V6() async throws {
        // Given
        let teamID = Team.ID()
        let httpClient = HTTPClientMock()
        let sut = TeamsAPIV6(httpClient: httpClient)

        // When
        _ = try? await sut.getTeam(for: teamID)

        // Then
        XCTAssertEqual(
            httpClient.receivedRequest,
            HTTPRequest(
                path: "/v6/teams/\(teamID.transportString())",
                method: .get
            )
        )
    }

}
