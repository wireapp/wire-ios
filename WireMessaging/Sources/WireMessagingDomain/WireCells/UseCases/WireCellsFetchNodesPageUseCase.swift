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

/// Fetches `WireCellNodes`s for the given parameters.
@MainActor
package struct WireCellsFetchNodesPageUseCase: Sendable {

    private let configuration: WireCellsGetNodesRequest.Configuration
    private let repository: any WireCellsNodesRepositoryProtocol
    private let localAssetRepository: any WireCellsLocalAssetRepositoryProtocol

    /// Initializes the use case with the required parameters.
    /// - Parameters:
    ///   - configuration: The configuration for the use case.
    ///   - repository: The repository to use for fetching nodes.
    package init(
        configuration: WireCellsGetNodesRequest.Configuration,
        repository: any WireCellsNodesRepositoryProtocol,
        localAssetRepository: any WireCellsLocalAssetRepositoryProtocol
    ) {
        self.configuration = configuration
        self.repository = repository
        self.localAssetRepository = localAssetRepository
    }

    /// Fetches nodes based on the provided search term and pagination token.
    ///
    /// - Parameters:
    ///   - searchTerm: An optional search term to filter nodes by their name.
    ///   - token: An optional pagination token. If `nil`, the first page of results will be fetched.
    /// - Returns: An array of `WireCellsNode` values and an optional pagination token for the next page of results. If
    /// `nil`, there are no more pages to fetch.
    package func invoke(
        searchTerm: String?,
        tags: [String],
        offset: Int
    ) async throws -> (nodes: [WireCellsNode], isLastPage: Bool) {
        let request = WireCellsGetNodesRequest(
            searchTerm: searchTerm,
            tags: tags,
            limit: 30,
            offset: offset,
            configuration: configuration
        )
        let (nodes, nextOffset) = try await repository.getNodes(request)

        // Retrieve assets that have been updated and deleting them locally.
        let nodesAssetToDelete = try nodes.compactMap {
            if let localAsset = try localAssetRepository.asset(nodeID: $0.id), localAsset.eTag != $0.eTag {
                $0
            } else {
                nil
            }
        }.map(\.id)

        try await localAssetRepository.deleteAssets(nodeIDs: nodesAssetToDelete)

        return (nodes, nextOffset == nil)
    }

}
