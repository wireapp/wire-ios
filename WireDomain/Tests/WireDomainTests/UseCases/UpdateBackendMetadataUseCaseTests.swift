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

import Foundation
import Testing
import WireDomain
import WireNetwork
import WireNetworkSupport

final class UpdateBackendMetadataUseCaseTests {

    let accountID = UUID()
    let resolveBackendMetadataUseCase = MockResolveBackendMetadataUseCaseProtocol()
    let storeURL = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let backendStore: BackendEnvironmentStore
    let journal: Journal
    let sut: UpdateBackendMetadataUseCase

    init() throws {
        self.backendStore = try BackendEnvironmentStore(directory: storeURL)
        self.journal = Journal(userID: accountID, storage: UserDefaults.temporary())

        self.sut = UpdateBackendMetadataUseCase(
            resolveBackendMetadataUseCase: resolveBackendMetadataUseCase,
            backendStore: backendStore,
            journal: journal,
            accountID: accountID
        )
    }

    deinit {
        try? FileManager.default.removeItem(at: storeURL)
    }

    // MARK: - Tests

    @Test(arguments: [APIVersion.v15, .v18])
    func `startup refreshes changed capabilities once and reuses negotiated metadata`(
        backendVersion: APIVersion
    ) async throws {
        let previousMetadata = ResolvedBackendMetadata(
            apiVersion: .v15,
            domain: "example.com",
            isFederationEnabled: false
        )
        try backendStore.storeBackendMetadata(previousMetadata, for: accountID)
        journal[.resolvedBackendMetadataAPIVersions] = ["15"]
        let metadata = ResolvedBackendMetadata(
            apiVersion: backendVersion,
            domain: "example.com",
            isFederationEnabled: false
        )
        resolveBackendMetadataUseCase.invoke_MockValue = metadata

        let refreshedMetadata = try await sut.invokeIfNeeded()
        let cachedMetadata = try await sut.invokeIfNeeded()

        #expect(refreshedMetadata == metadata)
        #expect(cachedMetadata == metadata)
        #expect(resolveBackendMetadataUseCase.invoke_Invocations.count == 1)
    }

    @Test(arguments: [false, true])
    func `startup preserves cached metadata when unavailable and retries on the next session`(
        malformedResponse: Bool
    ) async throws {
        let cachedMetadata = ResolvedBackendMetadata(
            apiVersion: .v15,
            domain: "example.com",
            isFederationEnabled: false
        )
        try backendStore.storeBackendMetadata(cachedMetadata, for: accountID)
        resolveBackendMetadataUseCase.invoke_MockError = if malformedResponse {
            DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Invalid backend metadata"))
        } else {
            URLError(.notConnectedToInternet)
        }

        let offlineResult = try await sut.invokeIfNeeded()

        #expect(offlineResult == cachedMetadata)
        #expect(journal[.resolvedBackendMetadataAPIVersions].isEmpty)

        let metadata = ResolvedBackendMetadata(apiVersion: .v18, domain: "example.com", isFederationEnabled: false)
        resolveBackendMetadataUseCase.invoke_MockError = nil
        resolveBackendMetadataUseCase.invoke_MockValue = metadata

        let onlineResult = try await sut.invokeIfNeeded()

        #expect(onlineResult == metadata)
        #expect(resolveBackendMetadataUseCase.invoke_Invocations.count == 2)
    }

