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

import CellsSDK
package import Foundation

/// Fetches `WireCellNodes`s for the given parameters.
package struct WireCellsFetchNodesUseCase: Sendable {

    package struct Configuration: Sendable {

        /// The root container for the nodes. If `nil`, nodes for all conversations will be returned.
        let root: WireCellsNodeLocator?

        /// Specific nodes to fetch.
        let nodeIDs: [UUID]?

        /// Whether to fetch nodes recursively from the root container.
        let isRecursive: Bool

        /// The type of nodes to fetch.
        let nodeType: WireCellsNodeType

        /// The deletion status of the nodes to fetch.
        let deletionStatus: WireCellsNodeDeletionStatus

        /// The maximum number of nodes to fetch.
        let pageSize: Int = 30

        /// A `Configuration` suitable for the conversation file view.
        package static func conversationFileView(root: WireCellsNodeLocator?) -> Configuration {
            Configuration(
                root: root,
                nodeIDs: nil,
                isRecursive: true,
                nodeType: .leaf,
                deletionStatus: .notDeleted
            )
        }

        /// A `Configuration` suitable for the files browser view.
        package static func filesBrowserView() -> Configuration {
            Configuration(
                root: nil,
                nodeIDs: nil,
                isRecursive: true,
                nodeType: .leaf,
                deletionStatus: .notDeleted
            )
        }

        /// A `Configuration` for showing only specific nodes in the file view.
        package static func nodesFileView(nodeIDs: [UUID]) -> Configuration {
            Configuration(
                root: nil,
                nodeIDs: nodeIDs,
                isRecursive: true,
                nodeType: .leaf,
                deletionStatus: .notDeleted
            )
        }

    }

    private let configuration: Configuration
    private let repository: any WireCellsNodesRepositoryProtocol

    /// Initializes the use case with the required parameters.
    /// - Parameters:
    ///   - configuration: The configuration for the use case.
    ///   - repository: The repository to use for fetching nodes.
    package init(
        configuration: Configuration,
        repository: any WireCellsNodesRepositoryProtocol
    ) {
        self.configuration = configuration
        self.repository = repository
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
        offset: Int
    ) async throws -> (nodes: [WireCellsNode], isLastPage: Bool) {
        let request = WireCellsGetNodesRequest(
            scope: WireCellsGetNodesRequest.Scope(
                root: configuration.root,
                isRecursive: configuration.isRecursive
            ),
            query: configuration.nodeIDs.map { WireCellsGetNodesRequest.Query(nodeIDs: $0) },
            filter: WireCellsGetNodesRequest.Filter(
                deletionStatus: configuration.deletionStatus,
                text: searchTerm,
                type: configuration.nodeType
            ),
            limit: configuration.pageSize,
            offset: offset
        )
        var (nodes, nextOffset) = try await repository.getNodes(request)

        // FIXME: [WPB-16311] Temporary fix to filter out recycled nodes.
        // This is necessary because the backend doesn't filter out recycled nodes when we have requested specific
        // nodes. Once we implement showing previews in a conversation this check should move there, if there is no
        // backend fix.
        if configuration.deletionStatus == .notDeleted, let nodeIDs = configuration.nodeIDs, !nodeIDs.isEmpty {
            nodes = nodes.filter { !$0.isRecycled }
        }

        return (nodes, nextOffset == nil)
    }

}
