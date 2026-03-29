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
import WireDomain
import WireNetwork
import WireTransport

// MARK: - UpdateBackendMetadataUseCaseProtocol

// sourcery: AutoMockable
public protocol UpdateBackendMetadataUseCaseProtocol {

    func invoke() async throws -> ResolvedBackendMetadata

}

// MARK: - UpdateBackendMetadataUseCase

struct UpdateBackendMetadataUseCase: UpdateBackendMetadataUseCaseProtocol {

    let networkStack: NetworkStack
    let backendStore: BackendEnvironmentStore
    let journal: Journal
    let accountID: UUID

    func invoke() async throws -> ResolvedBackendMetadata {
        // Get the last known metadata.
        var prevMetadata: ResolvedBackendMetadata?
        if let storedMetadata = try backendStore.fetchBackendMetadata(accountID: accountID) {
            prevMetadata = storedMetadata
        } else if
            let legacyAPIVersion = BackendInfo.apiVersion,
            let legacyDomain = BackendInfo.domain {
            // We're on the update path, use the legacy metadata.
            prevMetadata = ResolvedBackendMetadata(
                apiVersion: .init(legacyAPIVersion),
                domain: legacyDomain,
                isFederationEnabled: BackendInfo.isFederationEnabled
            )
        }

        // Get new metadata.
        let newMetadata: ResolvedBackendMetadata
        do {
            newMetadata = try await networkStack.resolvedBackendMetadata()
        } catch is URLError {
            // To allow offline browsing fallback to previous metadata if possible.
            if let prevMetadata {
                newMetadata = prevMetadata
            } else {
                throw Failure.noResolvedBackendMetadataAvailable
            }
        }

        if let prevMetadata {
            if !prevMetadata.isFederationEnabled, newMetadata.isFederationEnabled {
                // Now that federation is enabled we'll start storing domains
                // on entities in the database. We'll therefore need to add
                // the local domain to all existing entities so they're
                // fully qualified.
                journal[.isFederationMigrationRequired] = true
            }
        }

        // Store new metadata.
        do {
            try backendStore.storeBackendMetadata(
                newMetadata,
                for: accountID
            )
        } catch {
            throw Failure.failedToStoreMetadata(error)
        }

        return newMetadata
    }

}

// MARK: - UpdateBackendMetadataUseCase.Failure

extension UpdateBackendMetadataUseCase {

    enum Failure: Error {
        case noResolvedBackendMetadataAvailable
        case failedToStoreMetadata(any Error)
    }

}
