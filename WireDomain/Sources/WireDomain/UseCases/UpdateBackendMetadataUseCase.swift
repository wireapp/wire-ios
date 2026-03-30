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
public protocol UpdateBackendMetadataUseCaseProtocol {

    func invoke() async throws -> ResolvedBackendMetadata

}

// MARK: - UpdateBackendMetadataUseCase

public struct UpdateBackendMetadataUseCase: UpdateBackendMetadataUseCaseProtocol {

    let networkStack: NetworkStack
    let backendStore: BackendEnvironmentStore
    let journal: Journal
    let accountID: UUID

    public init(
        networkStack: NetworkStack,
        backendStore: BackendEnvironmentStore,
        journal: Journal,
        accountID: UUID
    ) {
        self.networkStack = networkStack
        self.backendStore = backendStore
        self.journal = journal
        self.accountID = accountID
    }

    public func invoke() async throws -> ResolvedBackendMetadata {
        let prevMetadata = try backendStore.fetchBackendMetadata(accountID: accountID)
        let newMetadata = try await networkStack.resolvedBackendMetadata()

        if let prevMetadata, !prevMetadata.isFederationEnabled, newMetadata.isFederationEnabled {
            // Now that federation is enabled we'll start storing domains
            // on entities in the database. We'll therefore need to add
            // the local domain to all existing entities so they're
            // fully qualified.
            journal[.isFederationMigrationRequired] = true
        }

        try backendStore.storeBackendMetadata(newMetadata, for: accountID)

        return newMetadata
    }
}
