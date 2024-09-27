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

import SnapshotTesting
import XCTest
@testable import WireAPI
@testable import WireAPISupport

final class BackendInfoAPITests: XCTestCase {
    // MARK: Internal

    // MARK: - Request generation

    func testGetBackendInfoRequest() async throws {
        // Given
        let apiService = MockAPIServiceProtocol()
        apiService.executeRequestRequiringAccessToken_MockMethod = { _, _ in
            throw "no response needed"
        }

        let sut = BackendInfoAPIImpl(apiService: apiService)

        // When
        _ = try? await sut.getBackendInfo()

        // Then
        let invocations = apiService.executeRequestRequiringAccessToken_Invocations
        try XCTAssertCount(invocations, count: 1)

        let request = invocations[0].request
        await snapshotter.verifyRequest(request: request)
    }

    // MARK: - Response handling

    func testGetBackendInfoResponseWithoutDevelopmentVersions() async throws {
        // Given
        let apiService = MockAPIServiceProtocol()
        apiService.executeRequestRequiringAccessToken_MockMethod = { request, _ in
            try request.mockResponse(
                statusCode: .ok,
                jsonResourceName: "GetBackendInfoSuccessResponse1"
            )
        }

        let sut = BackendInfoAPIImpl(apiService: apiService)

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

    func testGetBackendInfoResponseWithDevelopmentVersions() async throws {
        // Given
        let apiService = MockAPIServiceProtocol()
        apiService.executeRequestRequiringAccessToken_MockMethod = { request, _ in
            try request.mockResponse(
                statusCode: .ok,
                jsonResourceName: "GetBackendInfoSuccessResponse2"
            )
        }

        let sut = BackendInfoAPIImpl(apiService: apiService)

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

    // MARK: Private

    private let snapshotter = HTTPRequestSnapshotHelper()
}
