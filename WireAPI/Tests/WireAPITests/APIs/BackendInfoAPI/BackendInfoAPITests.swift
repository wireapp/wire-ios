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
@testable import WireAPISupport

final class BackendInfoAPITests: XCTestCase {

    private var apiSnapshotHelper: APIServiceSnapshotHelper<any BackendInfoAPI>!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        apiSnapshotHelper = APIServiceSnapshotHelper { apiService, apiVersion in
            let builder = BackendInfoAPIBuilder(apiService: apiService)
            return builder.makeAPI(for: apiVersion)
        }
    }

    override func tearDown() {
        apiSnapshotHelper = nil
        super.tearDown()
    }

    // MARK: - Request generation

    func testGetBackendInfoRequest() async throws {
        try await apiSnapshotHelper.verifyRequest(for: [.v0]) { sut in
            _ = try? await sut.getBackendInfo()
        }
    }

    func testGetBackendMLSPublicKeysRequest() async throws {
        let apiVersions = Set(APIVersion.allCases).subtracting([.v0, .v1, .v2, .v3, .v4])
        try await apiSnapshotHelper.verifyRequest(for: apiVersions) { sut in
            _ = try await sut.getBackendMLSPublicKeys()
        }
    }

    // MARK: - Response handling

    // MARK: - V0

    func testGetBackendInfo_SuccessResponse_200_V0_WithoutDevelopmentVersions() async throws {
        try await withThrowingTaskGroup(of: BackendInfo.self) { _ in
            // Given
            let apiService = MockAPIServiceProtocol.withResponses([
                (.ok, "GetBackendInfoSuccessResponse1")
            ])
            let sut = BackendInfoAPIV0(apiService: apiService)

            // When
            let result = try await sut.getBackendInfo()

            // Then
            XCTAssertEqual(
                result,
                BackendInfo(
                    domain: "example.com",
                    isFederationEnabled: true,
                    isMLSEnabled: false,
                    supportedVersions: [.v0, .v1, .v2],
                    developmentVersions: []
                )
            )
        }
    }

    func testGetBackendInfo_SuccessResponse_200_V0_WithDevelopmentVersions() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "GetBackendInfoSuccessResponse2")
        ])
        let sut = BackendInfoAPIV0(apiService: apiService)

        // When
        let result = try await sut.getBackendInfo()

        // Then
        XCTAssertEqual(
            result,
            BackendInfo(
                domain: "example.com",
                isFederationEnabled: true,
                isMLSEnabled: false,
                supportedVersions: [.v0, .v1, .v2],
                developmentVersions: [.v3]
            )
        )
    }

    // MARK: - V5

    func testGetBackendMLSPublicKeys_SuccessResponse_200_V5_And_Next_Versions() async throws {
        try await withThrowingTaskGroup(of: BackendMLSPublicKeys.self) { taskGroup in
            let testedVersions = [APIVersion.v5, .v6, .v7]

            for version in testedVersions {
                // Given
                let apiService = MockAPIServiceProtocol.withResponses([
                    (.ok, "GetBackendMLSPublicKeysSuccessResponse1")
                ])
                let sut = version.buildAPI(apiService: apiService)

                taskGroup.addTask {
                    // When
                    try await sut.getBackendMLSPublicKeys()
                }

                for try await value in taskGroup {
                    // Then
                    XCTAssertEqual(
                        value,
                        BackendMLSPublicKeys(
                            removal: .init(
                                ed25519: "YVAl3Nsu27aNpNbYlPB6fi",
                                ed448: nil,
                                p256: "BM036midcNiOMgny9m7N",
                                p384: "BPSlomkR8K4BcFLGTDOJx",
                                p512: "BAC3OmJi7rAPFAIXjU"
                            )
                        )
                    )
                }
            }
        }
    }

    func testGetBackendMLSPublicKeys_givenV5AndErrorResponse() async throws {
        // given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .badRequest,
            label: "mls-not-enabled"
        )

        let api = BackendInfoAPIV5(apiService: apiService)

        // Then
        await XCTAssertThrowsErrorAsync(BackendInfoAPIError.mlsNotEnabled) {
            // When
            try await api.getBackendMLSPublicKeys()
        }
    }
}

private extension APIVersion {
    func buildAPI(apiService: any APIServiceProtocol) -> any BackendInfoAPI {
        let builder = BackendInfoAPIBuilder(apiService: apiService)
        return builder.makeAPI(for: self)
    }
}
