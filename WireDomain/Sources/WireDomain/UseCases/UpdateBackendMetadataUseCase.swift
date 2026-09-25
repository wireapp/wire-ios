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
import WireNetwork

// MARK: - UpdateBackendMetadataUseCaseProtocol

// sourcery: AutoMockable
public protocol UpdateBackendMetadataUseCaseProtocol: Sendable {

    func invoke() async throws -> ResolvedBackendMetadata

}

// MARK: - UpdateBackendMetadataUseCase

public struct UpdateBackendMetadataUseCase: UpdateBackendMetadataUseCaseProtocol, @unchecked Sendable {

    let resolveBackendMetadataUseCase: any ResolveBackendMetadataUseCaseProtocol
    let backendStore: BackendEnvironmentStore
    let journal: Journal
    let accountID: UUID

    public init(
        resolveBackendMetadataUseCase: any ResolveBackendMetadataUseCaseProtocol,
        backendStore: BackendEnvironmentStore,
        journal: Journal,
        accountID: UUID
    ) {
        self.resolveBackendMetadataUseCase = resolveBackendMetadataUseCase
        self.backendStore = backendStore
        self.journal = journal
        self.accountID = accountID
    }

    /// Refreshes metadata before session creation when the client's production API versions have changed.
    public func invokeIfNeeded() async throws -> ResolvedBackendMetadata {
        try Task.checkCancellation()
        let cachedMetadata = try backendStore.fetchBackendMetadata(accountID: accountID)
        if let cachedMetadata,
           journal[.resolvedBackendMetadataAPIVersions] ==
           Set(APIVersion.productionVersions.map { String($0.rawValue) }) {
            return cachedMetadata
        }

        let newMetadata: ResolvedBackendMetadata
        do {
            newMetadata = try await resolveBackendMetadataUseCase.invoke()
        } catch {
            try Task.checkCancellation()
            // Preserve offline startup without marking the refresh complete, so a later session retries it.
            guard let cachedMetadata else { throw error }
            switch error {
            case let error as URLError where error.code != .cancelled:
                return cachedMetadata
            case let error as FailureResponse where error.code == 429 || (500 ... 599).contains(error.code):
                return cachedMetadata
            case is DecodingError:
                // A temporary proxy/backend outage can return HTML or an empty response.
                return cachedMetadata
            default:
                throw error
            }
        }

        try store(newMetadata, replacing: cachedMetadata)
        return newMetadata
    }

    public func invoke() async throws -> ResolvedBackendMetadata {
        let prevMetadata = try backendStore.fetchBackendMetadata(accountID: accountID)
        let newMetadata = try await resolveBackendMetadataUseCase.invoke()
        try store(newMetadata, replacing: prevMetadata)
        return newMetadata
    }

    private func store(
        _ newMetadata: ResolvedBackendMetadata,
        replacing prevMetadata: ResolvedBackendMetadata?
    ) throws {
        try Task.checkCancellation()

        if let prevMetadata, !prevMetadata.isFederationEnabled, newMetadata.isFederationEnabled {
            // Now that federation is enabled we'll start storing domains
            // on entities in the database. We'll therefore need to add
            // the local domain to all existing entities so they're
            // fully qualified.
            journal[.isFederationMigrationRequired] = true
        }

        try backendStore.storeBackendMetadata(newMetadata, for: accountID)
        journal[.resolvedBackendMetadataAPIVersions] = Set(APIVersion.productionVersions.map { String($0.rawValue) })
    }
}
