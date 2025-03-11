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

import WireAPI
import WireAPISupport
import WireAuthenticationAPI
import XCTest

@testable import WireAuthenticationLogic

final class ResolveBackendMetadataUseCaseTests: XCTestCase {

    private var api: MockBackendMetadataAPI!

    override func setUp() {
        api = MockBackendMetadataAPI()
    }

    override func tearDown() {
        api = nil
    }

    // MARK: - Resolve for preferred version

    func testInvoke_ResolvesToPreferredVersion() async throws {
        // Given
        let sut = ResolveBackendMetadataUseCase(
            backendMetadataAPI: api,
            clientProductionVersions: [.v6, .v7],
            preferredAPIVersion: .v8
        )

        // Mock
        api.getBackendMetadata_MockValue = Scaffolding.backendMetadata

        // When
        let backendMetadata = try await sut.invoke()

        // Then
        XCTAssertEqual(backendMetadata.apiVersion, .v8)
        XCTAssertEqual(backendMetadata.domain, "wire.com")
        XCTAssertEqual(backendMetadata.isFederationEnabled, true)
    }

    // MARK: - Resolve for production

    func testInvoke_ResolvesToMaxProductionVersion() async throws {
        // Given
        let sut = ResolveBackendMetadataUseCase(
            backendMetadataAPI: api,
            clientProductionVersions: [.v6, .v7],
            preferredAPIVersion: nil
        )

        // Mock
        api.getBackendMetadata_MockValue = Scaffolding.backendMetadata

        // When
        let backendMetadata = try await sut.invoke()

        // Then
        XCTAssertEqual(backendMetadata.apiVersion, .v7)
        XCTAssertEqual(backendMetadata.domain, "wire.com")
        XCTAssertEqual(backendMetadata.isFederationEnabled, true)
    }

    // MARK: - Failed to resolve

    func testInvoke_BackendVersionIsObsolete() async throws {
        // Given
        let sut = ResolveBackendMetadataUseCase(
            backendMetadataAPI: api,
            clientProductionVersions: [.v6, .v7],
            preferredAPIVersion: nil
        )

        // Mock
        api.getBackendMetadata_MockValue = Scaffolding.obsoleteBackendMetadata

        // Then
        await XCTAssertThrowsErrorAsync(ResolveBackendMetadataUseCase.Failure.backendAPIVersionObsolete) {
            // When
            try await sut.invoke()
        }
    }

    func testInvoke_ClientVersionIsObsolete() async throws {
        // Given
        let sut = ResolveBackendMetadataUseCase(
            backendMetadataAPI: api,
            clientProductionVersions: [.v2, .v3],
            preferredAPIVersion: nil
        )

        // Mock
        api.getBackendMetadata_MockValue = Scaffolding.backendMetadata

        // Then
        await XCTAssertThrowsErrorAsync(ResolveBackendMetadataUseCase.Failure.clientVersionObsolete) {
            // When
            try await sut.invoke()
        }
    }

}

private enum Scaffolding {

    static let backendMetadata = WireAPI.BackendMetadata(
        domain: "wire.com",
        isFederationEnabled: true,
        supportedVersions: [.v4, .v5, .v6, .v7],
        developmentVersions: [.v8]
    )

    static let obsoleteBackendMetadata = WireAPI.BackendMetadata(
        domain: "wire.com",
        isFederationEnabled: true,
        supportedVersions: [.v4, .v5],
        developmentVersions: []
    )

}
