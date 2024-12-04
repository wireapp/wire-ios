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
@testable import WireAPISupport
@testable import WireAPI

final class UsersAPITests: XCTestCase {

    private var apiSnapshotHelper: APIServiceSnapshotHelper<any UsersAPI>!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        apiSnapshotHelper = APIServiceSnapshotHelper { apiService, apiVersion in
            let builder = UsersAPIBuilder(apiService: apiService)
            return builder.makeAPI(for: apiVersion)
        }
    }

    override func tearDown() {
        apiSnapshotHelper = nil
        super.tearDown()
    }

    // MARK: - Request generation

    func testGetUserRequest() async throws {
        try await apiSnapshotHelper.verifyRequestForAllAPIVersions { sut in
            _ = try await sut.getUser(for: .mockID1)
        }
    }

    func testGetUsersRequest() async throws {
        try await apiSnapshotHelper.verifyRequestForAllAPIVersions { sut in
            _ = try await sut.getUsers(userIDs: [.mockID1, .mockID2, .mockID3])
        }
    }

    // MARK: - Response handling

    // MARK: - V0

    func testGetUserForID_SuccessResponse_200_V0_Then_Verify_Request() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "GetUserSuccessResponseV0")
        ])

        try await apiSnapshotHelper.verifyRequest(for: [.v0], apiService: apiService) { sut in
            // When
            let result = try await sut.getUser(for: Scaffolding.userID)

            // Then
            XCTAssertEqual(
                result,
                Scaffolding.user
            )
        }
    }

    func testGetUsersForIDs_SuccessResponse_200_V0_Then_Verify_Request() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "GetUsersSuccessResponseV0")
        ])

        try await apiSnapshotHelper.verifyRequest(for: [.v0], apiService: apiService) { sut in
            // When
            let result = try await sut.getUsers(userIDs: [Scaffolding.userID])

            // Then
            XCTAssertEqual(
                result,
                UserList(found: [Scaffolding.user], failed: [])
            )
        }
    }

    func testGetUsersForIDs_FailureResponse_NotFound_V0() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .notFound,
            label: "not-found"
        )

        let sut = UsersAPIV0(apiService: apiService)

        // Then
        await XCTAssertThrowsErrorAsync(UsersAPIError.userNotFound) {
            // When
            try await sut.getUser(for: Scaffolding.userID)
        }
    }

    // MARK: - V4

    func testGetUserForID_SuccessResponse_200_V4_Then_Verify_Request() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "GetUserSuccessResponseV4")
        ])

        try await apiSnapshotHelper.verifyRequest(for: [.v4], apiService: apiService) { sut in
            // When
            let result = try await sut.getUser(
                for: Scaffolding.userID
            )

            // Then
            XCTAssertEqual(
                result,
                Scaffolding.user
            )
        }
    }

    func testGetUsersForIDs_FailureResponse_NotFound_V4() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .notFound,
            label: "not-found"
        )

        let sut = UsersAPIV4(apiService: apiService)

        // Then
        await XCTAssertThrowsErrorAsync(UsersAPIError.userNotFound) {
            // When
            try await sut.getUser(for: Scaffolding.userID)
        }
    }

    func testGetUsersForIDs_SuccessResponse_200_V4_Then_Verify_Request() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "GetUsersSuccessResponseV4")
        ])

        try await apiSnapshotHelper.verifyRequest(for: [.v4], apiService: apiService) { sut in
            // When
            let result = try await sut.getUsers(userIDs: [Scaffolding.userID])

            // Then
            XCTAssertEqual(
                result,
                UserList(found: [Scaffolding.user], failed: [Scaffolding.userID])
            )
        }
    }

    enum Scaffolding {
        static let teamID = UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!
        static let userID = UserID(
            uuid: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!,
            domain: "example.com"
        )
        static let user = User(
            id: userID,
            name: "name",
            handle: "handle",
            teamID: teamID,
            accentID: 1,
            assets: [UserAsset(
                key: "3-1-47de4580-ae51-4650-acbb-d10c028cb0ac",
                size: .preview,
                type: .image
            )],
            deleted: true,
            email: "john.doe@example.com",
            expiresAt: ISO8601DateFormatter.fractionalInternetDateTime.date(from: "2021-05-12T10:52:02.671Z")!,
            service: Service(
                id: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!,
                provider: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!
            ),
            supportedProtocols: [.proteus],
            legalholdStatus: .enabled
        )
    }

}
