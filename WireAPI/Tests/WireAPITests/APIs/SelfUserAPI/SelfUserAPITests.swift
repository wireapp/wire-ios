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

final class SelfUserAPITests: XCTestCase {

    private var apiSnapshotHelper: APISnapshotHelper<any SelfUserAPI>!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        apiSnapshotHelper = APISnapshotHelper { httpClient, apiVersion in
            let builder = SelfUserAPIBuilder(httpClient: httpClient)
            return builder.makeAPI(for: apiVersion)
        }
    }

    override func tearDown() {
        apiSnapshotHelper = nil
        super.tearDown()
    }

    // MARK: - Request generation

    func testGetSelfUserRequest() async throws {
        try await apiSnapshotHelper.verifyRequestForAllAPIVersions { sut in
            _ = try await sut.getSelfUser()
        }
    }

    func testPushSupportedProtocolsRequest() async throws {
        let supportedVersions = APIVersion.v5.andNextVersions
        try await apiSnapshotHelper.verifyRequest(for: supportedVersions) { sut in
            _ = try await sut.pushSupportedProtocols([.mls])
        }
    }

    // MARK: - Request unsupported endpoints

    func testPushSupportedProtocols_UnsupportedVersionError_V0_to_V4() async throws {
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
                    await self.XCTAssertThrowsError(SelfUserAPIError.unsupportedEndpointForAPIVersion) {
                        // When
                        try await sut.pushSupportedProtocols([.mls])
                    }
                }

                try await taskGroup.waitForAll()
            }
        }
    }

    // MARK: - Request supported endpoints

    func testPushSupportedProtocols_V5_And_NextVersions() async throws {
        // Given
        let httpClient = HTTPClientMock(
            code: .ok,
            payload: nil
        )

        let supportedVersions = APIVersion.v5.andNextVersions

        let suts = supportedVersions.map { $0.buildAPI(client: httpClient) }

        try await withThrowingTaskGroup(of: Void.self) { taskGroup in
            for sut in suts {
                taskGroup.addTask {
                    // When
                    try await sut.pushSupportedProtocols([.mls])
                }

                try await taskGroup.waitForAll()
            }
        }
    }

    // MARK: - Response handling

    // MARK: - V0

    func testGetSelfUser_SuccessResponse_200_V0() async throws {
        // Given
        let httpClient = try HTTPClientMock(
            code: .ok,
            payloadResourceName: "GetSelfUserSuccessResponseV0"
        )

        let sut = SelfUserAPIV0(httpClient: httpClient)

        // When
        let result = try await sut.getSelfUser()

        // Then
        XCTAssertEqual(
            result,
            Scaffolding.selfUserV0
        )
    }

    func testGetSelfUser_FailureResponse() async throws {
        // Given
        let httpClient = try HTTPClientMock(code: .notFound, errorLabel: "not-found")
        let sut = SelfUserAPIV0(httpClient: httpClient)

        // Then
        await XCTAssertThrowsError {
            // When
            try await sut.getSelfUser()
        }
    }

    // MARK: - V4

    func testGetSelfUser_SuccessResponse_200_V4() async throws {
        // Given
        let httpClient = try HTTPClientMock(
            code: .ok,
            payloadResourceName: "GetSelfUserSuccessResponseV4"
        )

        let sut = SelfUserAPIV4(httpClient: httpClient)

        // When
        let result = try await sut.getSelfUser()

        // Then
        XCTAssertEqual(
            result,
            Scaffolding.selfUserV5
        )
    }

    // MARK: - V5

    func testPushSupportedProtocols_SuccessResponse_200_V5() async throws {
        // Given
        let httpClient = HTTPClientMock(code: .ok, payload: nil)

        // When
        let sut = SelfUserAPIV5(httpClient: httpClient)

        // Then
        try await sut.pushSupportedProtocols([.mls])
    }

    func testPushSupportedProtocols_FailureResponse_InvalidRequest_V5() async throws {
        // Given
        let httpClient = try HTTPClientMock(code: .notFound, errorLabel: "")
        let sut = SelfUserAPIV5(httpClient: httpClient)

        // Then
        await XCTAssertThrowsError {
            // When
            try await sut.pushSupportedProtocols([.mls])
        }
    }
}

extension SelfUserAPITests {
    enum Scaffolding {
        static let teamID = UUID(uuidString: "99DB9768-04E3-4B5D-9268-831B6A25C4AB")!
        static let userID = UserID(
            uuid: UUID(uuidString: "99DB9768-04E3-4B5D-9268-831B6A25C4AB")!,
            domain: "example.com"
        )
        static let selfUserV0 = SelfUser(
            id: UUID(uuidString: "99DB9768-04E3-4B5D-9268-831B6A25C4AB")!,
            qualifiedID: userID,
            ssoID: SSOID(scimExternalId: "string", subject: "string", tenant: "string"),
            name: "string",
            handle: "string",
            teamID: teamID,
            phone: "string",
            accentID: 2_147_483_647,
            managedBy: .wire,
            assets: [UserAsset(
                key: "3-1-47de4580-ae51-4650-acbb-d10c028cb0ac",
                size: .preview,
                type: .image
            )],
            deleted: true,
            email: "string",
            expiresAt: ISO8601DateFormatter.fractionalInternetDateTime.date(from: "2021-05-12T10:52:02.671Z")!,
            service: Service(
                id: UUID(uuidString: "99DB9768-04E3-4B5D-9268-831B6A25C4AB")!,
                provider: UUID(uuidString: "99DB9768-04E3-4B5D-9268-831B6A25C4AB")!
            ),
            supportedProtocols: [.proteus]
        )

        static let selfUserV5 = SelfUser(
            id: UUID(uuidString: "99DB9768-04E3-4B5D-9268-831B6A25C4AB")!,
            qualifiedID: userID,
            ssoID: SSOID(scimExternalId: "string", subject: "string", tenant: "string"),
            name: "string",
            handle: "string",
            teamID: teamID,
            phone: "string",
            accentID: 2_147_483_647,
            managedBy: .wire,
            assets: [UserAsset(
                key: "3-1-47de4580-ae51-4650-acbb-d10c028cb0ac",
                size: .preview,
                type: .image
            )],
            deleted: true,
            email: "string",
            expiresAt: ISO8601DateFormatter.fractionalInternetDateTime.date(from: "2021-05-12T10:52:02.671Z")!,
            service: Service(
                id: UUID(uuidString: "99DB9768-04E3-4B5D-9268-831B6A25C4AB")!,
                provider: UUID(uuidString: "99DB9768-04E3-4B5D-9268-831B6A25C4AB")!
            ),
            supportedProtocols: [.mls]
        )
    }
}

private extension APIVersion {
    func buildAPI(client: any HTTPClient) -> any SelfUserAPI {
        let builder = SelfUserAPIBuilder(httpClient: client)
        return builder.makeAPI(for: self)
    }
}
