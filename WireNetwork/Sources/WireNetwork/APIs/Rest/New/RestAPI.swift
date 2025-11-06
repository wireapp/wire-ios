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

protocol APIVersionProvider: AnyObject {

    func resolvedAPIVersion() async throws -> APIVersion

}

actor RestAPI: APIVersionProvider {

    private var backendMetadata: ResolvedBackendMetadata?
    private let apiService: APIService
    private let preferredAPIVersion: APIVersion?

    init(
        apiService: APIService,
        preferredAPIVersion: APIVersion?
    ) {
        self.apiService = apiService
        self.preferredAPIVersion = preferredAPIVersion
    }

    // MARK: - Backend metadata

    public func resolvedAPIVersion() async throws -> APIVersion {
        let backendMetadata = try await resolvedBackendMetadata()
        return backendMetadata.apiVersion
    }

    public func resolvedBackendMetadata() async throws -> ResolvedBackendMetadata {
        if let backendMetadata {
            return backendMetadata
        }

        let endpoint = GetBackendMetadataEndpoint(apiService: apiService)

        let useCase = ResolveBackendMetadataUseCase(
            backendMetadataAPI: endpoint,
            clientProductionVersions: APIVersion.productionVersions,
            preferredAPIVersion: preferredAPIVersion
        )

        do {
            let backendMetadata = try await useCase.invoke()
            self.backendMetadata = backendMetadata
            return backendMetadata
        } catch ResolveBackendMetadataUseCaseFailure.backendAPIVersionObsolete {
            throw NetworkStackError.backendAPIVersionObsolete
        } catch ResolveBackendMetadataUseCaseFailure.clientVersionObsolete {
            throw NetworkStackError.clientAPIVersionObsolete
        }
    }

    // MARK: - API clients

    private var apiVersionProvider: @Sendable () async throws -> APIVersion {
        { [weak self] in try await self!.resolvedAPIVersion() }
    }

    func makeConversationsAPI() -> ConversationsAPI2 {
        ConversationsAPI2(
            apiService: apiService,
            apiVersionProvider: apiVersionProvider
        )
    }

}
