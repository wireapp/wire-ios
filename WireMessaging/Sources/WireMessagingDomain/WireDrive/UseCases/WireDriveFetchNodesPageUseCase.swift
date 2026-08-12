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

/// Fetches `WireDriveNodes`s for the given parameters.
package struct WireDriveFetchNodesPageUseCase: Sendable {

    private let repository: any WireDriveNodesRepositoryProtocol

    /// Initializes the use case with the required parameters.
    /// - Parameters:
    ///   - repository: The repository to use for fetching nodes.
    package init(
        repository: any WireDriveNodesRepositoryProtocol
    ) {
        self.repository = repository
    }

    /// Fetches nodes based on the provided search term and pagination token.
    ///
    /// - Parameters:
    ///   - searchTerm: An optional search term to filter nodes by their name.
    ///   - token: An optional pagination token. If `nil`, the first page of results will be fetched.
    /// - Returns: An array of `WireDriveNode` values and an optional pagination token for the next page of results. If
    /// `nil`, there are no more pages to fetch.
    package func invoke(
        configuration: WireDriveGetNodesRequest.Configuration,
        searchTerm: String?,
        metafilter: Set<WireDriveNodesMetaFilter> = [],
        sortField: String? = nil,
        sortDirDesc: Bool? = nil,
        offset: Int
    ) async throws -> (nodes: [WireDriveNode], isLastPage: Bool) {
        let request = WireDriveGetNodesRequest(
            searchTerm: searchTerm,
            metafilter: metafilter,
            sortField: sortField,
            sortDirDesc: sortDirDesc,
            limit: 30,
            offset: offset,
            configuration: configuration
        )
        let (nodes, nextOffset) = try await repository.getNodes(request)

        return (nodes, nextOffset == nil)
    }

}
