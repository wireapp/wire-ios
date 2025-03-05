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

    private var apiSnapshotHelper: APIServiceSnapshotHelper<any BackendInfoAPI>!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        apiSnapshotHelper = APIServiceSnapshotHelper { apiService, _ in
            let builder = BackendInfoAPIBuilder(apiService: apiService)
            return builder.makeAPI()
        }
    }

    override func tearDown() {
        apiSnapshotHelper = nil
        super.tearDown()
    }

    // MARK: - Get backend info

    func testGetBackendInfoRequest() async throws {
        // Then
        try await apiSnapshotHelper.verifyRequestForAllAPIVersions { sut in
            // When
            _ = try? await sut.getBackendInfo()
        }
    }

    func testGetBackendInfo_SuccessResponse_200_V0_WithoutDevelopmentVersions() async throws {
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

}
