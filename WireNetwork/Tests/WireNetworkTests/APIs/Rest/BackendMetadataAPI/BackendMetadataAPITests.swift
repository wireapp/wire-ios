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

import WireFoundationSupport
import XCTest

@testable import WireNetwork
@testable import WireNetworkSupport

final class BackendMetadataAPITests: XCTestCase {

    private var mockDateProvider: CurrentDateProvidingMock!

    override func setUp() async throws {
        mockDateProvider = CurrentDateProvidingMock()
        mockDateProvider.now = try Date.ISO8601FormatStyle().parse("2025-04-09T12:34:56Z")
    }

    override func tearDown() {
        mockDateProvider = nil
    }

    // MARK: - Get backend info

    func testGetBackendMetadataRequest() async throws {
        // Then
        try await RequestSnapshotter(currentDateProvider: mockDateProvider).verifyRequest { _, networkService in
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
