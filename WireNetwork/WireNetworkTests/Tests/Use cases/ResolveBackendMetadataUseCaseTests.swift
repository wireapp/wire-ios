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

import Testing

@testable import WireNetwork
@testable import WireNetworkSupport

struct ResolveBackendMetadataUseCaseTests {

    let api = MockBackendMetadataAPI()

    // MARK: - Resolve for preferred version

    @Test("Resolves to preferred version")
    func resolvesToPreferredVersion() async throws {
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
        #expect(backendMetadata.apiVersion == .v8)
        #expect(backendMetadata.domain == "wire.com")
        #expect(backendMetadata.isFederationEnabled == true)
    }

    // MARK: - Resolve for production

    @Test("Resolves to max production version")
    func resolvesToMaxProductionVersion() async throws {
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
        #expect(backendMetadata.apiVersion == .v7)
        #expect(backendMetadata.domain == "wire.com")
        #expect(backendMetadata.isFederationEnabled == true)
    }

    // MARK: - Failed to resolve

    @Test("Backend version is obsolete")
    func backendVersionIsObsolete() async throws {
        // Given
        let sut = ResolveBackendMetadataUseCase(
            backendMetadataAPI: api,
            clientProductionVersions: [.v6, .v7],
            preferredAPIVersion: nil
        )

        // Mock
        api.getBackendMetadata_MockValue = Scaffolding.obsoleteBackendMetadata

        // Then
        await #expect(throws: ResolveBackendMetadataUseCase.Failure.backendAPIVersionObsolete) {
            // When
            try await sut.invoke()
        }
    }

    @Test("Client version is obsolete")
    func clientVersionIsObsolete() async throws {
        // Given
        let sut = ResolveBackendMetadataUseCase(
            backendMetadataAPI: api,
            clientProductionVersions: [.v2, .v3],
            preferredAPIVersion: nil
        )

        // Mock
        api.getBackendMetadata_MockValue = Scaffolding.backendMetadata

        // Then
        await #expect(throws: ResolveBackendMetadataUseCase.Failure.clientVersionObsolete) {
            // When
            try await sut.invoke()
        }
    }

}

private enum Scaffolding {

    static let backendMetadata = BackendMetadata(
        domain: "wire.com",
        isFederationEnabled: true,
        supportedVersions: [.v4, .v5, .v6, .v7],
        developmentVersions: [.v8]
    )

    static let obsoleteBackendMetadata = BackendMetadata(
        domain: "wire.com",
        isFederationEnabled: true,
        supportedVersions: [.v4, .v5],
        developmentVersions: []
    )

}
