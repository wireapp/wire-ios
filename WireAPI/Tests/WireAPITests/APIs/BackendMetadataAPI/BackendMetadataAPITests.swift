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

final class BackendMetadataAPITests: XCTestCase {

    // MARK: - Get backend info

    func testGetBackendMetadataRequest() async throws {
        // Then
        try await RequestSnapshotter().verifyRequest { _, networkService in
            let sut = BackendMetadataAPIBuilder(networkService: networkService).makeAPI()
            // When
            _ = try? await sut.getBackendMetadata()
        }
    }

    func testGetBackendMetadata_SuccessResponse_200_V0_WithoutDevelopmentVersions() async throws {
        // Given
        let networkService = MockNetworkServiceProtocol.withResponses([
            (.ok, "GetBackendMetadataSuccessResponse1")
        ])
        let sut = BackendMetadataAPIUnversioned(networkService: networkService)

        // When
        let result = try await sut.getBackendMetadata()

        // Then
        XCTAssertEqual(
            result,
            BackendMetadata(
                domain: "example.com",
                isFederationEnabled: true,
                supportedVersions: [.v0, .v1, .v2],
                developmentVersions: []
            )
        )
    }

    func testGetBackendMetadata_SuccessResponse_200_V0_WithDevelopmentVersions() async throws {
        // Given
        let networkService = MockNetworkServiceProtocol.withResponses([
            (.ok, "GetBackendMetadataSuccessResponse2")
        ])
        let sut = BackendMetadataAPIUnversioned(networkService: networkService)

        // When
        let result = try await sut.getBackendMetadata()

        // Then
        XCTAssertEqual(
            result,
            BackendMetadata(
                domain: "example.com",
                isFederationEnabled: true,
                supportedVersions: [.v0, .v1, .v2],
                developmentVersions: [.v3]
            )
        )
    }

}
