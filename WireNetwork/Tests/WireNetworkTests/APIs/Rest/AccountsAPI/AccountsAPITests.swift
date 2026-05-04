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

final class AccountsAPITests: XCTestCase {

    private var apiSnapshotHelper: APIServiceSnapshotHelper<any AccountsAPI>!

    // MARK: - Setup

    override func setUp() {
        apiSnapshotHelper = APIServiceSnapshotHelper<any AccountsAPI> { apiService, apiVersion in
            AccountsAPIBuilder(apiService: apiService)
                .makeAPI(for: apiVersion)

        }
    }

    override func tearDown() {
        apiSnapshotHelper = nil
    }

    // MARK: - Request generation

    func testUpgradeToTeam_V0_To_V6() async throws {
        // Given
        let apiService = MockAPIServiceProtocol()
        let builder = AccountsAPIBuilder(apiService: apiService)

        for apiVersion in [APIVersion.v0, .v1, .v2, .v3, .v4, .v5, .v6] {
            let sut = builder.makeAPI(for: apiVersion)

            // Then
            await XCTAssertThrowsErrorAsync(AccountsAPIError.unsupportedEndpointForAPIVersion) {
                try await sut.upgradeToTeam(teamName: Scaffolding.teamName)
            }
        }
    }

    func testUpgradeToTeam_Request_Generation_V7_Onwards() async throws {
        // Given
        let apiVersions =
            APIVersion.v7.andNextVersions
        let apiService = MockAPIServiceProtocol.withResponses(
            Array(repeating: (.ok, "UpgradeToTeamSuccessResponse"), count: apiVersions.count)
        )

        // Then
        try await apiSnapshotHelper.verifyRequest(for: apiVersions, apiService: apiService) { sut in
            // When
            _ = try await sut.upgradeToTeam(teamName: Scaffolding.teamName)
        }
    }

    // MARK: - Response handling

    func testUpgradeToTeam_Response_Handling_V7_Success() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "UpgradeToTeamSuccessResponse")
        ])

        let sut = AccountsAPIV7(apiService: apiService)

        // When
        let response = try await sut.upgradeToTeam(teamName: Scaffolding.teamName)

        // Then
        XCTAssertEqual(response, UpgradedAccountTeam(teamId: Scaffolding.teamID, teamName: Scaffolding.teamName))
    }

    func testUpgradeToTeam_Response_Handling_V7_User_Already_In_A_Team() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses([
            (.forbidden, "UpgradeToTeamErrorResponse_UserAlreadyInATeam")
        ])

        let sut = AccountsAPIV7(apiService: apiService)

        // Then
        await XCTAssertThrowsErrorAsync(AccountsAPIError.userAlreadyInATeam) {
            // When
            try await sut.upgradeToTeam(teamName: Scaffolding.teamName)
        }
    }

    func testUpgradeToTeam_Response_Handling_V7_User_Not_Found() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses([
            (.notFound, "UpgradeToTeamErrorResponse_UserNotFound")
        ])

        let sut = AccountsAPIV7(apiService: apiService)

        // Then
        await XCTAssertThrowsErrorAsync(AccountsAPIError.userNotFound) {
            // When
            try await sut.upgradeToTeam(teamName: Scaffolding.teamName)
        }
    }

}

private enum Scaffolding {

    static let teamName = "iOS Team"
    static let teamID = UUID(uuidString: "66dc3593-4c3a-49e8-b5c3-d3d908bd7403")!

}
