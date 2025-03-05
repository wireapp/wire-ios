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

final class BackendInfoAPITests: XCTestCase {

    // MARK: - Get backend info

    func testGetBackendInfoRequest() async throws {
        // Then
        try await RequestSnapshotter().verifyRequest { _, networkService in
            let sut = BackendInfoAPIBuilder(networkService: networkService).makeAPI()
            // When
            _ = try? await sut.getBackendInfo()
        }
    }

    func testGetBackendInfo_SuccessResponse_200_V0_WithoutDevelopmentVersions() async throws {
        // Given
        let networkService = MockNetworkServiceProtocol.withResponses([
            (.ok, "GetBackendInfoSuccessResponse1")
        ])
        let sut = BackendInfoAPIUnversioned(networkService: networkService)

        // When
        let result = try await sut.getBackendInfo()

        // Then
        XCTAssertEqual(
            result,
            BackendInfo(
                domain: "example.com",
                isFederationEnabled: true,
                supportedVersions: [.v0, .v1, .v2],
                developmentVersions: []
            )
        )
    }

    func testGetBackendInfo_SuccessResponse_200_V0_WithDevelopmentVersions() async throws {
        // Given
        let networkService = MockNetworkServiceProtocol.withResponses([
            (.ok, "GetBackendInfoSuccessResponse2")
        ])
        let sut = BackendInfoAPIUnversioned(networkService: networkService)

        // When
        let result = try await sut.getBackendInfo()

        // Then
        XCTAssertEqual(
            result,
            BackendInfo(
                domain: "example.com",
                isFederationEnabled: true,
                supportedVersions: [.v0, .v1, .v2],
                developmentVersions: [.v3]
            )
        )
    }

}
