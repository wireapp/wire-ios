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

@testable import WireAPI
import XCTest

final class BackendInfoAPITests: XCTestCase {
    private var httpClient: HTTPClient!

    // MARK: - V0

    func testGetBackendInfoRequestV0() async throws {
        // Given
        let httpClient = HTTPClientMock()
        let sut = BackendInfoAPIV0(httpClient: httpClient)

        // When
        _ = try? await sut.getBackendInfo()

        // Then
        XCTAssertEqual(
            httpClient.receivedRequest,
            HTTPRequest(
                path: "/api-version",
                method: .get
            )
        )
    }

    func testGetBackendInfoResponseV0() async throws {
        // Given
        let httpClient = try HTTPClientMock(
            code: 200,
            jsonResponse: """
            {
                "domain": "example.com",
                "federation": true,
                "supported": [0, 1, 2]
            }
            """
        )

        let sut = BackendInfoAPIV0(httpClient: httpClient)

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

    // MARK: - V2

    func testGetBackendInfoResponseV2() async throws {
        // Given
        let httpClient = try HTTPClientMock(
            code: 200,
            jsonResponse: """
            {
                "domain": "example.com",
                "federation": true,
                "supported": [0, 1, 2],
                "development": [3]
            }
            """
        )

        let sut = BackendInfoAPIV2(httpClient: httpClient)

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
