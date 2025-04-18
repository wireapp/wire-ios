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

import XCTest

@testable import WireAPI
@testable import WireAPISupport

final class MLSAPITests: XCTestCase {

    private var apiSnapshotHelper: APIServiceSnapshotHelper<any MLSAPI>!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        apiSnapshotHelper = APIServiceSnapshotHelper { apiService, apiVersion in
            let builder = MLSAPIBuilder(apiService: apiService)
            return builder.makeAPI(for: apiVersion)
        }
    }

    override func tearDown() {
        apiSnapshotHelper = nil
        super.tearDown()
    }

    // MARK: - Get backend MLS public keys

    func testGetBackendMLSPublicKeysRequest() async throws {
        // Given
        let apiVersions = APIVersion.v5.andNextVersions

        // Then
        try await apiSnapshotHelper.verifyRequest(for: apiVersions) { sut in
            // When
            _ = try await sut.getBackendMLSPublicKeys()
        }
    }

    func testGetBackendMLSPublicKeys_SuccessResponse_200_V5_And_Next_Versions() async throws {
        // Given
        try await withThrowingTaskGroup(of: BackendMLSPublicKeys.self) { taskGroup in
            let testedVersions = APIVersion.v5.andNextVersions

            for version in testedVersions {
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
        // Given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .badRequest,
            label: "mls-not-enabled"
        )

        let api = MLSAPIV5(apiService: apiService)

        // Then
        await XCTAssertThrowsErrorAsync(MLSAPIError.mlsNotEnabled) {
            // When
            try await api.getBackendMLSPublicKeys()
        }
    }
}

private extension APIVersion {

    func buildAPI(apiService: any APIServiceProtocol) -> any MLSAPI {
        let builder = MLSAPIBuilder(apiService: apiService)
        return builder.makeAPI(for: self)
    }

}
