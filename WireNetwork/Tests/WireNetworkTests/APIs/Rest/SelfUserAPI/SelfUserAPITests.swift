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

final class SelfUserAPITests: XCTestCase {

    private var apiSnapshotHelper: APIServiceSnapshotHelper<any SelfUserAPI>!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        apiSnapshotHelper = APIServiceSnapshotHelper { apiService, apiVersion in
            let builder = SelfUserAPIBuilder(apiService: apiService)
            return builder.makeAPI(for: apiVersion)
        }
    }

    override func tearDown() {
        apiSnapshotHelper = nil
        super.tearDown()
    }

    // MARK: - Request generation

    func testGetSelfUserRequest() async throws {
        let responses: [MockAPIServiceProtocol.Response] = Array(
            repeating: (.ok, "GetSelfUserSuccessResponseV0"),
            count: APIVersion.allCases.count
        )

        let apiService = MockAPIServiceProtocol.withResponses(responses)

        try await apiSnapshotHelper.verifyRequestForAllAPIVersions(apiService: apiService) { sut in
            _ = try await sut.getSelfUser()
        }
    }

    func testPushSupportedProtocolsRequest() async throws {
        let supportedVersions = APIVersion.v5.andNextVersions

        let responses: [MockAPIServiceProtocol.Response] = Array(
            repeating: (.ok, nil),
            count: supportedVersions.count
        )

        let apiService = MockAPIServiceProtocol.withResponses(responses)

        try await apiSnapshotHelper.verifyRequest(for: supportedVersions, apiService: apiService) { sut in
            _ = try await sut.pushSupportedProtocols([.mls])
        }
    }

    // MARK: - Request unsupported endpoints

    func testPushSupportedProtocols_UnsupportedVersionError_V0_to_V4() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses([])

        let unsupportedVersions: [APIVersion] = [.v0, .v1, .v2, .v3, .v4]
        let suts = unsupportedVersions.map {
            $0.buildAPI(apiService: apiService)
        }

        for sut in suts {
            // Then
            await XCTAssertThrowsErrorAsync(SelfUserAPIError.unsupportedEndpointForAPIVersion) {
                // When
                try await sut.pushSupportedProtocols([.mls])
            }
        }
    }

    // MARK: - Response handling

    // MARK: - V0

    func testGetSelfUser_SuccessResponse_200_V0_Then_VerifyRequests() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "GetSelfUserSuccessResponseV0")
        ])

        // Then
        try await apiSnapshotHelper.verifyRequest(for: [.v0], apiService: apiService) { sut in
            // When
            let result = try await sut.getSelfUser()

            // Then
            XCTAssertEqual(
                result,
                Scaffolding.selfUserV0
            )
        }
    }

    func testGetSelfUserNoSCIM_SuccessResponse_200_V0_Then_VerifyRequests() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "GetSelfUserSuccessResponseV0NoSCIM")
        ])

        // Then
        try await apiSnapshotHelper.verifyRequest(for: [.v0], apiService: apiService) { sut in
            // When
            let result = try await sut.getSelfUser()

            // Then
            XCTAssertEqual(
                result,
                Scaffolding.selfUserV0NoSCIM
            )
        }
    }

    func testGetSelfUser_FailureResponse() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .notFound,
            label: "not-found"
        )

        let sut = SelfUserAPIV0(apiService: apiService)

        // Then
        await XCTAssertThrowsErrorAsync {
            // When
            try await sut.getSelfUser()
        }
    }

    // MARK: - V4

    func testGetSelfUser_SuccessResponse_200_V4_Then_VerifyRequests() async throws {
        // Given

        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "GetSelfUserSuccessResponseV4")
        ])

        // Then
        try await apiSnapshotHelper.verifyRequest(for: [.v4], apiService: apiService) { sut in
            // When
            let result = try await sut.getSelfUser()

            // Then
            XCTAssertEqual(
                result,
                Scaffolding.selfUserV5
            )
        }
    }

    func testGetSelfUserNoSCIM_SuccessResponse_200_V4_Then_VerifyRequests() async throws {
        // Given

        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "GetSelfUserSuccessResponseV4NoSCIM")
        ])

        // Then
        try await apiSnapshotHelper.verifyRequest(for: [.v4], apiService: apiService) { sut in
            // When
            let result = try await sut.getSelfUser()

            // Then
            XCTAssertEqual(
                result,
                Scaffolding.selfUserV5NoSCIM
            )
        }
    }

    // MARK: - V5

    func testPushSupportedProtocols_SuccessResponse_200_V5_And_Next_Versions_Verify_Requests() async throws {

        let supportedVersions = APIVersion.v5.andNextVersions

        // Given
        let responses: [MockAPIServiceProtocol.Response] = Array(
            repeating: (.ok, nil),
            count: supportedVersions.count
        )

        let apiService = MockAPIServiceProtocol.withResponses(responses)

        // Then
        try await apiSnapshotHelper.verifyRequest(for: supportedVersions, apiService: apiService) { sut in
            // When
            try await sut.pushSupportedProtocols([.mls])
        }
    }

    func testPushSupportedProtocols_FailureResponse_InvalidRequest_V5() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .notFound,
            label: ""
        )
        let sut = SelfUserAPIV5(apiService: apiService)

        // Then
        await XCTAssertThrowsErrorAsync {
            // When
            try await sut.pushSupportedProtocols([.mls])
        }
    }

    func testPushSupportedProtocols_MLSProtocolErrorFailureResponse_V8() async throws {
        // Given
        let errorMessage = "MLS protocol cannot be removed"
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .conflict,
            label: "mls-protocol-error",
            message: errorMessage
        )
        let sut = SelfUserAPIV8(apiService: apiService)

        // Then
        await XCTAssertThrowsErrorAsync(SelfUserAPIError.mlsProtocolError(errorMessage), when: {
            // When
            try await sut.pushSupportedProtocols([.mls])
        })
    }
}

extension SelfUserAPITests {
    enum Scaffolding {
        static let teamID = UUID(uuidString: "99DB9768-04E3-4B5D-9268-831B6A25C4AB")!
        static let userID = UserID(
            id: UUID(uuidString: "99DB9768-04E3-4B5D-9268-831B6A25C4AB")!,
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
        static let selfUserV0NoSCIM = SelfUser(
            id: UUID(uuidString: "99DB9768-04E3-4B5D-9268-831B6A25C4AB")!,
            qualifiedID: userID,
            ssoID: SSOID(scimExternalId: nil, subject: "string", tenant: "string"),
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

        static let selfUserV5NoSCIM = SelfUser(
            id: UUID(uuidString: "99DB9768-04E3-4B5D-9268-831B6A25C4AB")!,
            qualifiedID: userID,
            ssoID: SSOID(scimExternalId: nil, subject: "string", tenant: "string"),
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
    func buildAPI(apiService: any APIServiceProtocol) -> any SelfUserAPI {
        let builder = SelfUserAPIBuilder(apiService: apiService)
        return builder.makeAPI(for: self)
    }
}

extension SelfUserAPIError: Equatable {
    public static func == (lhs: SelfUserAPIError, rhs: SelfUserAPIError) -> Bool {
        switch (lhs, rhs) {
        case (.selfUserNotFound, .selfUserNotFound):
            true
        case let (.mlsProtocolError(lhsMsg), .mlsProtocolError(rhsMsg)):
            lhsMsg == rhsMsg
        case (.unsupportedEndpointForAPIVersion, .unsupportedEndpointForAPIVersion):
            true
        default:
            false
        }

    }
}
