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

package import Foundation

/// Fetches remote `WireCellsNodes` for a given node ID.
package struct WireCellsFetchNodeUseCase: WireCellsFetchNodeUseCaseProtocol {

    private let repository: any WireCellsNodesRepositoryProtocol
    private let cache: any WireCellsNodeCacheProtocol

    package init(
        repository: any WireCellsNodesRepositoryProtocol,
        cache: any WireCellsNodeCacheProtocol
    ) {
        self.repository = repository
        self.cache = cache
    }

    /// Returns a `WireCellsNode` for a given nodeID or `nil` if not found. Caches the result in memory.
    package func invoke(nodeID: UUID) async throws -> WireCellsNode? {
        let node = try await repository.getNode(id: nodeID)
        await cache.setItem(WireCellsNodeCacheItem(node: node), for: nodeID)

        return node
    }

}
