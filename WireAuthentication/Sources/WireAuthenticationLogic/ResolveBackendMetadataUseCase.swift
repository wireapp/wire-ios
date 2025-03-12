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

import Foundation
import WireAPI
import WireAuthenticationAPI

public struct ResolveBackendMetadataUseCase: ResolveBackendMetadataUseCaseProtocol {

    public typealias Failure = ResolveBackendMetadataUseCaseFailure

    private let backendMetadataAPI: any BackendMetadataAPI
    private let clientProductionVersions: Set<APIVersion>
    private let preferredAPIVersion: APIVersion?

    public init(
        backendMetadataAPI: any BackendMetadataAPI,
        clientProductionVersions: Set<APIVersion>,
        preferredAPIVersion: APIVersion?
    ) {
        self.backendMetadataAPI = backendMetadataAPI
        self.clientProductionVersions = clientProductionVersions
        self.preferredAPIVersion = preferredAPIVersion
    }

    public func invoke() async throws -> WireAuthenticationAPI.BackendMetadata {
        let backendMetadata = try await backendMetadataAPI.getBackendMetadata()
        let resolvedAPIVersion = try resolveAPIVersion(from: backendMetadata)
        return WireAuthenticationAPI.BackendMetadata(
            apiVersion: .init(resolvedAPIVersion),
            domain: backendMetadata.domain,
            isFederationEnabled: backendMetadata.isFederationEnabled
        )
    }

    private func resolveAPIVersion(from backendMetadata: WireAPI.BackendMetadata) throws -> APIVersion {
        let backendProductionVersions = backendMetadata.supportedVersions
        let allBackendVersions = backendMetadata.supportedVersions.union(backendMetadata.developmentVersions)
        let commonProductionVersions = clientProductionVersions.intersection(backendProductionVersions)

        if let preferredAPIVersion, allBackendVersions.contains(preferredAPIVersion) {
            return preferredAPIVersion
        } else if let resolvedAPIVersion = commonProductionVersions.max() {
            return resolvedAPIVersion
        } else {
            // API version can't be resolved.
            guard let maxBackendVersion = backendProductionVersions.max() else {
                throw Failure.backendAPIVersionObsolete
            }

            guard let minClientVersion = clientProductionVersions.min() else {
                throw Failure.clientVersionObsolete
            }

            throw maxBackendVersion < minClientVersion ? Failure.backendAPIVersionObsolete : .clientVersionObsolete
        }
    }

}

private extension WireAuthenticationAPI.BackendMetadata.APIVersion {

    // TODO: [WPB-16272] remove when API version is deduplicated.
    init(_ apiVersion: WireAPI.APIVersion) {
        switch apiVersion {
        case .v0:
            self = .v0
        case .v1:
            self = .v1
        case .v2:
            self = .v2
        case .v3:
            self = .v3
        case .v4:
            self = .v4
        case .v5:
            self = .v5
        case .v6:
            self = .v6
        case .v7:
            self = .v7
        case .v8:
            self = .v8
        }
    }

}