    @Test
    func `startup propagates failure when there is no cached metadata`() async {
        resolveBackendMetadataUseCase.invoke_MockError = URLError(.notConnectedToInternet)

        await #expect(throws: URLError.self) {
            try await sut.invokeIfNeeded()
        }
    }

    @Test
    func `startup propagates incompatible API versions despite cached metadata`() async throws {
        let metadata = ResolvedBackendMetadata(apiVersion: .v15, domain: "example.com", isFederationEnabled: false)
        try backendStore.storeBackendMetadata(metadata, for: accountID)
        resolveBackendMetadataUseCase.invoke_MockError = NetworkStackError.backendAPIVersionObsolete

        await #expect(throws: NetworkStackError.self) {
            try await sut.invokeIfNeeded()
        }
    }

    @Test
    func `startup propagates cancellation instead of using cached metadata`() async throws {
        let metadata = ResolvedBackendMetadata(apiVersion: .v15, domain: "example.com", isFederationEnabled: false)
        try backendStore.storeBackendMetadata(metadata, for: accountID)
        resolveBackendMetadataUseCase.invoke_MockError = URLError(.cancelled)

        await #expect(throws: URLError.self) {
            try await sut.invokeIfNeeded()
        }
    }

    @Test
    func `invoke returns new metadata`() async throws {
        // Given
        let metadata = ResolvedBackendMetadata(
            apiVersion: .v5,
            domain: "example.com",
            isFederationEnabled: false
        )
        resolveBackendMetadataUseCase.invoke_MockValue = metadata

        // When
        let result = try await sut.invoke()

        // Then
        #expect(result == metadata)
    }

    @Test
    func `invoke stores new metadata`() async throws {
        // Given
        let metadata = ResolvedBackendMetadata(
            apiVersion: .v5,
            domain: "example.com",
            isFederationEnabled: false
        )
        resolveBackendMetadataUseCase.invoke_MockValue = metadata

        // When
        _ = try await sut.invoke()

        // Then
        let storedMetadata = try backendStore.fetchBackendMetadata(accountID: accountID)
        #expect(storedMetadata == metadata)
    }

    @Test
    func `invoke sets federation migration required when it transitions from disabled to enabled`() async throws {
        // Given
        let prevMetadata = ResolvedBackendMetadata(
            apiVersion: .v5,
            domain: "example.com",
            isFederationEnabled: false
        )
        try backendStore.storeBackendMetadata(prevMetadata, for: accountID)

        let newMetadata = ResolvedBackendMetadata(
            apiVersion: .v5,
            domain: "example.com",
            isFederationEnabled: true
        )
        resolveBackendMetadataUseCase.invoke_MockValue = newMetadata

        // When
        _ = try await sut.invoke()

        // Then
        #expect(journal[.isFederationMigrationRequired] == true)
    }

    @Test
    func `invoke does not set federation migration required when federation was already enabled`() async throws {
        // Given
        let prevMetadata = ResolvedBackendMetadata(
            apiVersion: .v5,
            domain: "example.com",
            isFederationEnabled: true
        )
        try backendStore.storeBackendMetadata(prevMetadata, for: accountID)

        let newMetadata = ResolvedBackendMetadata(
            apiVersion: .v5,
            domain: "example.com",
            isFederationEnabled: true
        )
        resolveBackendMetadataUseCase.invoke_MockValue = newMetadata

        // When
        _ = try await sut.invoke()

        // Then
        #expect(journal[.isFederationMigrationRequired] == false)
    }

    @Test
    func `invoke does not set federation migration required when federation remains disabled`() async throws {
        // Given
        let prevMetadata = ResolvedBackendMetadata(
            apiVersion: .v5,
            domain: "example.com",
            isFederationEnabled: false
        )
        try backendStore.storeBackendMetadata(prevMetadata, for: accountID)

        let newMetadata = ResolvedBackendMetadata(
            apiVersion: .v5,
            domain: "example.com",
            isFederationEnabled: false
        )
        resolveBackendMetadataUseCase.invoke_MockValue = newMetadata

        // When
        _ = try await sut.invoke()

        // Then
        #expect(journal[.isFederationMigrationRequired] == false)
    }

    @Test
    func `Does not set federation migration required when no previous metadata exists`() async throws {
        // Given
        let newMetadata = ResolvedBackendMetadata(
            apiVersion: .v5,
            domain: "example.com",
            isFederationEnabled: true
        )
        resolveBackendMetadataUseCase.invoke_MockValue = newMetadata

        // When
        _ = try await sut.invoke()

        // Then
        #expect(journal[.isFederationMigrationRequired] == false)
    }

}
