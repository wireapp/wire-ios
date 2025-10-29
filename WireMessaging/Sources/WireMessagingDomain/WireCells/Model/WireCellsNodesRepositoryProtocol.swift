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

package import Foundation

// sourcery: AutoMockable
/// A repository of `WireCellNode` objects.
package protocol WireCellsNodesRepositoryProtocol: Sendable {

    /// Fetches a node with the specified ID.
    ///
    /// - Parameter id: The UUID of the node to fetch.
    /// - Returns: The `WireCellsNode` object with the specified ID, or `nil` if not found.
    func getNode(id: UUID) async throws -> WireCellsNode?

    /// Fetches nodes based on the provided request.
    ///
    /// - Parameter request: The request containing the scope, filter, limit, and offset for fetching nodes.
    /// - Returns: A tuple containing an array of `WireCellsNode` objects and an optional next offset for pagination.
    func getNodes(_ request: WireCellsGetNodesRequest) async throws -> (nodes: [WireCellsNode], nextOffset: Int?)

    /// Deletes nodes with the specified IDs.
    ///
    /// - Parameters:
    ///  - nodeIDs: An array of UUIDs representing the IDs of the nodes to delete.
    ///  - permanently: A boolean indicating whether to delete the nodes permanently or move them to the recycle bin.
    func deleteNodes(nodeIDs: [UUID], permanently: Bool) async throws -> Bool

    /// Renames a node.
    ///
    /// - Parameters:
    ///  - nodeID: The `UUID`s of the node to rename.
    ///  - targetPath: The new path for the node.
    /// - Returns: Whether the renaming was successful.
    func renameNode(nodeID: UUID, targetPath: String) async throws -> Bool

    /// Apply some pre-validation checks on node name before sending an upload
    ///
    /// - Parameters:
    ///     - path: The node path to pre-check.
    ///     - findAvailablePath: Finds the next available path if path already exists.
    /// - Returns: Whether a file already exists at this path and the next available path if any.
    func preCheck(path: String, findAvailablePath: Bool) async throws -> (fileExists: Bool, nextPath: String?)

}

package struct WireCellsGetNodesRequest: Equatable, Sendable {

    /// Filters the results of the request.
    package struct Filter: Equatable, Sendable {

        /// The `DeletionStatus` of the node.
        package let deletionStatus: WireCellsNodeDeletionStatus

        /// An optional search text of a nodes file name.
        package let text: String?

        /// The type of the node.
        package let type: WireCellsNodeType
    }

    /// The query to apply to the scope. `Query` is deprecated but it is necessary until we implement [WPB-16311].
    package struct Query: Equatable, Sendable {

        /// The IDs of the nodes to fetch. If provided, only nodes with these IDs will be returned.
        package let nodeIDs: [UUID]?
    }

    /// The scope of the request.
    package struct Scope: Equatable, Sendable {

        /// The root locator for the search. If no root is provided, the search will return nodes for all conversations.
        package let root: WireCellsNodeLocator?

        /// Whether the search should be recursive or not. If true, it will return nodes from sub folders.
        package let isRecursive: Bool
    }

    /// The scope of the request.
    package let scope: Scope

    // FIXME: [WPB-16311] Remove Query once previewing cells files in conversations is implemented.
    /// The query to apply to the request.
    package let query: Query?

    /// The filter to apply to the results.
    package let filter: Filter

    /// The maximum number of nodes to return.
    package let limit: Int

    /// The pagination offset to start the results from.
    package let offset: Int

    package init(scope: Scope, query: Query? = nil, filter: Filter, limit: Int, offset: Int) {
        self.scope = scope
        self.query = query
        self.filter = filter
        self.limit = limit
        self.offset = offset
    }
}
