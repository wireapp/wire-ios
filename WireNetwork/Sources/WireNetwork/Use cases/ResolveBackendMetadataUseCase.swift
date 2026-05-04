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

struct ResolveBackendMetadataUseCase: ResolveBackendMetadataUseCaseProtocol {

    typealias Failure = ResolveBackendMetadataUseCaseFailure

    private let backendMetadataAPI: any BackendMetadataAPI
    private let clientProductionVersions: Set<APIVersion>
    private let preferredAPIVersion: APIVersion?

    init(
        backendMetadataAPI: any BackendMetadataAPI,
        clientProductionVersions: Set<APIVersion>,
        preferredAPIVersion: APIVersion?
    ) {
        self.backendMetadataAPI = backendMetadataAPI
        self.clientProductionVersions = clientProductionVersions
        self.preferredAPIVersion = preferredAPIVersion
    }

    func invoke() async throws -> ResolvedBackendMetadata {
        let backendMetadata = try await backendMetadataAPI.getBackendMetadata()
        let resolvedAPIVersion = try resolveAPIVersion(from: backendMetadata)
        return ResolvedBackendMetadata(
            apiVersion: resolvedAPIVersion,
            domain: backendMetadata.domain,
            isFederationEnabled: backendMetadata.isFederationEnabled
        )
    }

    private func resolveAPIVersion(
        from backendMetadata: BackendMetadata
    ) throws -> APIVersion {
        let allVersions = backendMetadata.allVersions
        let backendProductionVersions = backendMetadata.supportedVersions
        let commonProductionVersions = clientProductionVersions.intersection(backendProductionVersions)

        if let preferredAPIVersion, allVersions.contains(preferredAPIVersion) {
            // The preferred version is available.
            return preferredAPIVersion
        } else if let resolvedAPIVersion = commonProductionVersions.max() {
            // Using the max prod version.
            return resolvedAPIVersion
        } else {
            // API version can't be resolved.
            guard let maxBackendVersion = backendProductionVersions.max() else {
                throw Failure.backendAPIVersionObsolete
            }

            guard let minClientVersion = clientProductionVersions.min() else {
                throw Failure.clientVersionObsolete
            }

            if maxBackendVersion < minClientVersion {
                throw Failure.backendAPIVersionObsolete
            } else {
                throw Failure.clientVersionObsolete
            }
        }
    }

}

private extension BackendMetadata {

    var allVersions: Set<APIVersion> {
        supportedVersions.union(developmentVersions)
    }

}
